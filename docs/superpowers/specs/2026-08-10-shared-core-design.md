# Shared core across macOS and WSL (sub-project 6)

**Date:** 2026-08-10
**Status:** Approved, not yet implemented
**Repo:** `~/dotfiles`, branch `main`

## Goal

Share the platform-neutral half of `nix/home/` between the Mac and a WSL2 Linux
box, so both get the same shell, editor, git and tmux without either platform's
quirks leaking into the other.

## Context

**The Mac:** `REM-JoseS-MBP1`, aarch64-darwin, nix-darwin plus nix-homebrew
plus home-manager. Working and verified by `nix/verify.sh all` and two launchd
agents.

**The new machine:** `RockemSockem`, x86_64-linux, WSL2 (kernel
6.18.33.1-microsoft-standard-WSL2), user `jose`. State: the repo is cloned at
`~/dotfiles` and Determinate Nix is installed. Nothing else. No home-manager,
no dotfiles managed by anything.

`mkHost` cannot serve it. That function builds `nix-darwin` systems and
nix-darwin is macOS-only, so the Linux box needs a separate flake output driven
by standalone home-manager.

### What is portable, verified by reading each module

| Module | Verdict |
|---|---|
| `nvim.nix` | Portable as-is. Neovim from nixpkgs, `initLua` read from `nvim/init.lua` |
| `git.nix` | Portable **except** line 35, `credential.helper = "osxkeychain"`, which does not exist on Linux |
| `tmux.nix` | Portable except the `osascript` alert-bell hook (line 112) and `launchd.agents.tmux-boot` (line 141). The `tmuxline` source at line 107 uses `~/dotfiles`, which holds on both |
| `shell.nix` | Portable core, with five darwin-specific pieces listed below |
| `java.nix` | Portable, but out of scope: no Java work happens on the WSL box |
| `karabiner.nix`, `alacritty.nix` | macOS only |
| `configuration.nix`, `packages.nix` | nix-darwin options. Cannot port at all |

`shell.nix`'s darwin-specific pieces, by line: `profileExtra` running
`brew shellenv` (60-63), `ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX` (77), the
`~/.docker/completions` fpath entry (179), the final
`export PATH="/run/current-system/sw/bin:$PATH"` (230, a nix-darwin path that
does not exist on Linux), and `gdesc` piping to `pbcopy` (146).

## Decisions

**Directory split rather than in-module conditionals.** The alternative was
`lib.mkIf pkgs.stdenv.isDarwin` guards inside the existing flat files. That
moves fewer files but scatters platform logic through every module. A visible
boundary in the tree is easier to reason about, and makes "is this shared?" a
question you answer by looking at the path.

**Standalone home-manager on Linux, not NixOS-WSL.** NixOS-WSL would make the
whole machine declarative, but it requires re-provisioning the distro and the
stated need is terminal tooling, not system management.

**Terminal dev core only on Linux.** `packages.nix` declares 51 through
`environment.systemPackages`, a nix-darwin option, so the Linux list is written
fresh in `home.packages` rather than shared. Sharing a package list across a
system option and a home option is not worth the indirection at this size.

The exact list, so the plan does not have to guess:

```nix
home.packages = with pkgs; [
  actionlint
  btop
  fzf
  gh
  git-filter-repo
  htop
  jq
  pstree
  ripgrep
  tree
  watchexec
  wget
];
```

Twelve, plus `git`, `starship`, `tmux`, `neovim` and `zsh` which arrive through
their `programs.*` modules rather than as packages.

Deliberately excluded, with reasons, so nobody re-derives this: `coreutils`
(Linux already has GNU coreutils, unlike macOS), `goku` (drives Karabiner),
`jadx` (Android GUI work), `inetutils`, `nmap`, `pandoc`, `typst`, `ranger`,
`joker`, `yt-dlp`, `uv`, `shopify-cli`, `stripe-cli` (not core to terminal dev
on this box), and everything in the `media`, `vendored`, `languages` and
`services` groups.

**`osxkeychain` moves to a darwin-only file.** Approved explicitly. Linux gets
no credential helper for now; git will prompt. Adding `credential.helper =
"store"` or a libsecret helper is a later decision, not this one.

**`zsh/custom/functions.zsh` stays darwin-only.** Approved explicitly. It calls
`open` in four places: `openpr`, the Bitbucket URL helper, a Hammerspoon reload,
and a fallback `/usr/bin/open`. Sourcing it on Linux would install functions
that fail. Splitting it is its own job.

**Linked files:** darwin keeps all five it has today. Linux gets `.bin` only,
since `bin/` holds `git-wtf` and `zsh-colors`, both portable shell scripts.
`.hammerspoon`, `.amethyst.yml`, `.hushlogin` and `.claude/notify.sh` are
macOS-specific or depend on `osascript`.

## Architecture

