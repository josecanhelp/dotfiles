# home-manager migration (sub-project 2 of 4)

**Date:** 2026-08-09
**Status:** Approved, not yet implemented
**Repo:** `~/dotfiles`, branch `main`

## Goal

Introduce home-manager as a nix-darwin module, convert every config that has a
`programs.*` module, link the rest, and retire dotbot.

## Context

Sub-project 1 is complete: packages, casks, fonts, macOS defaults, and host
parameterisation are declarative. dotbot is the last imperative step on a new
machine, and `README.md` still lists `./install` as required.

dotbot manages 13 symlinks via `install.conf.yaml`, plus two git submodules
(`dotbot`, `dotbot-pip`).

## Which layer owns what

Recorded because it is the question this sub-project keeps raising.

| Layer | Scope | Writes to | Example |
|---|---|---|---|
| flake | package universe and versions | nothing | `inputs.nixpkgs.url` |
| nix-darwin | the machine, needs sudo, all users | `/etc`, `/Library`, `/run/current-system` | `fonts.packages`, `system.defaults.dock` |
| home-manager | one user's home directory | `~/` | `home.file`, `programs.git` |

Test: if it needs sudo or another user would want it, nix-darwin. If it is a
file in `$HOME`, home-manager.

Packages are the blurry case. They stay in `environment.systemPackages` rather
than moving to `home.packages`. On a single-user Mac the distinction buys
nothing, and moving 50+ packages is churn with real risk and no reproducibility
gain.

## Decisions

**Full conversion, not hybrid.** Everything with a `programs.*` module gets
one: `git`, `zsh`, `starship`, `alacritty`. An earlier draft left zsh alone;
that was rejected because it produces a half-state. `programs.starship`'s
`enableZshIntegration` works by appending to the `.zshrc` that home-manager
owns. If home-manager does not own it, the option silently does nothing and
the `eval "$(starship init zsh)"` line has to stay hand-written. Same for fzf
and zoxide. Converting zsh is what makes the other modules real.

**Out-of-store symlinks for everything that stays a file.**
`config.lib.file.mkOutOfStoreSymlink` pointing at `~/dotfiles/<path>`. Edits
take effect immediately with no rebuild.

**`~/.zshrc` is the deliberate exception.** Because `programs.zsh` generates
it, it lives in the store and is read-only. Changing an alias or a `setopt`
requires `darwin-rebuild switch`. This is accepted knowingly. Shell functions
stay in files sourced out-of-store, so the 216 lines most likely to be
iterated on remain instantly editable.

**home-manager as a nix-darwin module,** wired inside `mkHost` so a second
machine inherits it.

**dotbot stays in the repo until the links are verified.** It is the rollback
path.

## Architecture

```
~/dotfiles/
  flake.nix                 + home-manager input, + darwinModules.home-manager
  nix/
    configuration.nix       + home-manager wiring
    home.nix                NEW
    packages.nix            unchanged
    verify.sh               + links batch
```

`home-manager` is pinned to `release-26.05`, matching nixpkgs and nix-darwin.

Wiring in `configuration.nix`:

```nix
home-manager.useGlobalPkgs = true;
home-manager.useUserPackages = true;
home-manager.backupFileExtension = "hm-bak";
home-manager.users.jose = import ./home.nix;
```

`useGlobalPkgs` prevents home-manager instantiating a second nixpkgs, which
would double evaluation time and risk version skew against `packages.nix`.

`home.nix` opens with a link helper so the table stays scannable:

```nix
{ config, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  # link table and programs.* blocks, both below
}
```

A single `nix/home.nix` rather than a `nix/home/` directory. When sub-projects
3 and 4 add `programs.tmux` and `programs.neovim`, splitting will be justified
by real bulk. Not before.

## The link table

13 dotbot links become **9** home-manager links. Four disappear because they
become generated configs.

