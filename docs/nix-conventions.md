# Nix Conventions

This page explains the boundaries and rules of the repository. For step-by-step
changes, use [adding-and-removing.md](adding-and-removing.md).

## Core Rules

### Declare what matters

If a tool or setting is worth keeping, declare it in this repository. An
imperative install or preference is invisible to a fresh machine and creates
drift.

When removing something, remove both sides of the state: its declaration and
the installed item. Home-manager removes its own packages; Homebrew is set to
`cleanup = "none"`, so Homebrew items must be uninstalled separately.

### Prefer modules

Use a `programs.<name>` home-manager module when one exists. Modules provide
typed options, generate the correct file format, and compose with other
modules. Use `home.file` with inline text only when no module exists.

Use `mkOutOfStoreSymlink` only for configurations that need direct editing or
are written by their owning tool. This repo uses that approach for Hammerspoon,
Karabiner, Amethyst, and personal scripts. The cost is a dependency on the
checkout at `~/dotfiles`.

## Module Boundaries

| What it is | File | Applies to |
|---|---|---|
| Mac CLI package from nixpkgs | `nix/packages.nix` | macOS |
| Linux CLI package | `nix/home/linux/default.nix` | WSL2 |
| Portable home-manager module | `nix/home/shared/` | both machines |
| Mac-only home-manager module | `nix/home/darwin/` | macOS |
| GUI or App Store app | `nix/configuration.nix` | macOS |
| Brew-only formula | `nix/configuration.nix` | macOS |
| VS Code extension | `nix/home/darwin/vscode.nix` | macOS |
| Mac setting or system package | `nix/configuration.nix`, `nix/packages.nix` | macOS |
| User background job | `launchd.agents` in `nix/home/darwin/` | macOS |

The Mac uses nix-darwin's `environment.systemPackages`; Linux uses
home-manager's `home.packages`. A package wanted on both machines therefore
needs two entries. The lists are intentionally different and should not be
forced into an abstraction just to avoid the duplication.

`shared/` is a portability promise. Do not put macOS paths, commands, or
options there. If a setting differs by platform, keep the platform-specific
part in `nix/home/darwin/` or `nix/home/linux/`.

## Package Choice

Prefer, in order:

1. nixpkgs, for pinned versions and rollback support.
2. A Homebrew cask, for macOS GUI applications unavailable in nixpkgs.
3. A Homebrew formula, only when nixpkgs cannot provide the tool.

Every `homebrew.brews` entry needs a short reason why nixpkgs was not used.
Homebrew records that a package should exist, not its version, so it has weaker
reproducibility than Nix.

Homebrew configuration is macOS-only. The `homebrew` block in
`nix/configuration.nix` declares `taps`, `brews`, `casks`, and `masApps`; the
`nix-homebrew` module in `flake.nix` manages the Homebrew installation and tap
trust. A third-party tap must be listed in both places.

Names often differ between the declaration and the command. Look up the real
name before adding it:

| Thing | Lookup |
|---|---|
| nixpkgs package | `nix search nixpkgs <name>` |
| Homebrew cask token | `brew info --cask <name>` |
| App Store identifier | `mdls -name kMDItemAppStoreAdamID <app>` |

`nix/verify.sh` checks executable names, not nixpkgs attributes. For example,
`inetutils` provides `telnet` and `kubernetes-helm` provides `helm`.

## Generated File Ordering

Home-manager assembles shell files from multiple modules. Use ordering helpers
when the resulting order matters:

| Helper | Priority |
|---|---:|
| `lib.mkBefore` | 500 |
| default | 1000 |
| `lib.mkAfter` | 1500 |
| `lib.mkOrder n` | explicit |

The Darwin shell configuration uses explicit priorities for completion setup,
Starship, notifications, and the final PATH correction that puts Nix ahead of
Homebrew. Do not rely on module import order when two blocks must be ordered.

Comments inside Nix multiline strings become generated configuration comments;
changing them can change the generated file and system hash. Comments outside
those strings do not affect the generated output.

## Verification

Build without activating:

```sh
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths
```

Check binaries, linked files, and launchd agents:

```sh
nix/verify.sh all
nix/verify.sh links
nix/verify.sh agents
```

Evaluate the Linux output from the Mac:

```sh
nix eval '.#homeConfigurations."jose@RockemSockem".config.home.packages' --apply 'builtins.length'
```

Inspect generated output when changing shell composition rather than assuming
the module order produced what you intended. Add new files to git before
building: flake evaluation only sees tracked inputs.

## Known Constraints

- `system.defaults` enforces values on activation. Read the current macOS
  setting before declaring a value.
- Homebrew cask adoption can fail when an app was installed outside Homebrew;
  hand it over with `brew install --cask --force <token>` once.
- `~/.secrets` stays outside the repository and is sourced only when present.
- The VS Code settings file is intentionally unmanaged because taking ownership
  of it would replace the whole hand-maintained file.
