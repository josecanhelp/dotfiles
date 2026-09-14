# Keyboard Workflow: Karabiner, Goku, and Hammerspoon

This documents how a single physical shortcut can trigger the "same" action across
many apps, even when each app binds that action to a different native keystroke.

The canonical example: `hyper + '` opens the command palette in VS Code, the Quick
actions menu in Figma, the command bar in Teams, and so on. One chord, one intent,
many app-specific keystrokes.

## The three-layer model

```
  Physical key            Semantic intent              App-specific keystroke
  (Karabiner/Goku)        (Hammerspoon URL handler)    (sent to frontmost app)

  hyper + '        ->     hammerspoon://              ->  VS Code:  Cmd+Shift+P
                          opencommandpalette              Figma:    Cmd+/
                                                          Teams:    Cmd+E then /
                                                          Obsidian: Cmd+P
```

**Layer 1: Karabiner (compiled from `karabiner/karabiner.edn` by Goku).**
This is the physical layer. It maps a chord (for example `hyper + '`) to a *semantic
URL*, not to an app keystroke. hyper + `'` emits `open -g hammerspoon://opencommandpalette`.
Karabiner knows nothing about which app is focused or what its shortcuts are.

**Layer 2: Hammerspoon (`hammerspoon/init.lua`).**
This is the semantic layer. Each `hs.urlevent.bind('<intent>', ...)` is one *intent*
(for example "open the command palette"). Inside, it checks the frontmost app with
`appIs(...)` / `appIncludes({...})` and sends that app's real keystroke via
`hs.eventtap.keyStroke(...)`. This is where "same intent, different key per app" lives.

**Layer 3: `hammerspoon/appBundles.lua`.**
A lookup table mapping a readable name (`vscode`, `figma`, `slack`) to a macOS bundle
identifier (`com.microsoft.VSCode`, `com.figma.Desktop`, `com.tinyspeck.slackmacgap`).
The intent handlers reference these names.

### End-to-end trace: `hyper + '` in Figma

1. Karabiner sees Escape (or Caps Lock) held plus `'`. Its Goku rule
   `[:quote [:hs "opencommandpalette"]]` runs `open -g hammerspoon://opencommandpalette`.
2. Hammerspoon's `opencommandpalette` handler fires. It walks its `if appIs(...)` chain.
3. `appIs(figma)` is true (frontmost bundle ID is `com.figma.Desktop`), so it sends
   `Cmd+/`, which opens Figma's Quick actions menu.

Nothing in Karabiner mentions Figma. Adding Figma support was purely a Hammerspoon change.

## Layer 1: Karabiner chord layers

Modifier legend (from the top of `karabiner.edn`): `C` = left command, `T` = left
control, `O` = left option, `S` = left shift, `!` = mandatory modifiers, `!!` = hyper
(command + control + shift, optional option). Entries shown as a keystroke (for example
`Cmd+W`) are emitted directly by Karabiner; entries shown as `hammerspoon://name` hand
off to Layer 2.

### Hyper Mode

Activated by holding **Escape** or **Caps Lock**. Tapping either key alone still sends
Escape. Both triggers expose the same bindings.

| Key | Action |
| --- | --- |
| `b` | `hammerspoon://togglebreaktime` (toggle BreakTime) |
| `h` | `hammerspoon://navigateback` |
| `i` | `Cmd+Option+I` (direct; Escape-trigger layer only) |
| `j` | `hammerspoon://navigatedownward` |
| `k` | `hammerspoon://navigateupward` |
| `l` | `hammerspoon://navigateforward` |
| `m` | `hammerspoon://togglesidebar` |
| `n` | `hammerspoon://createanything` |
| `o` | `hammerspoon://openanything` |
| `p` | `hammerspoon://openprojectselector` |
| `q` | `Cmd+W` (direct; close window) |
| `f` | `hammerspoon://openfocusmodal` |
| `s` | `hammerspoon://openspacesmodal` |
| `v` | `Option+J` (direct; app overlay) |
| `w` | `hammerspoon://openwindowmodal` |
| `y` | `hammerspoon://copyanything` |
| `'` | `hammerspoon://opencommandpalette` |
| `return` | `hammerspoon://openappmodal` |
| `;` | `hyper+P` (direct; opens Raycast) |

### Super Duper Mode

Activated by pressing **`s` and `d` simultaneously**. Multiplexer control. Works against
both tmux and herdr, which are configured to share the `Ctrl+A` prefix and the same
bindings, because Hammerspoon cannot tell which one is running (same terminal, same
bundle ID).