```nix
home.file = {
  ".tmux.conf".source    = link "tmux.conf";
  ".tmux".source         = link "tmux";
  ".hammerspoon".source  = link "hammerspoon";
  ".amethyst.yml".source = link "amethyst/amethyst.yml";
  ".hushlogin".source    = link "hushlogin";
  ".bin".source          = link "bin";
};

xdg.enable = true;

xdg.configFile = {
  "nvim".source                    = link "nvim";
  "karabiner.edn".source           = link "karabiner/karabiner.edn";
  "karabiner/karabiner.edn".source = link "karabiner/karabiner.edn";
};
```

Now generated, no longer linked: `~/.zshrc`, `~/.gitconfig`,
`~/.config/starship.toml`, `~/.config/alacritty/alacritty.toml`.

**`xdg.enable = true` is required.** On Linux XDG is implied; on darwin
home-manager leaves it off by default and the three `xdg.configFile` entries
would silently do nothing.

**Three paths receive runtime writes** and must be out-of-store symlinks:
`~/.tmux` (tpm plugins), `~/.config/nvim` (`lazy-lock.json`), `~/.hammerspoon`
(`Spoons/`). A store symlink would make these read-only and break the tools.

**`~/.tmux` and `~/.config/nvim` stay links, not `programs.tmux` /
`programs.neovim`.** Those are sub-projects 3 and 4. This sub-project changes
who does the linking, not how tmux or nvim behave.

**`karabiner.edn` is linked twice** from one source, to
`~/.config/karabiner.edn` and `~/.config/karabiner/karabiner.edn`. That is what
dotbot does today and it is preserved deliberately: goku's search path is the
reason, and getting it wrong is a keyboard outage.

**`functions.zsh` is not linked at all.** The current `zshrc` sources it by
absolute path from `~/dotfiles/zsh/custom/`, and the generated one will do the
same. It never needed to be in `$HOME`.

**`artisan.plugin.zsh` is dead code and gets deleted.** A repo-wide search
finds no reference to it outside the file itself: nothing sources it, and
nothing ever did. Rather than wire it up (a behaviour change this migration has
no mandate for) or leave it lying around, Task 4 removes it. Decided
explicitly, not inherited.

**home-manager's zsh history defaults are adopted deliberately.** Enabling
`programs.zsh` raises `HISTSIZE`/`SAVEHIST` from 2000 to 10000 and adds
`HIST_IGNORE_SPACE` and `NO_APPEND_HISTORY` on top of the existing options.
This is a behaviour change the conversion introduces rather than preserves, and
it is accepted as an improvement rather than pinned back to the old values.

## The four conversions

### programs.zsh

Owns `~/.zshrc`. The conversion boundary:

| Current | Becomes |
|---|---|
| `aliases.zsh`, 84 pure `alias` lines | `programs.zsh.shellAliases`; file deleted |
| manual `source` of zsh-autosuggestions | `autosuggestion.enable = true` |
| manual `source` of zsh-syntax-highlighting | `syntaxHighlighting.enable = true` |
| manual `eval "$(starship init zsh)"` | `programs.starship.enableZshIntegration` |
| `HISTFILE`/`HISTSIZE`/`setopt` lines | `history`, `setOptions` |
| `bindkey` / keymap lines | `defaultKeymap`, plus `initContent` for the rest |
| `functions.zsh` | sourced from `initContent` by absolute path |
| everything else | `initContent` |

`aliases.zsh` is verified to contain 84 `alias` lines and **zero** other
statements, so the mapping is total rather than partial.

Two specifics:

- **`gsup` is dropped.** `alias gsup="git branch --set-upstream-to=origin/$(current_branch)"`
  relies on double-quote expansion at definition time. home-manager generates
  aliases through `lib.escapeShellArg`, which single-quotes, changing when the
  substitution happens. Rather than preserve a subtle behaviour difference,
  the alias is removed.
