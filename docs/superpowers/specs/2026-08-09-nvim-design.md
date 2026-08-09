# nvim declarative (sub-project 4 of 4)

**Date:** 2026-08-09
**Status:** Approved, not yet implemented
**Repo:** `~/dotfiles`, branch `main`

## Goal

Convert nvim to `programs.neovim`, cut it from an IDE to a terminal editor, and
retire both lazy.nvim and mason.

## Context

nvim is `$EDITOR` and `vim` is aliased to it, so its most common job is git
commit messages, config edits, and quick reads. It is explicitly **not** the
daily coding environment.

The current config does not reflect that. It is a PHP/Laravel and Vue IDE: 33
plugins, 9 LSP servers, 15 mason packages, 9 formatter types, across 643 lines
of Lua in 21 files.

An earlier count of "46 Lua files" was wrong. It included `nvim/.undo/`, whose
undo-history filenames contain `.lua`. The real config is 21 files.

### Defects already catalogued

`docs/dotfiles-review.md` recorded these in May, and they are still present:

- LSP completion broken: `cmp.lua` never registers the `nvim_lsp` source, and
  `lspconfig/init.lua` never passes `cmp_nvim_lsp.default_capabilities()`
- No treesitter
- Deprecated APIs: `vim.loop`, `vim.highlight.on_yank`, mason-lspconfig 1.x
  `automatic_installation`, lspconfig 0.11 style
- `conform` runs `pint`, a PHP formatter, on JSON
- `clipboard = 'unnamed'` should be `unnamedplus` on macOS
- `nvim-lspconfig` declared twice

### Defects found during this design

- **Four configured formatters were never installed.** `conform` references
  `stylua`, `isort`, `black`, and `prettierd`/`prettier`; none appear in
  mason's package list. Lua, Python, and JavaScript formatting silently do
  nothing.
- **Telescope's own keymaps are in its `keys` block.** The ten mappings in
  `keymaps.lua` are all commented out, so the live bindings come from
  `plugins/telescope.lua`.

Cutting to a terminal editor deletes every one of these rather than porting
them.

## Decisions

**Role: terminal editor.** No LSP, no formatters, no mason. This is the
decision every other one follows from.

**Nine plugins, down from 33.**

**Drop the nvim-cmp stack entirely** (6 plugins: `nvim-cmp`, `cmp-buffer`,
`cmp-cmdline`, `cmp-path`, `cmp_luasnip`, `LuaSnip`). Without LSP it would
complete only from buffer, path, and cmdline, which Neovim's built-in
`Ctrl-N` / `Ctrl-X Ctrl-F` already do with no config.

**Add treesitter** with a fixed grammar set from nixpkgs. It was the largest
gap, and syntax quality is most of what a reading-and-light-editing tool is
for.

**Lua stays in real `.lua` files, read in by Nix** via `builtins.readFile`.
Inlining ~200 lines of Lua into a Nix indented string would lose syntax
highlighting and `lua_ls` for no gain. The cost is that Lua edits need a
rebuild, which is acceptable precisely because this config is not iterated on.

**`~/.config/nvim` stops being a symlink.** `programs.neovim` generates it.
Keeping a linked directory beside a generated `init.lua` is the same shape as
the `~/.gitconfig` shadowing bug from sub-project 2.

**`lazy-lock.json` is deleted.** Nix pins plugin versions through
`flake.lock`; plugin updates happen via `nix flake update`.

## Architecture

```
nix/home/nvim.nix     plugins, grammars, extraLuaConfig = builtins.readFile ../../nvim/init.lua
nvim/init.lua         ~200 lines, trimmed from 643
```

Everything else under `nvim/` is deleted: `lua/js/` in full, `after/`,
`lazy-lock.json`.

`nvim/.undo/` is gitignored undo history and is left alone.

### programs.neovim

```nix
programs.neovim = {
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;

  plugins = with pkgs.vimPlugins; [
    gruvbox-nvim
    (nvim-treesitter.withPlugins (g: with g; [
      lua nix bash json yaml toml php vim vimdoc query
      markdown markdown_inline
      gitcommit git_rebase diff
      clojure
    ]))
    telescope-nvim
    plenary-nvim
    telescope-fzf-native-nvim
    vim-surround
    vim-commentary
    vim-tmux-navigator
    guess-indent-nvim
  ];

  extraLuaConfig = builtins.readFile ../../nvim/init.lua;
};
```

`defaultEditor`, `viAlias`, and `vimAlias` replace `EDITOR = "nvim"` in
`programs.zsh.sessionVariables` and `vim = "nvim"` in `shellAliases`. Both must
be removed from `nix/home/shell.nix` to avoid two sources of truth.

### Grammar selection

Chosen for what this editor actually opens, which is not what an IDE would
need:

| Grammars | Why |
|---|---|
| `gitcommit`, `git_rebase`, `diff` | nvim is `$EDITOR`; this is its most frequent job |
| `nix`, `lua`, `bash`, `toml`, `yaml`, `json`, `markdown`, `markdown_inline` | the dotfiles repo itself |
| `clojure` | `karabiner/karabiner.edn`; goku's config is EDN |
| `php` | the one work language likely to be opened for a quick read |
| `vim`, `vimdoc`, `query` | help files and treesitter queries |

Deliberately excluded: JavaScript, TypeScript, Vue, HTML, CSS, SQL. That is
IDE territory.

All 16 verified present in `pkgs.vimPlugins.nvim-treesitter.grammarPlugins`.
Nothing compiles at runtime; `:TSInstall` is never needed.

## What survives from the 643 lines

### options.lua, all of it

One change: `clipboard = 'unnamed'` becomes `'unnamedplus'`. On macOS
`unnamed` maps to the `*` register; `unnamedplus` maps to `+`, which is what
reliably syncs with the system clipboard.

