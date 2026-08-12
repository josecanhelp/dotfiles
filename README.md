![](./dotfiles.png)

my hard work / 
by these words guarded /
please steal. (c) JoseCanHelp

# JoseCanHelp

Declarative dotfiles for macOS and WSL2, built on Nix, nix-darwin and
home-manager. Install Nix, clone this repo, and one command applies the whole
configuration: packages, applications, macOS settings, shell, editor and
background jobs.

Borrowing is encouraged. If you take something from here, a link back is
appreciated, and I do the same for the repos I have learned from.

## Setting up a machine

1. **Install [Determinate Nix](https://docs.determinate.systems/).** Everything else depends on it. This repo sets `nix.enable = false` because Determinate manages the daemon itself and nix-darwin should not fight it.

2. **Clone to `~/dotfiles`.** The path matters: home-manager's links point at it by absolute path.

   ```sh
   git clone git@github.com:josecanhelp/dotfiles.git ~/dotfiles
   ```

3. **Add the machine to `flake.nix`** if it is not already there. See the next section.

4. **Build.** The attribute name must match the machine's hostname.

   ```sh
   sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
   ```

5. **Create `~/.secrets`** if you need it. It is sourced by zsh and deliberately kept out of this repo.

No install script, no `brew bundle` to run by hand, no plugin managers to bootstrap.

## Adding another machine

One block in `flake.nix`:

```nix
darwinConfigurations = {
  "REM-JoseS-MBP1" = mkHost {
    hostname = "REM-JoseS-MBP1";
    user = "jose";
  };

  "Joses-Mac-mini" = mkHost {
    hostname = "Joses-Mac-mini";
    user = "jose";
  };
};
```

That is the whole change. `hostname` and `user` are passed into
`nix/configuration.nix` as module arguments, and everything that used to
hardcode a name derives from them: the computer name, `system.primaryUser`, the
home directory, which user home-manager configures, the Homebrew prefix owner,
the log rotation path, and the Dock folder paths.

**The attribute name, the `hostname` value, and the name in the rebuild command
must all match.** nix-darwin looks its configuration up by the machine's actual
hostname, so a mismatch fails with "attribute not found" rather than anything
helpful.

An Intel machine also needs the platform:

```nix
"IntelMac" = mkHost {
  hostname = "IntelMac";
  user = "jose";
  system = "x86_64-darwin";
};
```

Settings that should apply to one machine only go in their own module, never in
the shared one:

```nix
"WorkMac" = mkHost {
  hostname = "WorkMac";
  user = "jose";
  extraModules = [ ./nix/hosts/work.nix ];
};
```

### What is not parameterized, on purpose

| Thing | Where | Why it is left alone |
|---|---|---|
| Git identity | `nix/home/shared/git.nix` | Personal, not per-machine. Change it if someone else uses this repo, not when adding a Mac of your own |
| Dock contents | `nix/configuration.nix` | Lists specific apps like Brave and Teams. A machine without them gets a Dock entry pointing at nothing |
| `~/Code/*` shortcuts | `nix/home/shared/shell.nix` | `ee`, `tt`, `jj`, `aa`. Harmless if the directory does not exist; the alias just fails |
| `ecrlogin` registry | `nix/home/shared/shell.nix` | Contains a specific ECR registry alias |

Everything else should come up identically.

## The WSL2 box

`RockemSockem` is Linux, so it cannot use `mkHost`: that builds nix-darwin
systems and nix-darwin is macOS-only. It gets a separate output driven by
standalone home-manager, which manages `$HOME` and nothing else.

First activation, before `home-manager` exists on `PATH`:

```sh
nix run home-manager/master -- switch -b bak --flake ~/dotfiles#jose@RockemSockem
```

Every switch after that, once `programs.home-manager.enable` has installed the
binary itself:

```sh
home-manager switch --flake ~/dotfiles#jose@RockemSockem
```

It shares four modules with the Mac, `nix/home/shared/`: git, zsh and starship,
tmux, and neovim. Everything macOS-specific lives in `nix/home/darwin/`, and the
Linux-only pieces in `nix/home/linux/`. `flake.nix` pins `nixpkgs-26.05-darwin`
for every host, so this box's package versions are paced by the darwin release
channel too, not a Linux-specific one.

Two things to expect on a first run:

**Home-manager will refuse to overwrite files already on the box.** If zsh or
git were ever set up by hand before this flake, home-manager finds a plain
`~/.zshrc`, `~/.zshenv` (both from `programs.zsh`) or `~/.config/git/config`
(from `programs.git`) already there and will not clobber them, which is why
the first command above passes `-b bak`.

**zsh will be installed but will not be your login shell.** `programs.zsh` puts
zsh in the profile; it does not change your shell. One time:

```sh
command -v zsh | sudo tee -a /etc/shells
chsh -s "$(command -v zsh)"
```

WSL2 without `systemd=true` in `/etc/wsl.conf` will also make home-manager
warn about the systemd user units it generates, harmlessly.

Deliberately not on that box: Java, cloud CLIs, media tooling, Alacritty (WSL
uses Windows Terminal), and `zsh/custom/functions.zsh`, whose functions call
macOS's `open`.

## The three layers

Nix is not one thing. Three separate systems stack here, and knowing which one owns a given setting is most of the battle.

**`flake.nix` is not configuration.** It is a lockfile plus a package universe. It pins where packages come from and at what version, and says nothing about this machine.

```nix
inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
```

**nix-darwin configures the machine.** Needs sudo, affects every user, writes to `/etc`, `/Library`, and `/run/current-system`.

```nix
fonts.packages = [ pkgs.nerd-fonts.fira-code ];   # -> /Library/Fonts
system.defaults.dock.autohide = true;             # -> macOS preferences
environment.systemPackages = [ pkgs.ripgrep ];    # -> /run/current-system/sw/bin
```

**home-manager configures my home directory.** No sudo, only affects me, writes to `~/`.

```nix
programs.git.settings.user.name = "Jose Soto";    # -> ~/.config/git/config
home.file.".hammerspoon".source = ...;            # -> ~/.hammerspoon
```

The test: **does it need sudo, or would another user on this Mac want it too?** Then nix-darwin. **Is it a file in my home directory?** Then home-manager.

| Layer | Scope | Writes to | Lives in |
|---|---|---|---|
| flake | package versions | nothing | `flake.nix`, `flake.lock` |
| nix-darwin | the machine | `/etc`, `/Library`, `/run/current-system` | `nix/configuration.nix`, `nix/packages.nix` |
| nix-homebrew | Homebrew itself | `/opt/homebrew` | `nix/configuration.nix`, `flake.nix` |
| home-manager | my home directory | `~/`, plus my own launchd agents | `nix/home/shared/`, `darwin/`, `linux/` |

## Generated vs linked

Every config in this repo is handled one of two ways, and the difference decides how you edit it.

**Generated** means Nix writes the file into `/nix/store` and symlinks it into place. The file is read-only. To change it, edit the Nix and rebuild.

**Linked** means home-manager symlinks the repo file itself into place via `mkOutOfStoreSymlink`. Edits take effect immediately, no rebuild. This is used where a tool writes into its own config directory at runtime, which a read-only store path would break.

| Tool | What it does | How | Edit this |
|---|---|---|---|
| **zsh** | shell | generated | `nix/home/shared/shell.nix` |
| **starship** | prompt | generated | `nix/home/shared/shell.nix` |
| **git** | version control | generated | `nix/home/shared/git.nix` |
| **alacritty** | terminal | generated | `nix/home/darwin/alacritty.nix` |
| **tmux** | multiplexer | generated | `nix/home/shared/tmux.nix` |
| **neovim** | editor | generated | `nix/home/shared/nvim.nix`, `nvim/init.lua` |
| **java** | JDK 17 and `JAVA_HOME` | generated | `nix/home/darwin/java.nix` |
| **hammerspoon** | window and keyboard automation | linked | `hammerspoon/` |
| **karabiner** | keyboard remapping | linked | `karabiner/karabiner.edn` |
| **amethyst** | tiling window manager | linked | `amethyst/amethyst.yml` |
| `~/.claude/notify.sh` | Claude Code notification hook | linked | `claude/notify.sh` |
| `~/.bin` | my own scripts | linked | `bin/` |
| `~/.hushlogin` | suppresses the login banner | linked | `hushlogin` |

Hammerspoon is linked because it writes Spoons into its own directory. Karabiner is linked because goku compiles the `.edn` and Karabiner-Elements writes `karabiner.json` alongside it.

Two files are neither generated nor linked. They are sourced by absolute path from the repo:

- `zsh/custom/functions.zsh`, sourced from `programs.zsh.initContent`
- `tmux/tmuxline`, sourced from `programs.tmux.extraConfig`

Shell functions have no Nix representation, so they stay real files and stay instantly editable.

## Background jobs

Two things run outside any app, registered through launchd:

| Job | What it does | Declared in |
|---|---|---|
| `goku` | recompiles `karabiner.edn` to `karabiner.json` on save | `nix/home/darwin/karabiner.nix` |
| `tmux-boot` | opens Alacritty fullscreen with the restored tmux session at login | `nix/home/darwin/extras.nix` |

Both use home-manager's `launchd.agents.*`, not nix-darwin's
`launchd.user.agents.*`. home-manager's version runs as me with no sudo, which
matches everything else in `nix/home/`, and using the wrong one either fails to
evaluate there or registers a second, competing agent.

`nix/verify.sh agents` asserts both are registered against paths that exist.
That check exists because three broken launchd jobs once survived an entire
migration unnoticed: `brew services list` returns empty, so no Homebrew command
ever surfaced them, and one of them reported a healthy PID for days while being
unable to run the command it existed for.

## Where things live

### Both machines

Anything here applies to the Mac and to the WSL box, because both import
`nix/home/shared/`.

| Want to change | File |
|---|---|
| A shell alias, prompt setting, or env var | `nix/home/shared/shell.nix` |
| Git config or identity | `nix/home/shared/git.nix` |
| tmux keybindings or plugins | `nix/home/shared/tmux.nix` |
| Neovim plugins or Lua | `nix/home/shared/nvim.nix`, `nvim/init.lua` |

### The Mac only

| Want to change | File |
|---|---|
| A CLI tool or language runtime | `nix/packages.nix` |
| A GUI app (cask) or a brew-only formula | `nix/configuration.nix`, `homebrew` block |
| macOS settings: Dock, Finder, key repeat | `nix/configuration.nix`, `system.defaults` |
| A disabled keyboard shortcut or text replacement | `nix/configuration.nix`, `activationScripts.postActivation` |
| Fonts | `nix/configuration.nix`, `fonts.packages` |
| Which files get symlinked into `$HOME` | `nix/home/darwin/default.nix`, `nix/home/darwin/karabiner.nix` |
| A login or background job | `nix/home/darwin/karabiner.nix`, `nix/home/darwin/extras.nix` |
| Add another Mac | `flake.nix`, one block |

### The WSL box only

Everything lives in one file, `nix/home/linux/default.nix`: its package list,
its shell additions, and its `home.file` links.

| Want to change | Where in that file |
|---|---|
| A CLI tool | the `home.packages` list |
| A zsh setting for that box alone | its `programs.zsh.initContent` block |
| A file symlinked into `$HOME` there | its `home.file` block |

There is deliberately no equivalent of `nix/configuration.nix` for it. Standalone
home-manager manages `$HOME` and nothing else, so nothing there configures the
machine, installs system packages, or sets OS preferences.

### The asymmetry that will trip you up

**Adding a CLI tool is a different file on each machine.** The Mac declares
packages in `nix/packages.nix` through `environment.systemPackages`, which is a
nix-darwin option and therefore cannot apply to Linux at all. The WSL box
declares them in `home.packages` in `nix/home/linux/default.nix`.

So "install ripgrep everywhere" means editing two files. There is no shared
package list, and that is a deliberate choice rather than an oversight: bridging
a system-level option and a home-level one is not worth the indirection at this
size. The two lists are also meant to differ, since that box gets a terminal dev
core rather than the Mac's full set.

### Package versions

`nix flake update`, then rebuild. That bumps both machines at once, since they
share `flake.lock`.

## Adding and removing things

**The rule: nothing gets installed by hand.** If a tool is worth keeping it is
worth a line in a file here, and removing that line is the half people forget.
An app deleted but still declared comes back on a fresh machine; a declaration
deleted but the app left behind means this machine and a fresh one disagree.
Both are drift.

Which file depends on what the thing is:

| What it is | Where it goes |
|---|---|
| CLI tool from nixpkgs, Mac | `nix/packages.nix` |
| CLI tool from nixpkgs, WSL | `home.packages` in `nix/home/linux/default.nix` |
| Program with a home-manager module | `nix/home/shared/` if portable, else `nix/home/darwin/` |
| GUI app | `casks` in `nix/configuration.nix` |
| App Store app | `masApps` in `nix/configuration.nix` |
| CLI tool **not** in nixpkgs | `brews` in `nix/configuration.nix` |
| VS Code extension | `nix/home/darwin/vscode.nix` |
| macOS setting | `system.defaults` in `nix/configuration.nix` |
| Background job | `launchd.agents` in a `nix/home/darwin/` module |

Order of preference is **nixpkgs, then a cask, then a brew formula.** nixpkgs
gives a pinned version and a rollback; Homebrew records only that something
should be installed, not which version. Every entry in `brews` carries a comment
saying why nixpkgs would not do, and that is the bar.

**Prefer a `programs.<name>` module over writing a config file yourself.**
home-manager ships 406 of them. The options are type-checked, the module knows
the file's real format, and modules compose: that is how
`programs.starship.enableZshIntegration` adds a line to the `.zshrc` that
`programs.zsh` generates. Only reach for `home.file` when no module exists.

Two documents go deeper:

- **[docs/adding-and-removing.md](docs/adding-and-removing.md)** has eight
  worked examples covering all nine rows above, with real tokens and the errors
  you should expect. The two CLI rows share one example, because a tool wanted on
  both machines is deliberately two edits.
- **[docs/nix-conventions.md](docs/nix-conventions.md)** covers the conventions
  behind them: module over file, ordering with `mkBefore`/`mkAfter`/`mkOrder`,
  how to verify before committing, and the traps this repo has actually hit.

The rest of this section is the short version for the two most common cases.

### A GUI app on the Mac (a cask)

**Find the real token first.** A wrong token does not fail the build, it fails
at activation, which is a slower way to find out. The app's name is often not
its token: Docker is `docker-desktop`, Wireshark is `wireshark-app`, DBeaver is
`dbeaver-community`, Ledger Live is `ledger-wallet`, and Eclipse is
`eclipse-ide`.

Watch for names that exist in both namespaces. `handbrake` is a formula (the
CLI) *and* a cask alias for `handbrake-app` (the GUI), so `brew install
handbrake` and `brew install --cask handbrake` give you different software.
`brew info --cask <token>` prints the token it actually resolved to, which is
how you catch an alias.

```sh
brew search --cask <name>
brew info --cask <token>     # confirm it is the thing you meant
```

Add it to `casks` in `nix/configuration.nix`, then rebuild.

**If Homebrew did not install the app in the first place, expect the first
rebuild to fail on it.** Homebrew tries to *adopt* the existing bundle and
refuses when the installed version differs from the cask's, which is the normal
state for anything that self-updates after a direct download:

```
Error: It seems the existing App is different from the one being installed.
```

Hand it over once, then rebuild again:

```sh
brew install --cask --force <token>
```

Do that deliberately, not reflexively. Adoption can be destructive: it may
remove the app before failing, which is what happened to Obsidian here.

### Removing a GUI app from the Mac

Remove the line from `casks` and rebuild. **That does not uninstall anything.**
`homebrew.onActivation.cleanup = "none"` means undeclared things are left alone,
so the app stays until you remove it yourself:

```sh
brew uninstall --cask <token>
brew uninstall --cask --force <token>   # if the app is already gone
```

The `--force` variant matters when you deleted the app by hand earlier:
Homebrew still has a record, and a plain `uninstall` errors with "It seems the
App source is not there."

Removing the declaration is the part that matters for reproducibility. A fresh
machine will not install it either way.

### A CLI tool on the Mac

**The nixpkgs attribute is often not the command name.** `telnet` comes from
`inetutils`, `helm` from `kubernetes-helm`, `sha256sum` from `coreutils`, `wp`
from `wp-cli`, and `cdk` from `aws-cdk-cli` (plain `cdk` in nixpkgs is an
unrelated curses library).

```sh
nix search nixpkgs <name>
```

Add the attribute to the right group in `nix/packages.nix`: `cli`, `media`,
`shell`, `vendored`, `languages` or `services`. Then rebuild.

Optionally add the **binary** name to the matching batch in `nix/verify.sh` so
it is asserted to resolve from Nix rather than Homebrew. Note the batches list
binaries, not attributes, precisely because the two diverge.

To remove: delete the line, rebuild, and drop it from `verify.sh` too or the
next run reports `MISSING`.

### A CLI tool on the WSL box

Check it exists for that platform first. Not everything in nixpkgs is built for
every system, and `vlc`, `obs-studio` and `virtualbox` are all absent on
aarch64-darwin, so the reverse happens too:

```sh
nix eval --raw nixpkgs#legacyPackages.x86_64-linux.<name>.version
```

Add it to `home.packages` in `nix/home/linux/default.nix`, then on that box:

```sh
home-manager switch --flake ~/dotfiles#jose@RockemSockem
```

To remove: delete the line and switch again. Standalone home-manager does
uninstall on removal, unlike the Homebrew path above.

### Checking before you commit

The Mac can verify its own changes:

```sh
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths
nix/verify.sh all
```

The WSL box cannot be built from the Mac, because cross-building x86_64-linux
from darwin needs a remote builder. Evaluation is the available check, and it
still catches a bad attribute name or a broken module:

```sh
nix eval '.#homeConfigurations."jose@RockemSockem".config.home.packages' --apply 'builtins.length'
```

## Worked examples

Moved to **[docs/adding-and-removing.md](docs/adding-and-removing.md)**, which
carries eight of them: a CLI tool on both machines (`bat`), a home-manager module
(`direnv`), a GUI app (Zed, and removing Minecraft), a brew formula with a
third-party tap, an App Store app, a VS Code extension, a macOS setting, and a
launchd background job. Each one names the file, shows the diff, gives the
activation command, and says what does *not* happen, which is usually the
surprising part.

## Traps worth knowing

**Nix only reads git-tracked files.** Add something under `nix/` and forget to `git add` it, and the rebuild reports that the path does not exist while you are staring right at it.

**Homebrew shadows Nix on `PATH` if you let it.** `brew shellenv` in `~/.zprofile` prepends `/opt/homebrew/bin`, which sits ahead of the Nix paths. The last `export PATH` in `nix/home/shared/shell.nix` re-asserts precedence, and `nix/verify.sh` asserts every declared binary actually resolves from Nix rather than Homebrew.

**`system.defaults` is enforced, not suggested.** Change one of those settings in System Settings and the next rebuild puts it back. More importantly, declaring a value that does not match the machine silently *changes* the machine rather than erroring, so read the current value before adding a setting.

**A declared cask is not free if Homebrew did not install the app.** Homebrew tries to adopt the existing bundle and refuses when versions differ, which is the normal state for anything that self-updates after a direct download. `brew install --cask --force <token>` hands it over once.

```sh
nix/verify.sh all      # every package batch, the symlink table, the agents
nix/verify.sh links    # just the symlinks
nix/verify.sh agents   # just the launchd agents
```

## Editor

Neovim, from nixpkgs, deliberately kept as a terminal editor rather than an IDE. Nine plugins, treesitter with a fixed grammar set, no LSP, no formatters, no plugin manager. It is `$EDITOR`, so its most common job is commit messages and config edits.

Plugins and grammars are declared in `nix/home/shared/nvim.nix`; the Lua lives in `nvim/init.lua` and is read into the Nix at build time.

(I used to use vim-plug and made [a video](https://www.youtube.com/watch?v=gRxGH2HA2_8) about it. Still a decent watch if you're on Vim rather than Neovim.)

## Terminal

- [Alacritty](https://alacritty.org/) and iTerm
- tmux, with plugins from nixpkgs rather than tpm
- zsh
- [Starship](https://starship.rs/)

The terminal font is FiraCode Nerd Font Mono, declared in `nix/configuration.nix`. Without it the prompt glyphs render as boxes, so it is a real dependency rather than a preference.

## Keyboard mapping

[Karabiner](https://karabiner-elements.pqrs.org/) and [Hammerspoon](https://www.hammerspoon.org/) re-bind modifier+keys across applications. I also use [modals](https://www.hammerspoon.org/docs/hs.hotkey.modal.html) to add layers beyond modifiers.

Karabiner's config is written as `karabiner/karabiner.edn` and compiled into the `karabiner.json` that Karabiner-Elements actually reads by [goku](https://github.com/yqrashawn/GokuRakuJoudo), which comes from nixpkgs. Without goku the `.edn` does nothing, which is why the watcher above is declared rather than left to `brew services`.

Several macOS shortcuts are deliberately disabled so their keys are free for Karabiner, Hammerspoon and tmux: both screenshot chords, Cmd-Opt-D, and the two input-source cycles that would otherwise claim Ctrl-Space. Those live in an activation script rather than `system.defaults`, because `AppleSymbolicHotKeys` is one dictionary holding every shortcut on the machine and a plain write would replace all of it.

`docs/keyboard-workflow.md` explains the layering in detail.

## Notes to self

- `docs/adding-and-removing.md` is the cookbook: eight worked examples, one per kind of thing this repo declares.
- `docs/nix-conventions.md` is the conventions behind them, written for someone new to Nix: module over file, where a new thing goes, ordering, how to verify, and the traps this repo has hit.
- `docs/nix-reproducibility-review.md` tracks what is still not declarative, plus known issues not yet fixed.
- `docs/reproducibility-audit-2026-08-09.md` is the full audit: what a fresh machine would not get, and what has since been closed.
- `docs/keyboard-workflow.md` explains the Karabiner and Hammerspoon layering.
