![](./dotfiles.png)

my hard work /
by these words guarded /
please steal. (c) JoseCanHelp

# JoseCanHelp

Declarative dotfiles for macOS and WSL2, built with Nix, nix-darwin, and
home-manager. The flake manages packages, applications, macOS settings, shell,
editor, and background jobs.

Borrowing is encouraged. If you take something from here, a link back is
appreciated.

## macOS Setup

1. Install [Determinate Nix](https://docs.determinate.systems/).
2. Clone this repository to `~/dotfiles`. That path is part of the linked-file
   configuration.

   ```sh
   git clone git@github.com:josecanhelp/dotfiles.git ~/dotfiles
   ```

3. Add a host block to `flake.nix` if the machine is not already listed.
4. Apply the configuration:

   ```sh
   sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
   ```

5. Create `~/.secrets` if needed. It is sourced by zsh and is not tracked.

There is no install script, manual `brew bundle` step, or plugin manager to
bootstrap.

## Adding A Mac

Add one block to `darwinConfigurations` in `flake.nix`:

```nix
"Joses-Mac-mini" = mkHost {
  hostname = "Joses-Mac-mini";
  user = "jose";
};
```

The attribute name, `hostname`, and the name passed to `darwin-rebuild` must
match. For an Intel Mac, also set `system = "x86_64-darwin"`.

Machine-specific changes belong in a separate module passed through
`extraModules`; shared settings stay in the existing modules.

## WSL2

The Linux target is standalone home-manager. It manages `$HOME`, not the
machine, and does not evaluate the macOS nix-darwin or Homebrew configuration.

First activation:

```sh
nix run home-manager/master -- switch -b bak --flake ~/dotfiles#jose@RockemSockem
```

Later activations:

```sh
home-manager switch --flake ~/dotfiles#jose@RockemSockem
```

The Linux output imports the portable modules under `nix/home/shared/` and its
own package and shell settings from `nix/home/linux/default.nix`.

## Configuration Layers

Use the layer that owns the thing being configured:

| Layer | Scope | Main files |
|---|---|---|
| Flake | Inputs and package versions | `flake.nix`, `flake.lock` |
| nix-darwin | The macOS machine | `nix/configuration.nix`, `nix/packages.nix` |
| nix-homebrew | Homebrew installation and trust | `flake.nix`, `nix/configuration.nix` |
| home-manager | User files and user launchd agents | `nix/home/` |
| Linked source files | Runtime-editable configurations | `hammerspoon/`, `karabiner/`, `amethyst/`, `bin/` |

As a rule, use nix-darwin for machine-wide settings and home-manager for files
in the home directory. Homebrew declarations are macOS-only: `brews`, `casks`,
and `masApps` live in the `homebrew` block in `nix/configuration.nix`.

## Where Things Live

### Both machines

| Change | File |
|---|---|
| Shell aliases, prompt, or environment | `nix/home/shared/shell.nix` |
| Git configuration | `nix/home/shared/git.nix` |
| tmux configuration | `nix/home/shared/tmux.nix` |
| Neovim packages or configuration | `nix/home/shared/nvim.nix`, `nvim/init.lua` |

### macOS only

| Change | File |
|---|---|
| CLI packages | `nix/packages.nix` |
| GUI apps, brew formulas, or App Store apps | `nix/configuration.nix` |
| macOS defaults, fonts, or activation scripts | `nix/configuration.nix` |
| Linked application configurations | `nix/home/darwin/default.nix` and its modules |
| Login or background jobs | `nix/home/darwin/` |

### WSL2 only

| Change | File |
|---|---|
| CLI packages and Linux-only settings | `nix/home/linux/default.nix` |

Adding a CLI tool to both machines requires two edits because the Mac uses
`environment.systemPackages` and Linux uses `home.packages`. The lists are
intentionally different.

## Generated And Linked Files

Most configuration is generated into the Nix store and linked into place. Edit
the Nix module and rebuild it.

These files are linked directly from the checkout so their owning tools can
edit or reload them without a rebuild:

| Tool | Source |
|---|---|
| Hammerspoon | `hammerspoon/` |
| Karabiner and Goku input | `karabiner/karabiner.edn` |
| Amethyst | `amethyst/amethyst.yml` |
| Claude notification hook | `claude/notify.sh` |
| Claude status line | `claude/statusline.sh` |
| Personal scripts | `bin/` |
| Login suppression | `hushlogin` |

Two files are sourced from the checkout rather than linked: the zsh functions
file and `tmux/tmuxline`. The supported checkout path is `~/dotfiles`.

## Verification

Build the macOS system without activating it:

```sh
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths
```

Check declared binaries, links, and launchd agents:

```sh
nix/verify.sh all
nix/verify.sh links
nix/verify.sh agents
```

The Linux output can be evaluated from the Mac, but not cross-built without a
Linux builder:

```sh
nix eval '.#homeConfigurations."jose@RockemSockem".config.home.packages' --apply 'builtins.length'
```

Nix reads repository files as flake inputs, so add new files to git before
building them.

## Detailed Guides

- [Adding and removing things](docs/adding-and-removing.md) is the practical
  cookbook for packages, modules, Homebrew, apps, extensions, settings, and
  background jobs.
- [Nix conventions](docs/nix-conventions.md) explains module choices, portable
  versus platform-specific configuration, ordering, and verification.
- [Keyboard workflow](docs/keyboard-workflow.md) explains the Karabiner and
  Hammerspoon layers.
- [Reproducibility review](docs/nix-reproducibility-review.md) tracks remaining
  non-declarative state and known gaps.
- [Historical audit](docs/archive/reproducibility-audit-2026-08-09.md) records
  the original machine audit and its resolved findings.

## Daily Notes

Neovim is a terminal editor managed through `nix/home/shared/nvim.nix` and
`nvim/init.lua`. tmux uses plugins from nixpkgs rather than tpm. The terminal
font is FiraCode Nerd Font Mono, declared in `nix/configuration.nix`.

Karabiner reads the generated `karabiner.json`, which is compiled from
`karabiner/karabiner.edn` by the declared Goku launchd agent. Hammerspoon owns
the higher-level, application-specific keyboard actions.