### keymaps.lua, minus 10 mappings and the console-log helpers

Dropped because their plugin is gone:

| Mapping | Plugin |
|---|---|
| `<Leader>g`, `<Leader>gp` | vim-fugitive |
| `gD`, `gd`, `K`, `gi`, `<leader>ld`, `<leader>q` | LSP |
| `<leader>o` | maximize.nvim |
| `<leader>e` | nvim-tree |

Also dropped by decision: the PHP and JavaScript console-log helpers (visual
`L`), 12 lines. They are a coding feature, not an editing one.

Everything else carries verbatim: leader as space, `jj` escape in insert and
cmdline, `<Leader><space>` clear search, visual `J`/`K` line moves, `Y` and `D`
to end of line, `<Leader>bn`/`bp`/`bd` buffer navigation, `;;` and `,,`,
`<Leader>vs`/`<Leader>sp` splits, `gj`/`gk` wrapped-line movement,
`<Leader>h` cursorline toggle, `<Leader>v` cursorcolumn, and both
`<Leader>ci` Commentary mappings.

### Telescope keymaps, 11 of 13

They live in the plugin's `keys` block. Two are LSP pickers
(`<Leader>s` `lsp_document_methods`, `<Leader>S` `lsp_document_symbols`) and
are dropped. `<Leader>fg` used the `live_grep_args` extension, which is not in
the nine; it becomes `builtin.live_grep`.

Surviving: `<Leader>ff` git_files, `<Leader>fa` find_files, `<Leader>fb`
buffers, `<Leader>fh` oldfiles, `<Leader>l` current_buffer_fuzzy_find,
`<Leader>C` commands, `<Leader>:` command_history, `<Leader>R` pickers,
`<Leader><Leader>f` filetypes, `<Leader><Leader>t` builtin, plus `<Leader>fg`
in its adapted form.

Because there is no lazy.nvim, these move from a `keys` block into ordinary
`vim.keymap.set` calls.

### disable.lua, minus three lines

It disables built-in plugins for faster startup. The gzip, zip, tar, vimball,
getscript, 2html, logiPat, and rrhelper disables stay.

**The three `loaded_netrw*` lines must be removed.** Dropping `nvim-tree`
makes netrw the only file browser again, and leaving it disabled means `:Ex`
silently does nothing.

### globals.lua, deleted

61 lines of TJ Devries' `P` / `RELOAD` / `R` helpers for developing nvim
config. Not applicable to a config that is generated and read-only.

### init.lua, replaced

The current file is lazy.nvim bootstrap, including a `vim.loop` call the review
flagged as deprecated. Nix replaces all of it. The new `nvim/init.lua` is the
merged, trimmed content of `options.lua`, `keymaps.lua`, `disable.lua`, and the
small setup calls for treesitter, telescope, gruvbox, and guess-indent.

## Cutover

1. Create `nix/home/nvim.nix`, import it from `nix/home/default.nix`
2. Write the trimmed `nvim/init.lua`
3. Remove `"nvim"` from `xdg.configFile` in `nix/home/default.nix`
4. Remove `EDITOR` from `sessionVariables` and `vim = "nvim"` from
   `shellAliases` in `nix/home/shell.nix`
5. Build, activate
6. Delete `nvim/lua/`, `nvim/after/`, `nvim/lazy-lock.json`
7. Remove `z.lua`-style stale entries: none apply here, but confirm
   `nix/verify.sh` still passes with `nvim` resolving from Nix

`~/.config/nvim` is currently an out-of-store symlink owned by home-manager.
Removing the `xdg.configFile` entry deletes it during activation, the same way
`~/.tmux.conf` was handled in sub-project 3. No manual `rm` needed.

Mason's runtime downloads at `~/.local/share/nvim/mason/` become orphaned. They
are outside the repo and can be deleted separately; 15 packages.

## Verification

- `~/.config/nvim` is generated, not a symlink into `~/dotfiles`
- `nvim --headless +qa` exits silently, no errors
- `nvim --headless "+lua print(#vim.api.nvim_list_runtime_paths())" +qa` shows
  the plugins on the runtime path
- Treesitter highlights: open a `.nix` file and confirm
  `:TSModuleInfo` or `:lua print(vim.treesitter.language.get_lang('nix'))`
  resolves
- Telescope opens: `nvim --headless "+lua require('telescope')" +qa` exits 0
- `<Leader>ff` and `<Leader>fa` work interactively
- `C-h`/`C-j`/`C-k`/`C-l` still switch tmux panes from inside nvim, proving
  `vim-tmux-navigator` is wired
- `git commit` opens nvim with `gitcommit` highlighting
- `:Ex` opens netrw, proving the disable lines were correctly trimmed
- `nix/verify.sh all` passes
- A clean login shell still has `EDITOR=nvim` and `vim` aliased, now from
  `programs.neovim` rather than hand-written settings

## Done

- `nvim/` contains only `init.lua` (~200 lines) and gitignored `.undo/`
- `lua/js/`, `after/`, `lazy-lock.json` deleted
- 33 plugins become 9; 15 mason packages become 0
- No LSP, no formatters, no mason, no lazy.nvim
- `EDITOR` and the `vim` alias come from `programs.neovim`
- `docs/nix-reproducibility-review.md` updated: all four sub-projects done

## Out of scope

- Restoring LSP for any language. If wanted later, add servers from nixpkgs
  and wire `vim.lsp.config()`; do not reintroduce mason.
- Deleting `~/.local/share/nvim/mason/`, which is outside the repo
- `nvim/.undo/`, which is gitignored undo history
- The remaining `docs/dotfiles-review.md` findings for Hammerspoon and
  Karabiner