- **The uncommitted WIP is absorbed.** `zsh/custom/aliases.zsh` currently has
  an uncommitted edit commenting out `alias gs="git status"`. The conversion
  omits `gs` from `shellAliases`, carrying that intent forward deliberately
  rather than losing it when the file is deleted.

The zsh plugin packages currently in `nix/packages.nix`
(`zsh-autosuggestions`, `zsh-syntax-highlighting`) are removed from there,
because `programs.zsh` pulls them in itself. The
`environment.pathsToLink = [ "/share/zsh-syntax-highlighting" ]` workaround in
`configuration.nix` is removed with them, since home-manager references the
store path directly rather than going through the system profile.

### programs.git

Replaces the 30-line `gitconfig`.

```nix
programs.git = {
  enable = true;
  userName = "Jose Soto";
  userEmail = "josecanhelp@gmail.com";
  lfs.enable = true;
  ignores = [ ".DS_Store" ".vscode/*" ".secrets" "CLAUDE.md" "scratch*.md"
              "**/.claude/settings.local.json" ];
  extraConfig = {
    github.user = "josecanhelp";
    init.defaultBranch = "main";
    pull.rebase = false;
    color.ui = "auto";
    status.short = true;
    help.autocorrect = 1;
    core.editor = "vim";
    credential.helper = "osxkeychain";
    mergetool = { prompt = false; keepBackup = false; };
    format.pretty = "format:%Cblue%h%Creset %Creset%Cgreen%cn, %cr%Creset : %s%Creset%C(red)%d%Creset";
  };
};
```

`lfs.enable = true` generates the entire `[filter "lfs"]` block.

`ignores` writes `~/.config/git/ignore`, which git reads via XDG. This absorbs
`~/.gitignore_global`, a file that exists on disk, is referenced by
`core.excludesfile`, and is **not tracked in this repo**. It would be missing
on a new machine. `core.excludesfile` is therefore deleted rather than
repointed, which also removes a hardcoded `/Users/jose` path.

**The stale `~/.gitconfig` must be deleted for any of this to take effect.**
With `xdg.enable = true`, home-manager writes `~/.config/git/config`, not
`~/.gitconfig`. Git reads both and gives `~/.gitconfig` precedence on
overlapping keys. Since dotbot created `~/.gitconfig` as a symlink into this
repo, leaving it in place would make the generated config inert and quietly
reinstate `core.excludesfile`. Removing it from `install.conf.yaml` stops it
being recreated but does not delete the existing link; that is an explicit
step.

Starship and alacritty are unaffected: home-manager writes them to the same
paths dotbot used, so `backupFileExtension` moves the old links aside during
activation.

### programs.alacritty

The current config imports a theme from `alacritty/alacritty-theme/`, a clone
of `github.com/alacritty/alacritty-theme` that is listed in `.gitignore` and is
**not a submodule**. On a new machine it does not exist and the import fails.

nixpkgs packages the same theme collection, so the fix is to reference it:

```nix
programs.alacritty = {
  enable = true;
  package = null;        # Alacritty comes from the Homebrew cask
  settings.general.import = [
    "${pkgs.alacritty-theme}/share/alacritty-theme/seashells.toml"
  ];
};
```

Verified: that package contains 176 themes including `seashells.toml`. This
is versioned by the flake lock, switching themes is a one-word change, and
the clone plus its `.gitignore` entry are deleted.

Two module quirks make this the required shape:

`package = null` rather than `enable = false`: the module body is wrapped in
`lib.mkIf cfg.enable`, so disabling it writes no config at all. The `package`
option is declared nullable precisely for the case where the program is
installed by other means.

`settings.general.import` rather than the module's `theme` option: with
`package = null`, the `theme` code path evaluates `cfg.package.version`
without a null guard and fails with "expected a set but found null"
(`modules/programs/alacritty.nix:95`). This is an upstream bug, since
`package` is declared nullable but `theme` does not account for it. The
module's own documentation directs you to `settings.general.import` for
custom themes.

