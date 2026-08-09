# Dotfiles Review — 2026-05-07

Multi-agent review of `/Users/jose/dotfiles` (5 parallel reviewers + cross-cutting security pass).

## Decisions
- **Amethyst stays.** User still uses it; the recent "Remove Amethyst configs" commit is being reconsidered. `amethyst/amethyst.yml` is intentional.
- **Aerospace removed** (replaced by Hammerspoon window modal + Amethyst). No further action.

---

## Fixed in this pass

| # | Finding | File(s) |
|---|---------|---------|
| 1 | tmux losing 24-bit color & italics inside Alacritty (`default-terminal "screen-256color"`, no RGB feature) | `tmux.conf:16,21` |
| 2 | `.gitignore` references `bin/apache-maven-3.9.6/*`; actual dir is `3.9.9` (and 90 vendored jars/scripts were tracked) | `.gitignore:4`, `git rm --cached -r bin/apache-maven-3.9.9` |
| 3 | `.gitmodules` lists 5 stale submodules that don't exist on disk (`dotbot-pip`, `tmux/plugins/tmux-yank`, `themes/tomorrow-theme`, `themes/fonts`, `themes/powerline-fonts`) | `.gitmodules` |
| 4 | `.claude/` untracked but not gitignored — risk of accidentally committing local Claude settings | `.gitignore` |
| 5 | Alacritty bell + tmux alert-bell hook double-fire macOS notifications | `alacritty/alacritty.toml:32-33` (removed) — kept tmux hook |
| 6 | ~10 lines of brittle, version-pinned fzf path config (`/usr/local/opt/fzf/bin`, `0.61.1` Cellar paths) | `zsh/zshrc` — replaced with `eval "$(fzf --zsh)"` |

---

## Pending — left for later

### Bugs that silently break things
- **LSP completion broken in nvim** — `lua/js/plugins/cmp.lua:57-61` missing `{ name = 'nvim_lsp' }` source; `lspconfig/init.lua:20-22` doesn't pass `cmp_nvim_lsp.default_capabilities()`.
- **`zsh-syntax-highlighting` silently not loading** — `zsh/zshrc:153-156` sources from Intel `/usr/local/share/...` (suppressed by `2>/dev/null`); should be `/opt/homebrew/share/...`.
- **Hammerspoon hotkeys silently dropped** — `hammerspoon/init.lua:661,668` use `{ 'cmd, shift' }` (single string) instead of `{ 'cmd', 'shift' }`; lines `745, 766` use `{ '' }` instead of `{}`.
- **goku path hardcoded to Intel** — `hammerspoon/init.lua:42` uses `/usr/local/bin/goku`; needs `/opt/homebrew/bin/goku`.
- **Wrong JSON formatter** — `nvim/lua/js/plugins/conform.lua:25` runs Laravel Pint on JSON.
- **`install` won't run cleanly** — `install:14` passes `--plugin-dir dotbot-pip` but the plugin isn't initialized and `install.conf.yaml` has no `pip:` block. Drop the flag.

