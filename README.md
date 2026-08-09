![](./dotfiles.png)

my hard work / 
by these words guarded /
please steal. (c) JoseCanHelp

# JoseCanHelp

I'm a vim-loving dev and I try my best to automate as much as I can. Hopefully, you find a golden nugget here and there as you search for ways to improve your configurations.

Find me on [twitter](https://twitter.com/josecanhelp).

If you happen to copy anything from this repository or if you are inspired by this repository to do something your own customized way, please link back to this repo in yours. I will do the same for the folks I have "borrowed" from. Cheers!

## Setting up a new machine

1. **Install [Determinate Nix](https://docs.determinate.systems/)**. Everything else depends on it. Note this repo sets `nix.enable = false` because Determinate manages the daemon itself, and nix-darwin should not fight it.

2. **Clone this repo to `~/dotfiles`.** The path matters: `zsh/zshrc` and the dotbot links both reference it.

   ```sh
   git clone --recursive git@github.com:josecanhelp/dotfiles.git ~/dotfiles
   ```

3. **Build the system.** The attribute name must match the machine's hostname.

   ```sh
   sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
   ```

   To add a machine, add one line to `darwinConfigurations` in `flake.nix`.

4. **Link the dotfiles** that Nix does not manage yet.

   ```sh
   cd ~/dotfiles && ./install
   ```

5. **Create `~/.secrets`** if you need it. It is sourced by `zsh/zshrc` and deliberately kept out of this repo.

Nix only reads files that git tracks. If you add something to `nix/` and the
rebuild claims it does not exist, you forgot to `git add` it.

## How this is managed

Three systems, in descending order of how much I trust them:

| Layer | Manages | Where |
|---|---|---|
| **nix-darwin** | CLI packages, language runtimes, fonts, macOS system settings | `nix/packages.nix`, `nix/configuration.nix` |
| **nix-homebrew** | Homebrew itself, plus GUI casks and the few formulae nixpkgs lacks | `nix/configuration.nix` |
| **dotbot** | Symlinking config files into `$HOME` | `install.conf.yaml` |

The plan is for home-manager to take over that third row. Until then, `./install` is still a required step on a new machine.

`nix/verify.sh` asserts that the packages actually resolve from Nix rather than
Homebrew, which matters because Homebrew's `brew shellenv` prepends itself to
`PATH` and will silently shadow everything if you let it.

## Vim

Neovim comes from nixpkgs. Plugins are managed by
[lazy.nvim](https://github.com/folke/lazy.nvim), pinned in `nvim/lazy-lock.json`.

(I used to use vim-plug and made [a video](https://www.youtube.com/watch?v=gRxGH2HA2_8) about it. Still a decent watch if you're on Vim rather than Neovim.)

## Terminal

- [Alacritty](https://alacritty.org/) and iTerm
- tmux
- zsh shell
- [Starship Prompt](https://starship.rs/)

The terminal font is FiraCode Nerd Font Mono, declared in `nix/configuration.nix`.
Without it the prompt glyphs render as boxes, so it is a real dependency rather
than a preference.

## Keyboard Mapping

[Karabiner](https://karabiner-elements.pqrs.org/) and [Hammerspoon](https://www.hammerspoon.org/) are used heavily to completely re-bind modifier+keys across applications. I also make use of [modals](https://www.hammerspoon.org/docs/hs.hotkey.modal.html) to add multiple layers to my keyboard beyond modifiers.

Karabiner's config is written as `karabiner/karabiner.edn` and compiled to the
`karabiner.json` that Karabiner-Elements actually reads by
[goku](https://github.com/yqrashawn/GokuRakuJoudo), which comes from nixpkgs.
Without goku the `.edn` file does nothing.

## Notes to self

- `docs/nix-reproducibility-review.md` tracks what still is not declarative.
- `docs/superpowers/specs/` and `docs/superpowers/plans/` hold the migration
  specs and plans.