| Key | Action | tmux | herdr |
| --- | --- | --- | --- |
| `f` | `Ctrl+A f Return` | find window | **nothing** |
| `up` | `hammerspoon://tabprevious` | same | same |
| `down` | `hammerspoon://tabnext` | same | same |
| `h` `j` `k` `l` | `navigateback` / `navigatedownward` / `navigateupward` / `navigateforward` | same | same |
| `n` | `Ctrl+A ,` | rename window | rename tab |
| `o` | `Ctrl+A z` | zoom pane | zoom |
| `r` | `Ctrl+A r` | reload config | **resize mode** |
| `-` | `hammerspoon://splithorizontally` | same | same |
| `\` | `hammerspoon://splitvertically` | same | same |
| `delete` | `Ctrl+A x y` | kill pane, `y` confirms | close pane; `y` may leak |
| `y` | `Ctrl+A Shift+[` | copy mode | no equivalent |

The bolded rows are the only ones that diverge. `r` is deliberate: remapping herdr's
reload onto `prefix+r` would collide with its resize mode, which earns the key more
often. The other three are tmux behaviours herdr has no counterpart for (`goto`, the
nearest thing to find-window, is undocumented and left alone rather than guessed at).

### herdr workspaces

Not reachable from Super Duper Mode, and not a tmux concept at all. herdr ships
`previous_workspace` and `next_workspace` **unset**, so out of the box there is no key
for this; `~/.config/herdr/config.toml` binds them.