```
nix/home/
  shared/
    git.nix        minus credential.helper
    nvim.nix       unchanged behaviour
    shell.nix      zsh, starship, portable aliases and initContent
    tmux.nix       minus the osascript hook and the launchd agent
  darwin/
    default.nix    imports ../shared + the files below; the current
                   default.nix's home.file and xdg.enable move here
    alacritty.nix  moved unchanged
    karabiner.nix  moved unchanged
    java.nix       moved unchanged
    extras.nix     the darwin half of shell and tmux and git:
                   profileExtra, ITERM_*, docker completions fpath,
                   the /run/current-system PATH line, pbcopy in gdesc,
                   osxkeychain, the osascript alert-bell hook,
                   launchd.agents.tmux-boot, functions.zsh sourcing
  linux/
    default.nix    imports ../shared + home.packages + .bin link
```

`nix/configuration.nix` changes one line: `users.${user} = import ./home;`
becomes `import ./home/darwin`.

### flake.nix

`home-manager` is already an input, so this is purely additive:

```nix
homeConfigurations."jose@RockemSockem" =
  home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    modules = [ ./nix/home/linux ];
    extraSpecialArgs = { user = "jose"; };
  };
```

Activated on that box with:

```sh
home-manager switch --flake ~/dotfiles#jose@RockemSockem
```

Standalone home-manager needs `home.username`, `home.homeDirectory` and
`home.stateVersion` set explicitly, which the darwin path gets from nix-darwin.
Those go in `linux/default.nix`.

### The riskiest part: initContent ordering

`shared/shell.nix` keeps `programs.zsh.initContent` as a `lib.mkMerge` of three
blocks at `mkBefore`, `mkOrder 1100` and `mkAfter`. `darwin/extras.nix` adds a
fourth block, and its priority decides whether the Homebrew PATH override still
runs last.

This repo has already been bitten here once: a pure file move changed the system
hash because starship's own `initContent` at the default priority 1000 tied with
a custom block, and the new module nesting flipped the tie. The fix was an
explicit `lib.mkOrder 1100`.

So the darwin PATH override must carry an explicit order **after** `mkAfter`
(1500), and the no-regression check below is what proves it.

## Verification

**The Mac must not regress.** The strongest available check: the system hash
before and after must be **identical**, because this is a file move plus a
platform split, not a behaviour change.

```sh
readlink /run/current-system     # 8j0sbgyka96z1rmm0nfq5nbkbqbkd2rp before
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths
```

If the hash differs, something moved that should not have, most likely
`initContent` ordering. Diff the generated `.zshrc` against the current one
before doing anything else.

Then, after activation:

- `nix/verify.sh all` passes, including the agents batch
- Both launchd agents still registered
- The generated `~/.zshrc` is byte-identical to the current one
- A clean login shell still has `brew` from Homebrew and `git` from Nix in the
  right precedence

**The Linux side cannot be built here.** Cross-building x86_64-linux from
darwin needs a remote builder this machine does not have. What is possible from
the Mac:

```sh
nix eval .#homeConfigurations."jose@RockemSockem".config.home.username
```

That proves the configuration evaluates, the module tree resolves, and no
darwin-only option leaked into the shared modules. It does not prove it builds.

Building and activating happen on RockemSockem, by hand:

```sh
home-manager switch --flake ~/dotfiles#jose@RockemSockem
```

Expect a first-run conflict on `~/.bashrc` or `~/.profile` if the distro shipped
them; home-manager will refuse rather than clobber. `-b bak` on the first switch
resolves it.

Then on that box: `zsh` runs, starship prompt appears, `nvim` starts clean,
`git config --get user.name` returns the shared identity, and `tmux` starts with
the shared keybindings.

## Two things to document, not discover

**zsh will not be the login shell.** A fresh WSL distro uses bash.
`programs.zsh` puts zsh in the profile but does not change the shell. Needs a
one-time `chsh -s ~/.nix-profile/bin/zsh`, and `~/.nix-profile/bin/zsh` may need
adding to `/etc/shells` first.

**`nvim.nix` moving one level deeper changes a relative path.**
`builtins.readFile ../../nvim/init.lua` becomes `../../../nvim/init.lua`. Nix
will error clearly if it is wrong, but it is the kind of thing that gets missed
in a move.

## Done when

- `nix/home/` is split into `shared/`, `darwin/` and `linux/`
- The Mac's system hash is unchanged and `verify.sh all` passes
- `flake.nix` exposes `homeConfigurations."jose@RockemSockem"` and it evaluates
- `README.md` documents the WSL bootstrap, including the `chsh` step and the
  `-b bak` first-run flag
- The WSL box has zsh, starship, nvim, git and tmux from this repo

## Out of scope

- Making `functions.zsh` portable
- A Linux git credential helper
- Java, cloud CLIs or media tooling on the WSL box
- NixOS-WSL, or managing anything about that machine beyond `$HOME`
- Alacritty config for Linux: WSL uses Windows Terminal
- The remaining audit items (`programs.fzf`, `programs.vscode`, MAS apps)
