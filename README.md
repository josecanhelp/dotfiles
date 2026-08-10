![](./dotfiles.png)

my hard work / 
by these words guarded /
please steal. (c) JoseCanHelp

# JoseCanHelp

I'm a vim-loving dev and I try my best to automate as much as I can. Hopefully, you find a golden nugget here and there as you search for ways to improve your configurations.

Find me on [twitter](https://twitter.com/josecanhelp).

If you happen to copy anything from this repository or if you are inspired by this repository to do something your own customized way, please link back to this repo in yours. I will do the same for the folks I have "borrowed" from. Cheers!

## Setting up a new machine

1. **Install [Determinate Nix](https://docs.determinate.systems/).** Everything else depends on it. This repo sets `nix.enable = false` because Determinate manages the daemon itself and nix-darwin should not fight it.

2. **Clone to `~/dotfiles`.** The path matters: home-manager's links point at it by absolute path.

   ```sh
   git clone git@github.com:josecanhelp/dotfiles.git ~/dotfiles
   ```

3. **Build the system.** The attribute name must match the machine's hostname.

   ```sh
   sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
   ```

4. **Create `~/.secrets`** if you need it. It is sourced by zsh and deliberately kept out of this repo.

That is the whole setup. No install script, no `brew bundle`, no plugin managers to bootstrap.

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
| home-manager | my home directory | `~/`, plus my own launchd agents | `nix/home/` |

## Generated vs linked

Every config in this repo is handled one of two ways, and the difference decides how you edit it.

**Generated** means Nix writes the file into `/nix/store` and symlinks it into place. The file is read-only. To change it, edit the Nix and rebuild.

**Linked** means home-manager symlinks the repo file itself into place via `mkOutOfStoreSymlink`. Edits take effect immediately, no rebuild. This is used where a tool writes into its own config directory at runtime, which a read-only store path would break.

| Tool | What it does | How | Edit this |
|---|---|---|---|
| **zsh** | shell | generated | `nix/home/shell.nix` |
| **starship** | prompt | generated | `nix/home/shell.nix` |
| **git** | version control | generated | `nix/home/git.nix` |
| **alacritty** | terminal | generated | `nix/home/alacritty.nix` |
| **tmux** | multiplexer | generated | `nix/home/tmux.nix` |
| **neovim** | editor | generated | `nix/home/nvim.nix`, `nvim/init.lua` |
| **hammerspoon** | window and keyboard automation | linked | `hammerspoon/` |
| **karabiner** | keyboard remapping | linked | `karabiner/karabiner.edn` |
| **amethyst** | tiling window manager | linked | `amethyst/amethyst.yml` |
| `~/.bin` | my own scripts | linked | `bin/` |
| `~/.hushlogin` | suppresses the login banner | linked | `hushlogin` |

Hammerspoon is linked because it writes Spoons into its own directory. Karabiner is linked because goku compiles the `.edn` and Karabiner-Elements writes `karabiner.json` alongside it.

Two files are neither generated nor linked. They are sourced by absolute path from the repo:

- `zsh/custom/functions.zsh`, sourced from `programs.zsh.initContent`
- `tmux/tmuxline`, sourced from `programs.tmux.extraConfig`

Shell functions have no Nix representation, so they stay real files and stay instantly editable.

## Background jobs

Two things run outside any app, registered through launchd. A watcher recompiles `karabiner.edn` to `karabiner.json` on save, declared in `nix/home/karabiner.nix`. A login job opens Alacritty fullscreen with the restored tmux session, declared in `nix/home/tmux.nix`. Both use home-manager's `launchd.agents.*`, not nix-darwin's `launchd.user.agents.*`: home-manager's version runs as me with no sudo, which matches everything else in `nix/home/`, and using the wrong one either fails to evaluate there or registers a second, competing agent from `nix/configuration.nix`.

## Where things live

| Want to change | File |
|---|---|
| A CLI tool or language runtime | `nix/packages.nix` |
| A GUI app (cask) or a brew-only formula | `nix/configuration.nix`, `homebrew` block |
| macOS settings: Dock, Finder, key repeat | `nix/configuration.nix`, `system.defaults` |
| Fonts | `nix/configuration.nix`, `fonts.packages` |
| Which files get symlinked into `$HOME` | `nix/home/default.nix`, `nix/home/karabiner.nix` |
| A login or background job (launchd agent) | `nix/home/karabiner.nix` (goku watcher), `nix/home/tmux.nix` (tmux login job) |
| Add another machine | `flake.nix`, one line in `darwinConfigurations` |
| Package versions | `nix flake update`, then rebuild |

## Two traps worth knowing

**Nix only reads git-tracked files.** Add something under `nix/` and forget to `git add` it, and the rebuild reports that the path does not exist while you are staring right at it.

**Homebrew shadows Nix on `PATH` if you let it.** `brew shellenv` in `~/.zprofile` prepends `/opt/homebrew/bin`, which sits ahead of the Nix paths. The last `export PATH` in `nix/home/shell.nix` re-asserts precedence, and `nix/verify.sh` asserts every declared binary actually resolves from Nix rather than Homebrew.

```sh
nix/verify.sh all      # every package batch plus the symlink table
nix/verify.sh links    # just the symlinks
```

## Editor

Neovim, from nixpkgs, deliberately kept as a terminal editor rather than an IDE. Nine plugins, treesitter with a fixed grammar set, no LSP, no formatters, no plugin manager. It is `$EDITOR`, so its most common job is commit messages and config edits.

Plugins and grammars are declared in `nix/home/nvim.nix`; the Lua lives in `nvim/init.lua` and is read into the Nix at build time.

(I used to use vim-plug and made [a video](https://www.youtube.com/watch?v=gRxGH2HA2_8) about it. Still a decent watch if you're on Vim rather than Neovim.)

## Terminal

- [Alacritty](https://alacritty.org/) and iTerm
- tmux, with plugins from nixpkgs rather than tpm
- zsh
- [Starship](https://starship.rs/)

The terminal font is FiraCode Nerd Font Mono, declared in `nix/configuration.nix`. Without it the prompt glyphs render as boxes, so it is a real dependency rather than a preference.

## Keyboard mapping

[Karabiner](https://karabiner-elements.pqrs.org/) and [Hammerspoon](https://www.hammerspoon.org/) re-bind modifier+keys across applications. I also use [modals](https://www.hammerspoon.org/docs/hs.hotkey.modal.html) to add layers beyond modifiers.

Karabiner's config is written as `karabiner/karabiner.edn` and compiled into the `karabiner.json` that Karabiner-Elements actually reads by [goku](https://github.com/yqrashawn/GokuRakuJoudo), which comes from nixpkgs. Without goku the `.edn` does nothing.

`docs/keyboard-workflow.md` explains the layering in detail.

## Notes to self

- `docs/nix-reproducibility-review.md` tracks what is still not declarative, plus known issues not yet fixed.
- `docs/keyboard-workflow.md` explains the Karabiner and Hammerspoon layering.