### Apple Silicon migration is half-done (`zsh/zshrc`)
- L22 `/opt/homebrew/lib` (lib dir, pointless in PATH)
- L25, L28: `/usr/local/aws/bin`, `/usr/local/opt/coreutils/libexec/gnubin` (Intel paths, don't exist)
- L32–34: `~/.dotfiles/bin/...` (repo is `~/dotfiles`, no leading dot — three dead PATH entries)
- L37: `~/nvim-osx64/bin` (Intel)
- L73: `complete -C '/usr/local/bin/aws_completer' aws` — Intel path
- L113: `FZF_DEFAULT_COMMAND='ag -u -g ""'` — `ag` not installed; switch to `rg --files` or `fd`
- L41: `ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX` — terminal is Alacritty, dead env var
- L64–69 + L176–177 — double `compinit` (~150-250ms cost per shell)
- L104, L158 — commented-out z.lua / JDK 1.8 sections (clutter)

### Hammerspoon / Karabiner / Amethyst
- `init.lua:678` `bundleId =` (no `local`) leaks to `_G`. Same pattern: `positions` (429), `lrsplits/tbsplits` (468–469), `currentLayout`/`layouts` (565–582), every fn in `helpers.lua`.
- `chain.lua:30` references `lastSeenAt` before declaration — fragile; declare `local lastSeenAt = 0`.
- `init.lua:287` "Swap with Main" emits `shift+option+return` — that's the Amethyst chord. Either fine (delegates to Amethyst) or redundant — verify.
- `init.lua:140` `appM` references Paw (EOL since 2022) and React Native Debugger.
- `amethyst.yml:240,250` — both `toggle-float` AND `toggle-tiling` bound to `mod1+t`. Last-parsed wins; one is silently ignored.
- `amethyst.yml:223-225` BSP bindings, but `bsp` not in active `layouts` (`:17-29`). Dead.
- `karabiner/karabiner.edn.bak` — stale 5.4 KB backup; delete.
- `hammerspoon/experimental.lua` — entirely commented-out dead code.
- Two near-identical hyper layers (escape vs caps_lock, `karabiner.edn:22-43` and `:44-64`) drift over time — extract to a shared var.

### Neovim modernization
- Deprecated APIs: `vim.loop` (use `vim.uv`), `vim.highlight.on_yank` (use `vim.hl.on_yank`), mason-lspconfig 1.x style (`automatic_installation`), conform's nested-table formatter syntax, lspconfig 0.11 style (`vim.lsp.config()` + `vim.lsp.enable()`).
- Volar 2.0 dropped takeover mode — pair with `vtsls` for JS/TS instead of letting Volar handle JS files.
- Major gaps: **no treesitter**, no gitsigns, no which-key.
- Minor: redundant `K` mapping (global at `keymaps.lua:89`, buffer-local at `lspconfig/keymaps.lua:21`); `clipboard = 'unnamed'` (should be `unnamedplus` on macOS); `nvim-lspconfig` declared twice; tracked `.DS_Store` files.

### Terminal stack
- `alacritty/alacritty.toml:7` — `live_config_reload = "true"` is a string; should be a bool.
- `alacritty/alacritty.toml:12-13` — `[font.bold] style = "Regular"` disables bold weight everywhere. Intentional?
- `alacritty/alacritty.toml:21-22` — large `font.offset.y = 12` combined with `glyph_offset.y = 7` may clip descenders.
- `tmux.conf:57` — `bind-key -n 'C-d' if-shell ... display-message` globally rebinds Ctrl-D to a status message; breaks shell EOF and copy-mode half-page-down.
- `tmux.conf:62-66` — dead `tmux_version < 3.0` branch on tmux 3.6a.

### Setup / install
- `install.conf.yaml:8-10, 30-32` — `sudo --validate` runs but nothing in install needs root. Remove.
- `install.conf.yaml:17` — symlinks vendored `bin/google-cloud-sdk/`, `apache-maven-3.9.9/`, `nvim-macos-arm64/` (tens of MB) into `~/.bin`. Split personal scripts from vendored toolchains.
- `README.md:27` says "iTerm" but `install.conf.yaml:19` configures Alacritty. README also missing install instructions.
- `raycast-scripts/` contains only `.DS_Store`.
- `gitconfig` missing modern defaults: `pull.ff=only`, `push.autoSetupRemote=true`, `rerere.enabled=true`, `merge.conflictstyle=zdiff3`. No commit signing.
- Several tracked `.DS_Store` files (`bin/`, `nvim/`, `tmux/`, `raycast-scripts/`, `hammerspoon/Spoons/`).

### Security (no high-severity)
- **Medium:** `zsh/custom/functions.zsh:8` `openpr()` rewrites git URLs to `http://` (not `https://`). Browser usually upgrades but the rewrite itself is wrong.
- **Medium:** No commit signing in `gitconfig` (developer identity is spoofable on public repos).
- **Low:** `zsh/custom/aliases.zsh:23,24` — `dpostgres`/`dmysql` expose `*_PASSWORD=secret` via env vars (visible in `ps`/`docker inspect`).
- **Informational:** `hammerspoon/helpers.lua:137,142` `triggerAlfredSearch`/`triggerAlfredWorkflow` interpolate raw strings into AppleScript; safe today (only static callers) but fragile.
- **Supply chain clean:** all submodules over HTTPS, lazy.nvim plugins commit-pinned via `lazy-lock.json`, no `curl|sh` patterns, secrets correctly externalized to `~/.secrets`.
