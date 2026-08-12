# Conventions

How this repo is meant to be changed, and why it is shaped the way it is. Read
this once; the day-to-day recipes live in
[adding-and-removing.md](adding-and-removing.md).

Written for someone new to Nix, so it explains the reasoning rather than just
the rules. Every claim here was checked against this repo rather than copied
from a tutorial.

---

## The one rule

**Nothing gets installed by hand.** If a tool is worth keeping, it is worth a
line in a file here.

The point is not tidiness. It is that a new machine should be one command away
from this one, and anything installed imperatively is invisible to that command.
Every item in the audit doc exists because something was installed by hand and
then forgotten.

The corollary is the part people miss: **removing the declaration is the part
that matters.** Deleting an app but leaving it declared means a fresh machine
reinstalls it. Deleting the declaration but leaving the app means this machine
keeps it while a fresh one does not. Both are drift. Do both.

---

## Prefer a module over a file

Nix can manage a program in three ways. They are not equal, and picking the
weakest one that works is the most common mistake.

**1. A `programs.<name>` module. Prefer this.** home-manager ships 406 of them
in this version. A module means you write settings as Nix attributes, and it
generates the config file:

```nix
programs.git = {
  enable = true;
  settings.user.email = "jose@example.com";
};
```

Why it is better than writing `.gitconfig` yourself: the option names are
type-checked, so a typo fails the build instead of being silently ignored by
git; the module knows the file's real format and escaping rules; and it
integrates with other modules, which is how `programs.starship.enableZshIntegration`
can add a line to the `.zshrc` that `programs.zsh` generates.

Check whether a module exists before writing a config file by hand. The reliable
way is to ask the evaluated config, which needs no man page and cannot go stale:

```sh
nix eval .#darwinConfigurations.REM-JoseS-MBP1.config.home-manager.users.jose.programs \
  --apply 'p: p ? direnv'      # true
```

The full option documentation is installed, but reaching it takes two
workarounds. `man home-configuration.nix` fails with "No manual entry" because
the per-user profile's man directory is not on the default `manpath`, so pass
the file directly. And option names are set in bold using overstrike sequences,
so a literal `grep` matches nothing until `col -b` strips them:

```sh
man /etc/profiles/per-user/$USER/share/man/man5/home-configuration.nix.5 \
  | col -b | grep -A5 'programs\.direnv\.enable'
```

Without the `col -b`, that grep returns zero matches on a page that plainly
contains the text, which is a confusing way to conclude a module does not exist.

**2. `home.file` with inline text.** For programs with no module. The file is
generated into the read-only Nix store and symlinked into place:

```nix
home.file.".foorc".text = ''
  set colour = blue
'';
```

**3. `home.file` with `mkOutOfStoreSymlink`.** For config you want to edit
without a rebuild. The symlink points at the live repo rather than the store,
so edits take effect immediately:

```nix
home.file.".hammerspoon".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/hammerspoon";
```

Use this for anything you iterate on, like Hammerspoon Lua or Karabiner rules,
where a rebuild per keystroke change would be intolerable. The cost is that the
file is no longer reproducible from the store alone: it depends on the repo
being checked out at that path.

**Which one this repo uses where** is listed under "Generated vs linked" in the
README.

---

## Where a new thing goes

| What it is | File | Applies to |
|---|---|---|
| CLI tool from nixpkgs | `nix/packages.nix` | Mac |
| CLI tool from nixpkgs | `nix/home/linux/default.nix` | WSL box |
| Program with a home-manager module | `nix/home/shared/` if portable, else `nix/home/darwin/` | per its file |
| GUI app | `casks` in `nix/configuration.nix` | Mac |
| App Store app | `masApps` in `nix/configuration.nix` | Mac |
| CLI tool **not** in nixpkgs | `brews` in `nix/configuration.nix` | Mac |
| VS Code extension | `nix/home/darwin/vscode.nix` | Mac |
| macOS setting | `system.defaults` in `nix/configuration.nix` | Mac |
| Background job | `launchd.agents` in a `nix/home/darwin/` module | Mac |

The split that catches everyone: **`nix/packages.nix` is a nix-darwin file, not
a home-manager one.** It sets `environment.systemPackages`, which does not
exist on the WSL box. A tool wanted on both machines is two edits in two files.
There is no single list. See "The asymmetry that will trip you up" in the README.

**`shared/` means portable, and that is a promise you have to keep.** A macOS
assumption in a shared file breaks the Linux box, and you will not find out from
the Mac because the Linux side cannot be built here. This has happened: a
`shell = "/bin/zsh"` in `shared/tmux.nix` would have made tmux refuse to start
on WSL, since that path does not exist there. Before putting something in
`shared/`, ask whether the path, the binary and the option all exist on Linux.

---

## Nixpkgs first, Homebrew only with a reason

Order of preference: **nixpkgs → cask → brew formula.**

nixpkgs gives you a pinned version, a rollback, and no separate update path.
Homebrew gives you none of those: `homebrew.brews` and `homebrew.casks` record
*that* something should be installed, not which version, so two machines built
from this repo on different days can differ.

Each of the five entries in `brews` carries a comment saying why nixpkgs was not
used, and that is the standard to hold. A brew with no reason is a brew that
should be a nixpkgs package:

```nix
brews = [
  "themekit"      # shopify/shopify
  "ant"           # apacheAnt evaluates unavailable on aarch64-darwin
  "pipx"          # fails its checkPhase in this nixpkgs
  "ruby"          # keg-only and unlinked, so /usr/bin/ruby still wins
];
```

Casks are different: GUI apps on macOS mostly are not in nixpkgs at all, so 53
casks is not a failure to migrate.