| Keys | Action |
| --- | --- |
| `Ctrl+A Shift+K` | Previous workspace |
| `Ctrl+A Shift+J` | Next workspace |
| `Ctrl+A w` | Workspace picker (herdr default, and tmux's `choose-tree` key) |
| `Ctrl+A Shift+N` | New workspace |

These are herdr-only, so they are configured in herdr rather than sent through
Hammerspoon. Changes need `herdr server reload-config` to take effect.

Everything about herdr other than keys, including how the config is deployed and what
its theme tokens paint, is in [herdr.md](herdr.md).

### Launch Mode

A Goku simlayer on the **`'` (quote)** key: hold `'` and press a letter within 350ms to
launch an app. Tapping `'` alone types an apostrophe. (This coexists with `hyper + '`
because Hyper Mode requires Escape/Caps Lock to be held.)

| Key | Launches |
| --- | --- |
| `a` | Ghostty |
| `c` | Visual Studio Code |
| `f` | Brave Browser |
| `m` | Messages |
| `o` / `b` | Obsidian |
| `p` | Postman |
| `t` | Microsoft Teams |
| `s` | Slack |

## Layer 2: Hammerspoon intents

Each row is one `hs.urlevent.bind` handler in `init.lua`. The right column shows the
keystroke sent per frontmost app.

**Terminal** below means the `terminals` list in `init.lua`: Ghostty, iTerm and Alacritty.
Alacritty is still listed although Ghostty replaced it, so the bindings keep working if
you switch back. The keystrokes these rows send are *multiplexer* bindings rather than
terminal-app ones, so what has to agree is tmux and herdr, not the three emulators.

Note the traversal rows send `Ctrl+A h` rather than a bare `Ctrl+H`. Going through the
prefix is what makes them work in herdr as well as tmux, and it leaves `Ctrl+H` with the
focused app, so nvim splits keep working without tmux's `is_vim` shell guard.

### Cross-app action intents

| Intent | Per-app keystrokes |
| --- | --- |
| `opencommandpalette` | VS Code `Cmd+Shift+P` · **Figma `Cmd+/`** · Teams `Cmd+E` then `/` · Obsidian `Cmd+P` · IntelliJ `Cmd+Shift+A` |
| `openanything` | VS Code / TablePlus / Fork `Cmd+P` · Teams `Cmd+E` · Eclipse `Cmd+Shift+R` · Discord / Superhuman `Cmd+K` · Slack / Monday `Cmd+K` then `Down` · PhpStorm / Xcode `Cmd+Shift+O` · Brave `Shift+T` (Vimium) · OmniFocus / Obsidian `Cmd+O` · Bear `Cmd+Shift+F` · IntelliJ `Cmd+T` · else: notify with bundle ID |
| `createanything` | OmniFocus `Ctrl+Option+Space` · Bear `Cmd+N` · Brave `Cmd+T` |
| `closeanything` | Brave `Cmd+W` |
| `openprojectselector` | VS Code `Cmd+Option+P` · Terminal `Ctrl+A f Return` |
| `togglesidebar` | VS Code `Cmd+B` then `Cmd+H` · Slack `Cmd+Shift+D` · Bear `Ctrl+3` · PhpStorm `Cmd+1` · Sketch `Cmd+Option+1` then `Cmd+Option+2` · Obsidian `Cmd+Option+Ctrl+M` · OmniFocus `Cmd+Option+S` |
| `navigateback` | Bear / Spotify `Cmd+Option+Left` · Finder / Slack / Brave `Cmd+[` · VS Code `Cmd+K Cmd+Left Esc` · Obsidian `Cmd+Option+Ctrl+A` · Terminal `Ctrl+A h` · (in Window modal: `a`) |
| `navigateforward` | Bear / Spotify `Cmd+Option+Right` · Finder / Slack / Brave `Cmd+]` · VS Code `Cmd+K Cmd+Right Esc` · Obsidian `Cmd+Option+Ctrl+D` · Terminal `Ctrl+A l` |
| `navigateupward` | TablePlus `Cmd+[` · Bear `Up` · VS Code `Ctrl+\`` then `Esc` · Messages `Ctrl+Shift+Tab` · Brave `Cmd+Shift+]` · Terminal `Ctrl+A k` · Obsidian `Cmd+Option+Ctrl+W` · else `Cmd+Shift+[` |
| `navigatedownward` | TablePlus `Cmd+]` · Bear `Down` · VS Code `Ctrl+\`` · Messages `Ctrl+Tab` · Brave `Cmd+Shift+[` · Terminal `Ctrl+A j` · Obsidian `Cmd+Option+Ctrl+S` · else `Cmd+Shift+]` |
| `copyanything` | selected text to clipboard · Bear `Cmd+Option+Shift+L` (copy note link) · Brave `yy` (copy URL) |
| `tabprevious` | Terminal `Ctrl+A p` · VS Code `Cmd+Option+Left` |
| `tabnext` | Terminal `Ctrl+A n` · VS Code `Cmd+Option+Right` |
| `splithorizontally` | Terminal `Ctrl+A -` · Obsidian `Cmd+Option+Ctrl+-` |
| `splitvertically` | Terminal `Ctrl+A v` · Obsidian `Cmd+Option+Ctrl+\` |
| `togglebreaktime` | toggles the BreakTime app via AppleScript (not app-specific) |

### Modal intents

These open a Hammerspoon modal (a sub-mode with its own keymap) rather than sending a
single keystroke.

| Intent | Opens |
| --- | --- |
| `openappmodal` | App launcher modal (`appM`) |
| `openfocusmodal` | Directional window focus modal (`focusM`) |
| `openspacesmodal` | Spaces navigation modal (`spacesM`) |
| `openwindowmodal` | Window sizing / positioning modal (`windowM`) |
| `enablelayoutm` | Multi-window layout modal (`layoutM`) |
| `reloadhammerspoon` | Reloads the Hammerspoon config |

## Layer 3: App bundle IDs

`appBundles.lua` maps names to bundle IDs. To find a new app's ID:

```sh
osascript -e 'id of app "Figma"'      # -> com.figma.Desktop
```

The `if true then` fallback in the `openanything` handler also notifies you with the
frontmost app's bundle ID and offers to copy it, which is a quick way to discover IDs
while an app is focused.

## Recipe: add an existing intent to a new app

This is the common case, and what adding Figma looked like. No Karabiner change is
needed because the chord already routes to the intent.

1. **Register the app** in `appBundles.lua` (keep the list alphabetical):

   ```lua
   figma = 'com.figma.Desktop'
   ```

2. **Add a branch** to the relevant intent handler in `init.lua`:

   ```lua
   hs.urlevent.bind('opencommandpalette', function()
       if appIs(vscode) then
           hs.eventtap.keyStroke({ 'cmd', 'shift' }, 'p')
       elseif appIs(figma) then
           hs.eventtap.keyStroke({ 'cmd' }, '/') -- Figma Quick actions
       elseif appIs(teams) then
           ...
   ```

   Use `appIs(x)` for one app, `appIncludes({ x, y })` for several sharing a keystroke.

3. **Save.** The `ReloadConfiguration` spoon watches the config and reloads Hammerspoon
   automatically. Focus Figma and press `hyper + '` to test.

To give Figma more mappings later (sidebar toggle, navigation, and so on), repeat step 2
in the matching handler (`togglesidebar`, `navigateback`, etc.). Each is just another
`elseif appIs(figma)` branch.

## Recipe: add a brand-new intent

Use this when the action itself is new, not just a new app for an existing action.

1. **Add a chord** in `karabiner.edn` under the Hyper Mode rules, pointing at a new
   intent name:

   ```clojure
   [:g [:hs "mynewintent"]]
   ```

   Saving triggers the declarative `launchd.agents.goku` watcher in
   `nix/home/darwin/karabiner.nix`, which runs Goku with absolute Nix store paths.

2. **Add the handler** in `init.lua`:

   ```lua
   hs.urlevent.bind('mynewintent', function()
       if appIs(vscode) then
           hs.eventtap.keyStroke({ 'cmd' }, 'somekey')
       elseif appIs(figma) then
           hs.eventtap.keyStroke({ 'cmd' }, 'otherkey')
       end
   end)
   ```

3. **Save both.** Karabiner recompiles through launchd, Hammerspoon reloads, and
   `hyper + g` now dispatches per app.

## Why this design

Keeping Karabiner "dumb" (chord to intent) and Hammerspoon "smart" (intent to per-app
keystroke) means:

- Muscle memory is per *intent*, not per app. "Command palette" is always `hyper + '`,
  regardless of which app translates it to which keystroke.
- Adding or changing app behavior never touches Karabiner, so there is no Goku rebuild
  and no risk to the physical key layer.
- All app-awareness lives in one place (`init.lua`), driven by one lookup table
  (`appBundles.lua`).