Font settings carry over unchanged, including
`family = "FiraCode Nerd Font Mono"`, already declared in
`nix/configuration.nix`.

### programs.starship

Direct translation of 32 lines of TOML into `settings`. Verified to contain no
imports or references to external files.

One transcription hazard. The python module's format string contains escaped
parentheses inside a single-quoted TOML string:

```toml
format = 'via [$symbol$version( \($virtualenv\))]($style) '
```

TOML single quotes are literal; Nix double quotes are not, and `\(` in a Nix
double-quoted string is an escape sequence. This must use a Nix indented
string (`''...''`) or have its backslashes doubled. Getting it wrong silently
changes the prompt rather than failing loudly.

The same care applies to `format.pretty` in the git config, a long string of
`%C(...)` colour codes.

All four conversions are mechanical, so the risk is transcription error, not
design. The plan verifies by diffing generated output against the current
files rather than trusting the translation.

## Cutover

All nine target paths currently hold dotbot symlinks, and home-manager refuses
to clobber files it does not own. `backupFileExtension = "hm-bak"` makes it
move each aside instead of failing activation.

1. Add the home-manager input and wiring, plus `home.nix`. dotbot untouched.
2. Activate. HM takes the nine paths and writes the four generated configs,
   backing up what dotbot left.
3. Verify links, diff generated configs against the originals, then verify
   behaviour.
4. Delete `install.conf.yaml`, `install`, and the `dotbot` and `dotbot-pip`
   submodules.
5. Delete the `.hm-bak` files, `alacritty/alacritty-theme`, `gitconfig`,
   `starship.toml`, `alacritty/alacritty.toml`, `zsh/zshrc`, and
   `zsh/custom/aliases.zsh`.

Steps 1 to 3 are reversible with `darwin-rebuild --rollback` followed by
`./install`, because dotbot is still present. After step 4, recovery is a
`git revert`.

`themes/tomorrow-theme` is unrelated to dotbot and stays.

## Verification

A `links` batch in `verify.sh` asserting each of the nine paths is a symlink
resolving under `~/dotfiles`. It catches the two failures that matter:

- A link pointing into `/nix/store`, meaning `mkOutOfStoreSymlink` was missed
  and the file is now read-only
- A link silently never created because `xdg.enable` was off

Generated-config checks, comparing against the pre-migration originals:

- `git config --get user.email`, `--get init.defaultBranch`, and
  `--get filter.lfs.clean` return the expected values
- `~/.config/starship.toml` matches the original semantically, with the python
  `format` string byte-identical
- `~/.config/alacritty/alacritty.toml` resolves its theme import to a
  `/nix/store` path that exists

Behavioural checks a config diff cannot prove:

- A new login shell starts with no errors
- The prompt renders, meaning starship initialised
- Autosuggestions and syntax highlighting are active
- A sample of aliases resolve (`gp`, `art`, `dot`)
- `tmux` starts and tpm plugins load
- `nvim` starts with no lazy.nvim errors

## Done

- New machine setup is clone plus `darwin-rebuild switch`, with no `./install`
- `install.conf.yaml`, `install`, `dotbot/`, `dotbot-pip/` removed
- `.gitmodules` contains only `themes/tomorrow-theme`
- `alacritty/alacritty-theme` removed along with its `.gitignore` entry
- `~/.gitignore_global` no longer referenced
- `zsh/zshrc` and `zsh/custom/aliases.zsh` removed; `functions.zsh` and
  `artisan.plugin.zsh` remain
- `README.md` step 4 (`./install`) removed
- `verify.sh links` passes and all behavioural checks pass

## Out of scope

- `programs.tmux` (sub-project 3) and `programs.neovim` (sub-project 4)
- Moving packages from `environment.systemPackages` to `home.packages`
- `themes/tomorrow-theme`
- `~/.secrets`, `~/.ssh/config`, `~/.zprofile`, which stay unmanaged by design
