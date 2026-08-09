# tmux declarative (sub-project 3 of 4)

**Date:** 2026-08-09
**Status:** Approved, not yet implemented
**Repo:** `~/dotfiles`, branch `main`

## Goal

Convert `tmux.conf` to `programs.tmux`, split `nix/home.nix` into a directory
before it grows further, and retire tpm. Plus three small sweeps that have been
sitting in the reproducibility review.

## Context

home-manager is live and owns the dotfiles. `~/.tmux.conf` and `~/.tmux` are
out-of-store symlinks into the repo.

`tmux.conf` is 92 lines. It declares 5 tpm plugins, but only 4 do anything:
`tpm` itself disappears under Nix. Two more plugin directories sit on disk
undeclared (`tmux-fzf`, `vim-tmux-navigator`), doing nothing.

`vim-tmux-navigator` deserves a note: the plugin is installed but **not** in the
`@plugin` list. Its functionality is hand-rolled as a 20-line process-tree shell
snippet inside `tmux.conf`, with a custom `C-d` binding the plugin has no
equivalent for. The inline version is what actually runs.

## Decisions

**Split `nix/home.nix` into `nix/home/` first, as its own commit.** The file is
351 lines across five sections. tmux adds ~60 and nvim (next sub-project) adds
more. The home-manager spec said splitting would be justified "by real bulk, not
before"; that point has arrived, and doing it now means nvim lands into a
structure rather than creating one.

**`zsh` and `starship` share `shell.nix`.** They are genuinely coupled:
`programs.starship.enableZshIntegration` only functions because `programs.zsh`
owns `.zshrc`.

**Typed options where they exist, `extraConfig` verbatim for the rest.**
Type-checking where it is free, zero risk where it is not.

**`sensibleOnTop = false`.** home-manager defaults this to `true`, so leaving it
unset means silently opting in. `tmux-sensible` would add `focus-events`,
`aggressive-resize`, `status-keys emacs`, `display-time`, `status-interval`,
`C-p`/`C-n` window bindings, and `default-command` wrapping every pane in
`reattach-to-user-namespace`. Settings already declared survive (sensible is
prepended), but the additions are real. Keeping it off makes this a pure
conversion, which is what makes it verifiable.

**`customPaneNavigationAndResize = true`.** It reproduces the existing
`H/J/K/L` resize bindings exactly with `resizeAmount = 5`, and additionally
binds `prefix + h/j/k/l` for pane selection. Those four keys are unbound today,
so the addition is purely additive. Accepted deliberately.

**Drop the `~/.tmux` link; relocate resurrect state.** Runtime state moves out
of the repo into a real `~/.tmux/resurrect`.

**Drop `tmux-fzf`.** Never declared, never loaded. Adopting it would be
introducing a new tool mid-migration.

**Drop `z-lua` entirely.** See the sweep section.

## Architecture

```
nix/
  configuration.nix        users.jose = import ./home   (was ./home.nix)
  home/
    default.nix            link helper, home.file, xdg.configFile, imports
    git.nix                programs.git
    shell.nix              programs.zsh + programs.starship
    alacritty.nix          programs.alacritty
    tmux.nix               programs.tmux                 NEW
  packages.nix
  verify.sh
```

The `link` helper stays in `default.nix`; only the link table uses it.

`import ./home` resolves to `default.nix` by Nix convention.

### Commit 1: pure move

`nix/home.nix` becomes `nix/home/default.nix`, with `git.nix`, `shell.nix`, and
`alacritty.nix` split out and imported. No content changes.

**Acceptance test: the built store path must be byte-identical to the running
system.** A pure file move that changes the derivation is not a pure file move.
This must be verified before tmux is layered on, or a later failure cannot be
attributed.

### Commit 2: tmux

## The conversion

### Typed options

```nix
programs.tmux = {
  enable = true;
  sensibleOnTop = false;
  prefix = "C-a";
  keyMode = "vi";
  mouse = true;
  historyLimit = 4096;
  escapeTime = 10;
  terminal = "tmux-256color";
  shell = "/bin/zsh";
  resizeAmount = 5;
  customPaneNavigationAndResize = true;
  plugins = with pkgs.tmuxPlugins; [ resurrect continuum copycat yank ];
};
```

`prefix = "C-a"` replaces three lines: `set -g prefix C-a`, `unbind-key C-b`,
and `bind-key C-a send-prefix`.

`historyLimit` must be set: the option defaults to 2000, not 4096.

`escapeTime = 10` is written explicitly even though it matches the module
default, because the value is deliberate and a future default change should not
silently alter it.

Options deliberately left at their defaults, all verified to be `false` or
otherwise inert on darwin: `focusEvents`, `aggressiveResize`, `baseIndex`,
`disableConfirmationPrompt`, `newSession`, `reverseSplit`, and `secureSocket`
(which defaults to `pkgs.stdenv.isLinux`).

### extraConfig, verbatim

Everything with no typed equivalent:

- The four `@continuum-*` / `@resurrect-*` plugin options
- `renumber-windows`, `allow-rename off`, `allow-passthrough`,
  `extended-keys`, `terminal-features` for Alacritty RGB
