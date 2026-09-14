# herdr

herdr is the terminal workspace manager that replaced tmux on 2026-09-12. This page
covers how its configuration is managed here and records behavior that herdr's own
documentation does not state. For keybindings and how they interact with Karabiner
and Hammerspoon, see [keyboard-workflow.md](keyboard-workflow.md).

Everything below was verified against **herdr 0.9.0**. It is partly reverse-engineered,
so re-check it after a major upgrade.

## How the config is managed

`nix/home/darwin/herdr.nix` links the config with `mkOutOfStoreSymlink`:

```
~/.config/herdr/config.toml  ->  ~/dotfiles/herdr/config.toml   (same inode)
```

This matches the rule in [nix-conventions.md](nix-conventions.md): out-of-store links
are for configuration that needs direct editing or is written by its owning tool.
herdr qualifies on both counts. `herdr config reset-keys` rewrites `config.toml` in
place, which would fail against a read-only store path.

Two consequences worth knowing:

- **Editing `herdr/config.toml` in this repo edits the live config.** No
  `darwin-rebuild` or flake switch is needed, because the content never enters the
  store. The deploy step is `herdr server reload-config`, nothing else. You only need
  a rebuild if you change the *link* in `herdr.nix`, such as managing a second file.
- **The config depends on the `~/dotfiles` checkout existing.** That is the cost
  `nix-conventions.md` names for this approach, accepted deliberately.

Verify a change with `herdr config check` (prints `config: ok` or diagnostics) and
apply it with `herdr server reload-config`, which returns JSON including a
`diagnostics` array. An empty array means it parsed and applied cleanly.

The herdr **binary** is deliberately not declared anywhere in this repo. It installs
and updates itself into `~/.local/bin` via `herdr update`, on a channel it tracks on
its own, so a fresh machine needs that bootstrap by hand. This is a known gap against
"declare what matters", tracked in [nix-reproducibility-review.md](nix-reproducibility-review.md).

## Which config applies under `herdr --remote`

This is the single most useful thing to know about remote sessions, and it is easy to
get backwards. Attaching with `herdr --remote <user>@<host>` does **not** hand the
whole UI to the remote machine.

| Setting | Resolved by |
| --- | --- |
| `[theme]`, `[theme.custom]` | **local client** |
| `[ui]` sidebar settings | **local client** |
| `[keys]` | **local client** (override with `--remote-keybindings server`) |
| `tab_bar_right` entries of type `hostname`, `datetime`, `command` | **remote server** |
| `window_title` | **remote server** |
| Custom commands and plugins advertised by the server | **remote server** |

herdr's docs state it as: *"The UI uses the client's local theme, sidebar settings, and
keybindings by default. Herdr does not copy local command plugins, configuration,
executables, or secrets onto SSH hosts."*

The practical rule: **appearance cannot vary by server, content can.** Any theme or
color change made here paints identically no matter which machine is on the far end.
Only things herdr resolves server-side can differ.

## The server tag

`[ui] tab_bar_right` in `herdr/config.toml` pins a marker to the right of the tab row
saying which server the client is attached to:

| Attached to | Shows |
| --- | --- |
| `herdr --remote fmwork@homelab` | `■ WORK` |
| `herdr --remote fmpersonal@homelab` | `◆ PERSONAL` |
| this machine | `● LOCAL` |

A `hostname` entry cannot do this, because both remotes are the same box and only the
account differs. The entry reads the username instead, via a `command` entry that
resolves on the server.

Notes on `command` entries, none of which are obvious:

- They run through **`/bin/sh -lc`** on Linux and macOS (`cmd.exe /d /c` on Windows).
  Full shell syntax works inline, which is why the tag is a `case` statement in the
  config rather than a script file deployed to three machines. Note `-lc` is a *login*
  shell, so profile startup counts against the timeout.
- herdr uses the **last line** of successful output and **strips ESC sequences rather
  than interpreting them**. A command cannot color its own output.
- The entry is **cleared** on failure, empty output, or timeout, and refills on the
  next interval. `interval_seconds` accepts 1 to 31,536,000 and `timeout_seconds`
  accepts 1 to 3,600.
- On narrow tab rows the status area **yields to tabs and controls**, so the tag is the
  first thing dropped. Shapes survive truncation better than words.

Because color cannot vary by server, the three markers are different **shapes**. Shape
and wording are the only channels that can actually distinguish the servers.

## Theme token map

herdr's config reference lists the `[theme.custom]` tokens but never says what any of
them paint. These were identified empirically: set a token to an obvious color, run
`herdr server reload-config`, and look at what moved.

| UI element | Token |
| --- | --- |
| Tab row background | `panel_bg` |
| Tab row right status entry foreground (the server tag) | `overlay1` |
| Sidebar background | `sidebar_bg` |
| Selected sidebar row background | `active_row_bg` |
| Sidebar primary text (branch line) | `text` |
| Sidebar secondary text (workspace name) | `subtext0` |

The full token set accepted under `[theme.custom]` is:

```
accent  panel_bg  sidebar_bg  active_row_bg  selection_bg
surface0  surface1  surface_dim  overlay0  overlay1
text  subtext0  mauve  green  yellow  red  blue  teal  peach
```

The tokens **not** in the table above were included in the probe but could not be
attributed, because nothing visible changed. They most likely paint states that were
not on screen: pickers, modals, toasts, resize mode, and confirmation dialogs. Repeat
the method above with those states open to finish the map.

Two caveats before setting any of these:

- The tokens are **shared**, not element-specific. Setting `overlay1` to color the
  server tag also repaints anything else drawn with `overlay1`.
- They are **client-local** (see the table further up), so they cannot indicate which
  server you are on.

`panel_bg` additionally accepts the literal value `"reset"`, which lets the outer
terminal background show through instead of herdr painting its own.

## Things that do not work

- **Per-element font size.** herdr is a TUI on a single cell grid. Every character is
  the terminal's font at the terminal's size, set in `nix/home/darwin/ghostty.nix`.
- **Per-entry styling in the tab bar.** Sidebar rows support inline token styles
  (`{ token = "workspace", fg = "#89b4fa", bold = true, dim = false }` under
  `[ui.sidebar.agents]` and `[ui.sidebar.spaces]`). The tab bar has no equivalent.
- **Reading tab bar state programmatically.** `herdr api snapshot` does not expose it,
  so the tag can only be verified by looking at the screen.

## Reference

herdr ships no local copy of its configuration reference. The sources used here:

- Config reference: `docs/next/website/src/data/config-reference.json` in `herdrdev/herdr`
- Configuration guide: `docs/next/website/src/content/docs/configuration.mdx`
- Remote attach: `docs/next/website/src/content/docs/connecting-machines.mdx`
- `herdr --default-config` prints the annotated defaults locally, and is the fastest
  way to see what a version actually accepts.