**A third-party tap needs `trust.taps` in `flake.nix`.** Homebrew refuses to
load formulae from untrusted taps, which aborts `brew bundle` mid-activation.
`themekit` and `ecsplorer` come from taps, which is why those two taps are
listed there.

---

## Names diverge, so look them up

Three different naming systems, and assuming they agree is the fastest way to a
failed build.

| Kind | Look it up with | Examples of divergence |
|---|---|---|
| nixpkgs attribute | `nix search nixpkgs <name>` | `telnet` is in `inetutils`, `helm` is `kubernetes-helm`, `wp` is `wp-cli`, `sha256sum` is in `coreutils` |
| cask token | `brew info --cask <name>` | Docker is `docker-desktop`, Wireshark is `wireshark-app`, DBeaver is `dbeaver-community` |
| App Store id | `mdls -name kMDItemAppStoreAdamID <app>` | numeric, never guessable |

`nix/verify.sh` lists **binaries**, not attributes, precisely because the two
diverge. Adding `coreutils` and then putting `coreutils` in a verify batch
reports `MISSING`, because the binary is `sha256sum`.

For App Store apps, read the id off the installed bundle. A wrong id does not
error, it installs a different app.

---

## Ordering, when it matters

Shell init is one generated file assembled from many modules, so order is a real
concern. home-manager provides priority helpers, all of them just numbers:

| Helper | Number | Use |
|---|---|---|
| `lib.mkBefore` | 500 | first |
| default | 1000 | unordered |
| `lib.mkAfter` | 1500 | last |
| `lib.mkOrder n` | n | when you need to sit between two others |

This repo uses `mkOrder 501`, `1100` and `1600` in `nix/home/darwin/extras.nix`
because those blocks must land in specific positions relative to `mkBefore` and
`mkAfter` in `shared/shell.nix`. The `1600` one is load-bearing: it re-asserts
Nix's precedence on `PATH` over the Homebrew line that `~/.zprofile` adds, so it
has to run after everything else.

**Two blocks at the same number are resolved by module load order**, which is
not something you should rely on. If you find yourself adding a second
`mkBefore`, use `mkOrder 501` instead and say why in a comment.

---

## Verify before you commit

Building is not the same as working, and both are cheaper than finding out at
activation.

```sh
# Does it evaluate and build? No sudo, changes nothing.
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths

# Do the declared binaries, symlinks and agents actually resolve?
nix/verify.sh all
```

For the WSL box, evaluation is all the Mac can do, because cross-building
x86_64-linux from darwin needs a remote builder this machine does not have:

```sh
nix eval '.#homeConfigurations."jose@RockemSockem".config.home.packages' --apply 'builtins.length'
```

**Inspect the generated file rather than trusting the module.** This is the
single most useful habit, and it catches things reasoning does not:

```sh
# What will the generated .zshrc actually say?
nix eval .#darwinConfigurations.REM-JoseS-MBP1.config.home-manager.users.jose.home.file \
  --apply 'f: f."./.zshrc".text' --raw | diff ~/.zshrc -
```

Attribute names containing dots need `--apply`, since the CLI splits on them.

---

## Traps this repo has actually hit

Each of these cost real time here, so they are worth knowing before they cost
you any.

**Nix only reads git-tracked files.** A new file under `nix/` that you forgot to
`git add` fails with "path does not exist" while you are looking straight at it.

**`system.defaults` is enforced, not suggested.** Declaring a value that does
not match the machine silently *changes* the machine instead of erroring. Read
the current value with `defaults read` before adding a setting.

**Homebrew removes nothing.** `homebrew.onActivation.cleanup = "none"` means
undeclaring a cask leaves the app installed. The Nix paths do uninstall on
removal; the Homebrew path does not.

**Adopting an existing app can fail destructively.** A newly declared cask whose
app was installed by direct download fails with "the existing App is different
from the one being installed", and may remove the app before failing. Hand it
over once with `brew install --cask --force <token>`.

**`nix build`'s last line can be part of an error trace.** Check that the output
path exists rather than reading the last line:

```sh
out=$(nix build ... --print-out-paths) && [ -d "$out" ] && echo OK
```

**`env -i` drops `USER` and `HOME`.** Testing a shell with a bare `env -i`
produces failures that are artifacts of the test. `environment.systemPath`
contains the literal `/etc/profiles/per-user/$USER/bin`, so without `USER` it
expands to a path that exists and is empty.

**home-manager session variables are guarded against re-sourcing.** A shell that
already has `__HM_SESS_VARS_SOURCED=1` will not pick up new values, so a test
inheriting your environment reads the old ones. Unset it and
`__HM_ZSH_SESS_VARS_SOURCED` when checking.

**Comments inside `''` strings are generated output.** Rewording one changes the
file Nix produces. Comments outside them are free. A refactor that should not
change behaviour can be checked by confirming the system hash is unchanged, but
that check is blind to the Nix-level comments.

---

## Deliberately not done

Knowing what was considered and rejected is as useful as knowing the rules.

- **No `nix.enable`.** Determinate Nix manages the daemon, so nix-darwin is told
  to leave it alone.
- **No `homebrew.onActivation.cleanup = "zap"`.** It would uninstall the 243
  undeclared formulae still on this machine.
- **`settings.json` for VS Code is not managed.** 743 hand-maintained lines, and
  setting any `userSettings` value takes ownership of the whole file.
- **No commit signing in `programs.git`.** Noted in the review doc, not yet
  decided.
- **`~/.secrets` is not in the repo** and never will be. `shared/shell.nix`
  sources it if present.