- Bindings: `s` synchronize-panes, `c` new-window, `r` reload, `|` and `-`
  splits, `v` and `o` layouts
- The 20-line `is_vim` vim-navigator snippet and its `C-d`/`C-h`/`C-j`/`C-k`/
  `C-l`/`C-\` bindings, including the tmux-version conditional
- `if-shell ... source ~/dotfiles/tmux/tmuxline`
- Both Claude Code hooks: the `alert-bell` notification and the
  `session-window-changed` marker clear

### Deleted

- The five `set -g @plugin` lines
- `run -b '~/.tmux/plugins/tpm/tpm'`

Nix supplies the plugins; tpm has no role.

## Cutover

**The shadowing trap.** tmux reads `~/.tmux.conf` **before**
`$XDG_CONFIG_HOME/tmux/tmux.conf`, per `man tmux`. `programs.tmux` writes the
latter. If `~/.tmux.conf` survives, the generated config never loads.

Unlike the `~/.gitconfig` case in sub-project 2, home-manager owns
`~/.tmux.conf` here, so removing the `home.file` entry deletes it during
activation. No manual `rm` needed.

1. Remove `".tmux.conf"` and `".tmux"` from `home.file` in
   `nix/home/default.nix`
2. Add `nix/home/tmux.nix`, import it from `default.nix`
3. Build, then activate
4. Move resurrect state out of the repo, before starting a new tmux server:
   ```sh
   mkdir -p ~/.tmux
   mv ~/dotfiles/tmux/resurrect ~/.tmux/resurrect
   ```
   327 files, 1.4 MB. `@continuum-restore 'on'` means this state is live, and
   `@continuum-boot 'on'` auto-starts tmux with Alacritty at login.
   `tmux-resurrect` defaults to `$HOME/.tmux/resurrect`
   (`scripts/helpers.sh:1`), so no `@resurrect-dir` override is needed.
5. Delete `tmux/plugins/` (5.4 MB of dead tpm installs)
6. Remove `tmux/plugins/*` and `tmux/resurrect` from `.gitignore`
7. `git rm tmux.conf`

`tmux/tmuxline` and `tmux/.gitkeep` stay tracked. The tmuxline `source` line
uses an absolute `~/dotfiles/...` path, so it survives `~/.tmux` disappearing.

**A running tmux server keeps its old config until killed.** That is a safety
property here: a bad generated config cannot lock you out mid-migration.

## The sweep

Three items carried from `docs/nix-reproducibility-review.md`.

**Drop `z-lua`.** Its shell integration was commented out in the old `zshrc` and
never re-enabled, so `z` is not a working directory jumper and the `zz`, `zi`,
`zf`, `zb` aliases have been dead. Remove all four from
`programs.zsh.shellAliases` and `z-lua` from `nix/packages.nix`. Four aliases
that silently do nothing cost more than they save.

**Untap two vestigial taps.** `candid82/brew` (was for `joker`, now from
nixpkgs) and `homebrew/services` both supply zero installed formulae:

```sh
brew untap candid82/brew homebrew/services
```

Neither is declared in `homebrew.taps`, so nothing recreates them.

**Leave `~/.local/bin` alone.** `claude`, `q`, and `devon_agent` are
installer-managed and self-updating. Declaring them would fight their updaters.
Recorded in the review doc as deliberate.

## Verification

- `~/.tmux.conf` and `~/.tmux` are gone
- `~/.config/tmux/tmux.conf` exists and is a symlink into `/nix/store`
- A **fresh** server loads it. `tmux kill-server`, then `tmux new -d`, then:
  - `tmux show-options -g prefix` returns `C-a`
  - `tmux show-options -g history-limit` returns `4096`
  - `tmux show-window-options -g mode-keys` returns `vi`
  - `tmux show-options -g default-terminal` returns `tmux-256color`
- Plugin paths resolve into `/nix/store`, not `~/.tmux/plugins`
- Bindings work: `prefix + |` splits, `prefix + H` resizes by 5, `prefix + h`
  selects the pane left, `C-h` does vim-aware switching
- `ls ~/.tmux/resurrect | wc -l` returns 327
- `nix/verify.sh all` passes, and `tmux` still resolves from Nix
- A clean login shell starts silent, and `zz` is no longer defined

## Done

- `tmux.conf` removed from the repo; `nix/home/tmux.nix` is the source of truth
- `nix/home.nix` replaced by `nix/home/` with five modules
- tpm and all six plugin directories gone from the repo
- resurrect state lives in `~/.tmux/resurrect`, outside the repo
- `z-lua` and its four dead aliases removed
- Two vestigial taps removed
- `docs/nix-reproducibility-review.md` updated: tmux marked done

## Out of scope

- `programs.neovim` (sub-project 4)
- Adopting `tmux-fzf`
- Replacing the inline vim-navigator with the plugin, which would lose the
  custom `C-d` binding
- `~/.local/bin` installer-managed tools
- `tmux/tmuxline`, which stays a sourced file rather than becoming Nix
