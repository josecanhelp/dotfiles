# Reproducibility review: what's missing to rebuild this machine from scratch

**Date:** 2026-08-08
**Question:** if you ran this flake on a brand new Mac, what would be wrong?

Packages are done. Everything below is what packages alone don't cover.

## Verified against nixpkgs 26.05 / nix-darwin on aarch64-darwin

Every attribute named here was checked to exist before being recommended.

---

## Tier 1: a fresh machine is visibly broken without these

### 1. Fonts are not declared

`~/Library/Fonts` holds **290 manually installed fonts**. This is not
cosmetic: `alacritty/alacritty.toml` hard-requires one of them.

```toml
family = "FiraCode Nerd Font Mono"
```

On a new machine Alacritty falls back to a default face and every glyph in
the Starship prompt renders as a box.

```nix
fonts.packages = with pkgs; [ nerd-fonts.fira-code ];
```

`nerd-fonts.fira-code` exists in your pinned nixpkgs. nix-darwin exposes
`fonts.packages` and `fonts.fontDir`. The other 289 are mostly design
files and probably do not belong in the flake, but the one the terminal
depends on does.

### 2. `goku` is a hard dependency of your Karabiner setup

`install.conf.yaml` links `karabiner/karabiner.edn`, but `.edn` is source,
not config. Karabiner-Elements reads `karabiner.json`, which `goku`
compiles from the `.edn`. Without goku, your keyboard customisations
cannot be built at all.

It comes from the `yqrashawn/goku` tap and **was never in migration scope**
(see the tap blind spot below). It is in nixpkgs:

```nix
goku
```

### 3. The hostname is hardcoded

```nix
darwinConfigurations."REM-JoseS-MBP1" = nix-darwin.lib.darwinSystem { ... };
```

A second machine cannot use this flake without editing it. Options, in
increasing order of effort:

- Add a second `darwinConfigurations.<hostname>` entry sharing the same
  modules
- Factor the shared modules into a `let` binding and instantiate per host
- Generate configurations from a list of hostnames

The second is usually the right size for two or three machines.

### 4. Bootstrap is undocumented

A fresh machine needs Determinate Nix installed before this flake can do
anything, and `README.md` still describes the pre-Nix world: dotbot as the
framework and vim-plug for Vim plugins (you moved to lazy.nvim). Someone
following the README today, including you in a year, gets the wrong
mental model.

Minimum viable bootstrap section:

1. Install Determinate Nix
2. `git clone --recursive` this repo to `~/dotfiles`
3. `sudo darwin-rebuild switch --flake ~/dotfiles#<hostname>`

**Resolved.** `README.md` now carries exactly this section, and step 4 is
gone: home-manager owns the links, so there is no imperative step left.

---

## Tier 2: cheap, high value

### 5. macOS system defaults

You have real customisations that exist nowhere but in this machine's
preference database. Measured, not guessed:

| Domain | Setting | Current |
|---|---|---|
| Dock | `autohide` | 1 |
| Dock | `tilesize` | 36 |
| Dock | `mru-spaces` | 0 |
| Finder | `ShowPathbar` | 1 |
| Finder | `FXPreferredViewStyle` | `Nlsv` (list) |
| Finder | `_FXSortFoldersFirst` | 1 |
| Keyboard | `KeyRepeat` | 2 |
| Keyboard | `InitialKeyRepeat` | 15 |
| Keyboard | `ApplePressAndHoldEnabled` | 0 |

All are covered by nix-darwin's `system.defaults`, which exposes `dock`,
`finder`, `NSGlobalDomain`, `trackpad`, `screencapture`, `spaces`,
`loginwindow`, `controlcenter` and more:

```nix
system.defaults = {
  dock = { autohide = true; tilesize = 36; mru-spaces = false; };
  finder = {
    ShowPathbar = true;
    FXPreferredViewStyle = "Nlsv";
    _FXSortFoldersFirst = true;
  };
  NSGlobalDomain = {
    KeyRepeat = 2;
    InitialKeyRepeat = 15;
    ApplePressAndHoldEnabled = false;
  };
};
```

The fast key repeat in particular is the kind of thing you would notice
within thirty seconds on a new machine and spend twenty minutes
rediscovering.

