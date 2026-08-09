# home-manager migration (sub-project 2 of 4)

**Date:** 2026-08-09
**Status:** Approved, not yet implemented
**Repo:** `~/dotfiles`, branch `main`

## Goal

Introduce home-manager as a nix-darwin module, move all dotbot symlinks under
it, convert three small configs to typed Nix options, and retire dotbot.

## Context

Sub-project 1 is complete: packages, casks, fonts, macOS defaults, and host
parameterisation are all declarative. dotbot remains the last imperative step
on a new machine, and `README.md` still lists `./install` as required.

dotbot manages 13 symlinks via `install.conf.yaml`, plus two git submodules
(`dotbot`, `dotbot-pip`).

## Which layer owns what

Recorded because it is the question this sub-project keeps raising.

| Layer | Scope | Writes to | Example |
|---|---|---|---|
| flake | package universe and versions | nothing | `inputs.nixpkgs.url` |
| nix-darwin | the machine, needs sudo, all users | `/etc`, `/Library`, `/run/current-system` | `fonts.packages`, `system.defaults.dock` |
| home-manager | one user's home directory | `~/` | `home.file.".zshrc"`, `programs.git` |

Test: if it needs sudo or another user would want it, nix-darwin. If it is a
file in `$HOME`, home-manager.

Packages are the blurry case. They stay in `environment.systemPackages`
rather than moving to `home.packages`. On a single-user Mac the distinction
buys nothing, and moving 50+ packages is churn with real risk and no
reproducibility gain.

## Decisions

**Hybrid depth.** Convert `git`, `starship`, and `alacritty` to `programs.*`
modules (96 lines total, all mechanical). Everything else stays a file link.
Notably `zsh` is **not** converted: `programs.zsh` would mean rewriting 460
lines of handwritten zsh, and it is the highest-risk file on the machine
since a mistake breaks every new shell.

**Out-of-store symlinks throughout.** `config.lib.file.mkOutOfStoreSymlink`
pointing at `~/dotfiles/<path>`. Editing `zshrc` takes effect in the next
shell with no rebuild, exactly as today. The cost is that a home-manager
rollback restores which files are linked but not their contents. Content
rollback is git's job.

**home-manager as a nix-darwin module,** not standalone, wired inside
`mkHost` so a second machine inherits it automatically.

**dotbot stays in the repo until the links are verified working.** It is the
rollback path for steps 1 to 3.

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

13 dotbot links become 10 home-manager links. Three disappear because they
become generated configs.

```nix
home.file = {
  ".zshrc".source        = link "zsh/zshrc";
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

Dropped, now generated: `~/.gitconfig`, `~/.config/starship.toml`,
`~/.config/alacritty/alacritty.toml`.

**`xdg.enable = true` is required.** On Linux XDG is implied; on darwin
home-manager leaves it off by default and the three `xdg.configFile` entries
would silently do nothing.

**Three paths receive runtime writes** and must be out-of-store symlinks:
`~/.tmux` (tpm plugins), `~/.config/nvim` (`lazy-lock.json`), `~/.hammerspoon`
(`Spoons/`). A store symlink would make these read-only and break the tools.

**`~/.tmux` and `~/.config/nvim` stay links, not `programs.tmux` /
`programs.neovim`.** Those are sub-projects 3 and 4. This sub-project changes
who does the linking, not how tmux or nvim behave.

**`karabiner.edn` is linked twice** from one source, to `~/.config/karabiner.edn`
and `~/.config/karabiner/karabiner.edn`. That is what dotbot does today and it
is preserved deliberately: goku's search path is the reason, and getting it
wrong is a keyboard outage.

## The three conversions

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

### programs.alacritty

The current `alacritty.toml` imports a theme:

```toml
import = [ "~/dotfiles/alacritty/alacritty-theme/themes/seashells.toml" ]
```

`alacritty/alacritty-theme/` is a clone of
`github.com/alacritty/alacritty-theme`, listed in `.gitignore` and **not a
submodule**. On a new machine it does not exist and the import fails.

The fix is to inline the 37 lines of seashells colors into
`programs.alacritty.settings`. After that the clone and its `.gitignore` entry
are both deleted.

Font settings carry over unchanged, including `family = "FiraCode Nerd Font
Mono"`, which is already declared in `nix/configuration.nix`.

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

The same care applies to `format.pretty` in the git config, which is a long
string of `%C(...)` colour codes.

All three conversions are mechanical, so the risk is transcription error, not
design. The plan verifies by diffing generated output against the current
files byte for byte rather than trusting the translation.

## Cutover

All ten target paths currently hold dotbot symlinks, and home-manager refuses
to clobber files it does not own. `backupFileExtension = "hm-bak"` makes it
move each aside instead of failing activation.

1. Add the home-manager input and wiring. dotbot untouched.
2. Activate. HM takes the ten paths, backing up dotbot's links.
3. Verify links, then verify behaviour.
4. Delete `install.conf.yaml`, `install`, and the `dotbot` and `dotbot-pip`
   submodules.
5. Delete the `.hm-bak` files and `alacritty/alacritty-theme`.

Steps 1 to 3 are reversible with `darwin-rebuild --rollback` followed by
`./install`, because dotbot is still present. After step 4, recovery is a
`git revert`.

`themes/tomorrow-theme` is unrelated to dotbot and stays.

## Verification

A `links` batch in `verify.sh` asserting each of the ten paths is a symlink
resolving under `~/dotfiles`. It catches the two failures that matter:

- A link pointing into `/nix/store`, meaning `mkOutOfStoreSymlink` was missed
  and the file is now read-only
- A link that was silently never created because `xdg.enable` was off

Behavioural checks a link table cannot prove:

- A new login shell starts with no errors
- `tmux` starts and tpm plugins load
- `nvim` starts with no lazy.nvim errors
- `git config --get user.email` returns the expected value from the generated
  config

## Done

- `brew`-free, dotbot-free new machine setup: clone, `darwin-rebuild switch`,
  done
- `install.conf.yaml`, `install`, `dotbot/`, `dotbot-pip/` removed
- `.gitmodules` contains only `themes/tomorrow-theme`
- `alacritty/alacritty-theme` removed along with its `.gitignore` entry
- `~/.gitignore_global` no longer referenced
- `README.md` step 4 (`./install`) removed
- `verify.sh links` passes and all behavioural checks pass

## Out of scope

- `programs.tmux` (sub-project 3) and `programs.neovim` (sub-project 4)
- Converting `zsh` to `programs.zsh`
- Moving packages from `environment.systemPackages` to `home.packages`
- `themes/tomorrow-theme`
- `~/.secrets`, `~/.ssh/config`, `~/.zprofile`, which stay unmanaged by design
