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
claude  devon_agent  uv  uvx
```

Each installed by its own installer, none declared.

**Partly resolved.** `uv` and `uvx` now come from nixpkgs and resolve from
`/run/current-system/sw/bin`, because `~/.local/bin` is appended to `PATH`
rather than prepended. The copies still sitting here are dead weight,
44 MB, and can go.

All Amazon Q traces were removed on 2026-08-09: the app itself was already
uninstalled, leaving 304 MB of orphaned `qterm` shims, two broken symlinks
(`q`, `qterm`), a LaunchAgent still loaded at every login trying to exec a
deleted binary, and no-op source blocks in `~/.zprofile`, `~/.bash_profile`,
and `~/.bashrc`.

`claude` is Claude Code, which manages its own updates and is better left
alone, but it should be named in the README bootstrap so a fresh machine
gets it. `devon_agent` is a pipx venv and may well be abandoned.

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
- `~/.ssh/config`, `~/.aws/config`, `~/.docker/config.json`: machine and
  credential specific
- `~/.zprofile`, untracked, written by the Homebrew installer. Since the
  Amazon Q blocks were removed on 2026-08-09 it holds one line,
  `eval "$(/opt/homebrew/bin/brew shellenv)"`. That is the only reason
  `/opt/homebrew/bin` is on `PATH` at all, so it cannot simply be deleted.
  A candidate for `programs.zsh.profileExtra`, which would make it
  declarative and remove the last untracked shell startup file.
- The 289 non-terminal fonts in `~/Library/Fonts`

---

## Known issues, not yet fixed

Carried over from a May 2026 review of the pre-Nix repo. Everything that
review found in `zsh/zshrc`, `nvim/lua/js/`, `install`, `install.conf.yaml`,
and `tmux.conf` is moot, because the migration deleted those files. What
follows is the remainder, each re-verified against the current tree on
2026-08-09.

### Real bugs

- **Hammerspoon hotkeys silently do nothing.** `hammerspoon/init.lua:666,673`
  pass `{ 'cmd, shift' }`, a single string, where `hs.eventtap.keyStroke`
  expects `{ 'cmd', 'shift' }`. Neither modifier is applied. Lines `750,771`
  pass `{ '' }` where an empty `{}` is meant.
- **Amethyst binds `mod1+t` twice**, to `toggle-float` (`amethyst.yml:239`)
  and `toggle-tiling` (`:249`). Last parsed wins; the other is dead.
- **`select-bsp-layout` is bound** (`amethyst.yml:224`) but `bsp` is not in
  the active `layouts` list, so the binding does nothing.

### Cleanup

- `hammerspoon/experimental.lua` is entirely commented-out dead code.
- `karabiner/karabiner.edn.bak` is a stale backup.
- `raycast-scripts/` is empty.
- `hammerspoon/init.lua:137,143` reference React Native Debugger and Paw;
  Paw has been EOL since 2022.

### Fragile, works today

- Globals leaking to `_G` in `hammerspoon/init.lua`: `positions` (434),
  `lrsplits`/`tbsplits` (473, 474), `currentLayout`/`layouts` (570, 572),
  `bundleId` (683), plus all 16 functions in `helpers.lua`.
- `hammerspoon/chain.lua:30` reads `lastSeenAt` before it is assigned at
  `:39`. Works only because Lua returns nil for undeclared globals.
- `zsh/custom/functions.zsh:8` `openpr()` rewrites git remotes to `http://`
  rather than `https://`.
- `programs.git` sets no commit signing.

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