### 6. The tap blind spot

**`brew leaves` does not list formulae from third-party taps.** The
packages migration was scoped from `brew leaves`, so these six were never
considered, and none of them are declared anywhere:

| Formula | Tap | In nixpkgs? |
|---|---|---|
| `goku` | yqrashawn/goku | **yes** |
| `stripe` | stripe-cli | **yes** (`stripe-cli`) |
| `shopify-cli` | shopify/shopify | **yes** (`shopify-cli`) |
| `themekit` | shopify/shopify | no |
| `ecsplorer` | masaushi/tap | no |
| `msodbcsql17` | microsoft/mssql-release | no |

Four are live on your PATH right now (`goku`, `stripe`, `shopify`,
`ecsplorer`).

Three move to nixpkgs directly. The other three need declaring on the
Homebrew side, which nix-darwin supports:

```nix
homebrew.taps = [
  "shopify/shopify"
  "masaushi/tap"
  "microsoft/mssql-release"
];
homebrew.brews = [ "themekit" "ecsplorer" "msodbcsql17" ];
```

Note `msodbcsql17` pairs with `unixODBC`, which **is** in nixpkgs. Worth
checking whether the brew formula is still needed once unixODBC comes
from Nix.

**Resolved.** Four vestigial taps removed: `candid82/brew` (was `joker`),
`homebrew/services`, `stripe/stripe-cli`, and `yqrashawn/goku` (the last two
because this migration moved their formulae into nixpkgs). `homebrew/core`
and `homebrew/cask` stay: they are the default taps supplying the 13 casks,
and appear to supply "nothing" only because default-tap packages are not
listed with a tap prefix. `nikitabobko/tap` (AeroSpace) also supplies
nothing and is a candidate for removal, left in place pending a decision.

### 7. `~/.local/bin` tools

```
claude  devon_agent  q  qterm  uv  uvx  bash/fish/nu/zsh (qterm shims)
```

Each installed by its own installer, none declared. `uv` **is** in
nixpkgs and is the easy win. Claude Code and Amazon Q manage their own
updates and are probably better left alone, but they should at least be
named in the README bootstrap so a fresh machine gets them.

---

## Tier 3: all complete

The four sub-projects from the original decomposition:

- ~~**home-manager, retiring dotbot.**~~ **Done.** 13 imperative symlinks
  became 9 home-manager links plus 4 `programs.*` modules (zsh, git,
  starship, alacritty). `./install` and both dotbot submodules are gone.
  `themes/tomorrow-theme` was removed afterwards as unreferenced, so the
  repo now has no submodules and no `.gitmodules` at all.
- ~~**tmux declarative.**~~ **Done.** `programs.tmux` with 4 plugins from
  nixpkgs. tpm, all plugin directories, and `tmux.conf` are gone; resurrect
  state moved to `~/.tmux/resurrect`, outside the repo. Only nvim remains.
- ~~**nvim declarative.**~~ **Done.** Cut from a 33-plugin IDE to a 9-plugin
  terminal editor: no LSP, no formatters, no mason, no lazy.nvim. Treesitter
  added with 16 grammars from nixpkgs.

---

## Deliberately not migrated

Worth writing down so nobody "fixes" these later:

- `~/.secrets`, sourced from `programs.zsh.initContent` in `nix/home/shell.nix`,
  correctly outside the repo
- `~/.ssh/config`, `~/.aws/config`, `~/.docker/config.json` — machine and
  credential specific
- `~/.zprofile` — untracked, bracketed by Amazon Q blocks that say to
  leave them at top and bottom
- The 289 non-terminal fonts in `~/Library/Fonts`

---

## Suggested order

1. Fonts and `goku` (Tier 1, one commit, immediately fixes a broken
   fresh install)
2. macOS defaults (Tier 2, self-contained, high daily impact)
3. Tap formulae and `uv` (Tier 2, closes the blind spot)
4. Hostname parameterisation plus README bootstrap (Tier 1, but only
   matters once there is a second machine)
5. home-manager (Tier 3, the large one)

Items 1 to 3 are small enough to do in a single session and would take
the fresh-machine result from "visibly broken" to "close enough to work
in".
