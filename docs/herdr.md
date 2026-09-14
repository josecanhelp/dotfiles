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
get backwards in both directions. Attaching with `herdr --remote <user>@<host>` neither
hands the whole UI to the remote machine nor keeps it all local. The split is per
setting:

| Setting | Read from | How known |
| --- | --- | --- |
| `[theme]`, `[theme.custom]` | **local client** | tested |
| `[ui]` sidebar settings | **local client** | documented |
| `[keys]` | **local client** (override with `--remote-keybindings server`) | documented |
| `[ui] tab_bar_right` | **remote server** | tested |
| `[ui] window_title` | **remote server** | documented |
| Custom commands and plugins | **remote server** | documented |

Note that `[ui]` is **split**. Sidebar settings come from the client while
`tab_bar_right` comes from the server, so the table name is not a reliable guide and
the rows have to be known individually. The "How known" column says which rows were
confirmed by experiment rather than taken from the reference.

herdr's docs state the first half: *"The UI uses the client's local theme, sidebar
settings, and keybindings by default. Herdr does not copy local command plugins,
configuration, executables, or secrets onto SSH hosts."*

They do not state the second half, and the sentence that looks like it does is a trap.
The reference says `hostname`, `datetime`, and `command` entries "resolve on the Herdr
server". That governs **where a value is computed**, not **which config the entry list
is read from**. Both happen to be server-side, but the sentence only asserts the first.
A `tab_bar_right` list written in the client config renders on local sessions and is
invisible under `herdr --remote`.

Verified directly: with an entry present locally and absent on the server, the status
area was blank on remote attach and correct locally.

`[theme.custom]` was tested the same way and came out the other direction. The client
sets `overlay1` to lime; fm-work's config was temporarily given `overlay1 = "#ff8800"`
and reloaded. The tag stayed **lime** on attach, so the client's theme wins and the
documented sentence holds for theme exactly as written.

The consequence is worth stating plainly, because it is the question this design keeps
running into: **the tag's color cannot differ per server.** Text and shape are the only
channels that can. Anything that looks like a per-server color would have to come from
outside herdr, for example launching each remote in its own Ghostty window with a
different theme.

The practical rule: **appearance cannot vary by server, content can, and content lives
on the server.** A theme change here paints identically whatever is on the far end.
Anything that should differ per machine has to be configured on that machine.

## The server tag

A marker at the right of the tab row says which server the client is attached to.
Because `tab_bar_right` is read server-side, this is **three config files, one per
machine**, each carrying a static `text` entry:

| Session | Config file | Shows |
| --- | --- | --- |
| local | `~/dotfiles/herdr/config.toml` (this repo) | `● LOCAL` |
| `--remote fmwork@homelab` | `~/.config/herdr/config.toml` on `fm-work` | `■ WORK` |
| `--remote fmpersonal@homelab` | `~/.config/herdr/config.toml` on `fm-personal` | `◆ PERSONAL` |

Static text rather than a command, because each file describes exactly one machine.
Nothing to detect at runtime, nothing that can time out. The markers are three
different **shapes**, since command output has ESC sequences stripped rather than
interpreted and the theme tokens that could color the entry are client-local, so shape
and wording are the only channels available.

**Known gap.** The two remote halves are hand-maintained and outside this repo. They
are not declared in nix, not version controlled, and a rebuilt container loses them.
A backup from the last edit sits beside each file as `config.toml.bak-<date>`.
Restoring one means appending the `[ui] tab_bar_right` block by hand and running
`herdr server reload-config` on that host.

### Gotcha: the ssh login name is not the shell user

Relevant if the tag ever becomes a `command` entry again. `herdr --remote
fmwork@homelab` logs in as `fmwork`, but the shell on the far side runs as **`node` on
both containers**, so matching on `id -un` matches neither and falls through silently.
Match on `hostname`, which is `fm-work` and `fm-personal` and names the machine the
server actually runs on.

A command entry can be checked without attaching, by running it where it would run:

```
$ ssh -o BatchMode=yes fmwork@homelab '/bin/sh -lc "hostname"'
fm-work
```

That check is worth the one command. A command entry that fails, times out, or returns
nothing leaves the area **blank** with no error shown anywhere, which is the same
symptom as the entry not being configured on that server at all. Those two causes are
indistinguishable from the client, so check the server config first.

herdr also ships a built-in `{ type = "hostname" }` entry that needs no shell. It
prints the raw hostname, already readable here, and cannot fail the way a command can.

Notes on `command` entries, none of which are obvious:

- They run through **`/bin/sh -lc`** on Linux and macOS (`cmd.exe /d /c` on Windows).
  Full shell syntax works inline, so a one-line `case` needs no script file on disk.
  Note `-lc` is a *login* shell, so profile startup counts against the timeout.
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
