# Reproducibility audit

**Date:** 2026-08-09
**Scope:** everything on this Mac that a fresh machine would not get from
`darwin-rebuild switch`.
**Status:** findings only. Nothing here has been acted on.

## The headline

| | Count |
|---|---|
| `.app` bundles found | 129 |
| Not independently declarable (Apple, helpers, browser stubs) | 23 |
| Already covered by a declaration | 13 |
| **Undeclared, a cask exists** | **64** |
| Undeclared, Mac App Store | 15 |
| Undeclared, no cask | 14 |
| **Declared but the app is missing** | **2** |

Plus 16 macOS settings that are deliberate, undeclared, and expressible in
nix-darwin, 54 undeclared VS Code extensions, and nine things that are already
broken or that break on a fresh machine.

**Status as of 2026-08-10: Tiers 1, 2 and 3 are complete.** All nine Tier 1
items are fixed, 53 applications are declared as casks, and all 16 macOS
settings plus the keyboard shortcuts are declared. What remains is Tiers 4, 5
and 6, none of which is broken, plus the Mac App Store apps. Each section below
carries its own status line.

## Confidence

Findings below are verified, not inferred. Cask tokens were checked against
the real Homebrew cask index (7,685 tokens), not guessed. nix-darwin option
paths were read out of the flake input's own source at
`/nix/store/4zfrqa0lg8q036z285zh7v4r3dmkyvkd-source/modules/system/defaults/`,
because wrong option names fail at build time rather than degrading quietly.

Two caveats on "unused" claims: `mdls -name kMDItemLastUsedDate` is null for
roughly half the apps, including Safari, which is in daily use. Dates marked
`~` come from a support-file mtime proxy and are a lower bound. Do not treat
either as proof an app is abandoned.

An earlier draft of this document claimed the 13 declared casks exactly
matched the 13 installed, with no drift. **That was wrong**, and the way it
was wrong is instructive: comparing Caskroom directory names to the declared
list only proves Homebrew's *records* agree with the config. It says nothing
about whether the applications still exist. See Tier 1 item 9.

The goku finding was corrected the same way. A first pass read a live PID as
"still working, dies at reboot." Reading the job's actual child process and log
showed it has been failing for days. Both corrections came from checking the
thing itself rather than a proxy for it.

---

## Tier 1: broken, or breaks on a fresh machine

### 1. ~~goku is already broken, not "will break"~~ FIXED 2026-08-09

Replaced by launchd.agents.goku in nix/home/karabiner.nix, invoking watchexec
directly with store paths. Both Homebrew registrations and the 4.3M-line log
removed. After activation, touching `karabiner.edn` regenerated
`karabiner.json`: the first confirmed successful compile since the packages
migration.

`~/Library/LaunchAgents/homebrew.mxcl.goku.plist` runs
`/opt/homebrew/opt/goku/bin/gokuw`, which the packages migration deleted along
with the formula.

Three separate readings of this were produced during the audit and **all three
were partly wrong**, so here is what was actually measured.

Both processes are alive:

```
7508  /bin/sh /opt/homebrew/opt/goku/bin/gokuw
7532  watchexec -r -e edn -w /Users/jose/.config/karabiner.edn goku
```

So it is not true that the job died, and not true that the watcher never
started. But PID 7532's environment is:

```
PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin
```

and **neither `goku` nor `watchexec` exists anywhere on that PATH**. Verified
directly rather than inferred:

```
$ env -i PATH="/opt/homebrew/bin:...:/sbin" sh -c 'command -v goku'
goku: NOT FOUND on this PATH
```

So the watcher is running but **cannot execute the command it exists to run**.
When an `.edn` edit fires it, the `goku` invocation will fail. Auto-compilation
is dead now, not at the next reboot.

`~/Library/Logs/goku.log` corroborates the history: **4.3 million lines** of
`gokuw: line 2: watchexec: command not found`, which stopped growing on Aug 8
at 21:57 when the current supervisor pair came up. That log is also worth
deleting on its own merits.

The practical impact is currently latent: `karabiner.edn` has not been edited
since 2026-01-01 and `karabiner.json` was compiled 2026-08-06, so the two agree
today. The breakage bites on the *next* Karabiner edit, which will silently do
nothing.

That mtime comparison is not evidence of breakage and should not be
re-derived as such: it compares a symlink's mtime against a regular file's,
and an unchanged `karabiner.json` is equally consistent with nothing having
needed compilation. The finding rests on exactly two things: PID 7532's PATH
containing neither binary, and the goku.log wall of "watchexec: command not
found".

There is also a **duplicate registration**: a root-owned
`/Library/LaunchDaemons/homebrew.mxcl.goku.plist` (916 B, Apr 2025) in a
failing respawn loop, `last exit code = 78: EX_CONFIG`. Nothing should have
registered goku as a system daemon; it has since been deleted along with the
user-level registration.

**Superseded original proposal, kept for history only, do not copy it.** It
argued the fix must set PATH explicitly, because `gokuw` is a two-line shell
wrapper that calls both `watchexec` and `goku` by bare name, and that
declaring only the program path would reproduce the same failure with
prettier paths. Both binaries are in Nix
(`/run/current-system/sw/bin/watchexec` confirmed present):

```nix
launchd.user.agents.goku = {
  serviceConfig = {
    ProgramArguments = [ "${pkgs.goku}/bin/gokuw" ];
    RunAtLoad = true;
    KeepAlive = true;
    StandardErrorPath = "/Users/jose/Library/Logs/goku.log";
    EnvironmentVariables.PATH =
      "${pkgs.goku}/bin:${pkgs.watchexec}/bin:/usr/bin:/bin";
  };
};
```

`launchd.user.agents` is nix-darwin's option, not home-manager's; copied into
`nix/home/` this fails to evaluate, and copied into `nix/configuration.nix` it
creates a second, competing goku agent. What was actually implemented is the
opposite approach: home-manager's `launchd.agents.goku` in
`nix/home/karabiner.nix:23`, which skips `gokuw` and invokes `watchexec`
directly with absolute Nix store paths for both binaries, so no bare-name
PATH lookup and no PATH patching are involved.

### 2. ~~Dead php@8.1 LaunchAgent~~ FIXED 2026-08-09

Plist deleted. PHP removed from the system entirely in the same sub-project.

`homebrew.mxcl.php@8.1.plist` points at
`/opt/homebrew/opt/php@8.1/sbin/php-fpm`, removed in the migration. Not
loaded. php is now 8.3.32 from Nix. The plist was inert and has since been
deleted.

### 3. ~~A third broken launchd job, from our own tmux migration~~ FIXED 2026-08-09

Replaced by launchd.agents.tmux-boot in nix/home/tmux.nix; @continuum-boot set
off so continuum deletes its own plist.

`Tmux.Start.plist` is registered in the user domain with **no file in
`~/Library/LaunchAgents`**, because tmux-continuum registers it dynamically.
A directory listing misses it entirely. `launchctl list` shows
`LastExitStatus = 1`, failing at every login.

Its target is
`~/.tmux/plugins/tmux-continuum/scripts/handle_tmux_automatic_start/osx_alacritty_start_tmux.sh`,
a tpm path. `~/.tmux/` now contains only `resurrect/`; the whole `plugins/`
tree went away when tpm was retired and plugins moved to nixpkgs.

At the time of this finding, `nix/home/tmux.nix:51-52` still declared:

```
set -g @continuum-boot 'on'
set -g @continuum-boot-options 'alacritty,fullscreen'
```

So the declared config asked continuum to register a boot agent, while the
registration that actually sat in launchd was the stale tpm-era one above,
pointing at a `~/.tmux/plugins/` path that no longer existed. `@continuum-boot`
is now `'off'` at `nix/home/tmux.nix:60`, so continuum no longer tries to
register its own agent; `launchd.agents.tmux-boot` is the declared replacement
noted above.

**All three broken jobs share a root cause worth noting:** `brew services list`
returns empty with exit 0. No `brew` command surfaces any of them, which is
exactly why they went unnoticed through the whole migration.

### 4. ~~Dangling `~/.aerospace.toml`~~ FIXED 2026-08-10

Removed. It was a dotbot-era symlink, so home-manager never owned it and no
rebuild would ever have cleaned it up.

Symlink dated 2025-08-13 pointing at
`/Users/jose/dotfiles/aerospace/aerospace.toml`, deleted when AeroSpace was
removed. dotbot created it, so home-manager never owned it and never cleaned
it up.

The general lesson matters more than this one file: **dotbot-era symlinks in
`$HOME` are invisible to home-manager.** Anything dotbot linked that
home-manager does not now declare will dangle forever with no warning.

### 5. ~~Four Homebrew formulae are used but not declared~~ FIXED 2026-08-10

`ant`, `pipx` and `ruby` are now in `homebrew.brews`. `pytorch` was
deliberately left undeclared instead, matching the argument already written in
`packages.nix` that it belongs in a devshell rather than globally.

`brew leaves --installed-on-request` and the `homebrew.brews` list in
`configuration.nix` are **disjoint sets**.

Installed but not declared: `ant`, `pipx`, `pytorch`, `ruby`. These are the
documented exceptions in `packages.nix`, but they are documented in a
*comment* explaining why they are not in nixpkgs. Nothing installs them. A
fresh machine gets none of them.

Declared but absent from `brew leaves`: `themekit`, `ecsplorer`. Both are
fine, both are installed. `brew leaves` simply does not list them despite
both being marked `installed_on_request`. `msodbcsql17` was removed from the
declaration on 2026-08-09; the formula itself is still installed. See Tier 6,
where that unreliability is the finding rather than a footnote.

### 6. ~~Hostname is assumed, never set~~ FIXED 2026-08-10

`networking.computerName` and `networking.localHostName` are declared, and
`mkHost` now takes `hostname` and `user` so a second machine is one block.

`flake.nix` keys its configuration on `REM-JoseS-MBP1` and
`scutil --get ComputerName` returns that today, but `configuration.nix` has no
`networking.*` settings. The flake *requires* the hostname without *setting*
it, so on a fresh machine the rebuild fails until it is set by hand.

```nix
networking.computerName = "REM-JoseS-MBP1";
networking.localHostName = "REM-JoseS-MBP1";
```

`networking.hostName` is deliberately omitted: `scutil --get HostName` is
currently unset, so declaring it would be a behavior change rather than a
capture of current state.

Caveat: the `REM-` prefix suggests corporate MDM assigns this name. Declaring
it is harmless if MDM agrees and will fight MDM if IT ever renames the
machine. Worth a comment in the config.

### 7. ~~The declared tmux config depends on an undeclared file~~ FIXED 2026-08-10

`claude/notify.sh` is tracked in the repo and linked to `~/.claude/notify.sh`,
so both halves of the hook pair now ship together.

`nix/home/tmux.nix:106-108` declares:

```
# The marker itself is set by ~/.claude/notify.sh (Claude Code hooks).
set-hook -g session-window-changed 'set-option -w @claude_alert ""'
```

`~/.claude/notify.sh` exists on disk (797 B, executable) and is **not tracked
in this repo**. `git ls-files` has no match for it.

So a declared piece of config depends on an undeclared file. On a fresh
machine the hook installs and clears a marker nothing ever sets. Half a
feature, silently.

Fix by declaring `notify.sh`, either through `programs.claude-code.hooks` or
as a plain `home.file`. The lighter route is fine; what matters is that the
two halves ship together. Note `settings.json` also references it by absolute
`/Users/jose/` path, so that path assumption travels with it.

### 8. ~~`~/.nix-profile` is dangling, and `shell.nix` puts it on PATH~~ FIXED 2026-08-10

The vestigial PATH entry is gone, and `verify.sh` now accepts
`/etc/profiles/per-user/*` in its place, which is where `useUserPackages`
actually installs.

`~/.nix-profile` points at `~/.local/state/nix/profiles/profile`, which does
not exist. Meanwhile `nix/home/shell.nix:231` ends with:

```sh
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
```

That middle entry resolves to nothing.

**Do not "fix" this by recreating the profile.** The dangling link is expected:
`configuration.nix:29` sets `home-manager.useUserPackages = true`, which
installs home-manager packages into `/etc/profiles/per-user/$USER` rather than
`~/.nix-profile`. That directory exists, is populated, and is already on PATH.
`/nix/var/nix/profiles/per-user/jose` is absent for the same reason.

So nothing is broken; the PATH entry is simply vestigial. zsh does not error on
nonexistent PATH directories. The correct cleanup is to drop it, leaving:

```sh
export PATH="/run/current-system/sw/bin:$PATH"
```

which still satisfies the "Nix must win over Homebrew" intent documented above
it. `verify.sh:46` also accepts `$HOME/.nix-profile/bin/*` as a valid Nix path
in a case that can never match, and can lose that branch too.

### 9. ~~Two declared casks whose apps are gone~~ FIXED 2026-08-10

`barrier` and `drawio` dropped from `homebrew.casks`. Both apps had been
deleted outside Homebrew, so a fresh machine would have resurrected two unused
apps.

| Cask | Caskroom record | App | State |
|---|---|---|---|
| `barrier` | 2.4.0, staged 2023-02-17 | `/Applications/Barrier.app` | **missing** |
| `drawio` | 28.1.2, staged 2025-10-01 | `/Applications/draw.io.app` | **missing** |

Both were deleted outside Homebrew, so Homebrew still believes they are
installed and `darwin-rebuild` is a no-op today. But a `brew reinstall` or a
fresh machine resurrects two apps that are not in use. Barrier upstream is
also unmaintained; Deskflow and Input Leap are its successors.

Each needs an explicit decision: reinstall, or drop from `homebrew.casks`.

---

## Tier 2: applications

**DONE 2026-08-10.** The cask list went from 11 to 53. Of the 59 apps that had
an official cask, 43 were declared and 16 were reviewed and deliberately left
out: Cap, Cyberduck, ScreenFlow, Visual Studio, Discord, ResponsivelyApp,
cool-retro-term, DBeaver, Eclipse, MySQLWorkbench, Raspberry Pi Imager, Sketch,
Tunnelblick, NordVPN, VirtualBox and DisplayLink Manager. Those stay installed
and simply will not follow to a new machine.

One thing learned in the doing, recorded in `configuration.nix`: declaring an
app Homebrew did not install is not free. Homebrew tries to adopt the bundle and
refuses on a version mismatch, which is the normal state for anything that
self-updates after a direct download. Three of the 43 hit it and Obsidian failed
destructively, removing the app before erroring.

The original survey follows, kept for the token list.

The largest single win. 64 apps have an official cask and are installed by
direct download today.

### Tokens that are not the obvious guess

Worth calling out separately, because guessing these wrong wastes a rebuild:

| App | Correct token | The wrong guess |
|---|---|---|
| Docker | `docker-desktop` | `docker` |
| HandBrake | `handbrake-app` | `handbrake` is the CLI formula |
| Wireshark | `wireshark-app` | `wireshark` |
| DBeaver | `dbeaver-community` | `dbeaver` |
| Ledger Wallet | `ledger-wallet` | `ledger-live` |
| Epic Games | `epic-games` | `epic` is a different product |
| Company Portal | `intune-company-portal` | `company-portal` |
| Firefox Dev Edition | `firefox@developer-edition` | contains `@`, valid as a Nix string |
| Responsively | `responsively` | `responsivelyapp` |
| Eclipse | `eclipse-ide` | `eclipse` |

### Everyday drivers, highest value first

`1password`, `visual-studio-code`, `google-chrome`, `brave-browser`,
`chatgpt`, `claude`, `fork`, `hammerspoon`, `shottr`, `dbngin`, `figma`,
`slack`, `microsoft-teams`, `zoom`, `obsidian`, `dropbox`, `google-drive`,
`local`, `sizzy`, `tableplus`, `docker-desktop`, `firefox@developer-edition`,
`codex`, `monologue`.

**`karabiner-elements` deserves priority.** Its config is already version
controlled in this repo and paired with the declared `goku`, yet the
application itself is not declared. `Karabiner-EventViewer` ships inside the
same cask; do not declare it separately.

**`hammerspoon` and `shottr` are login items** (per the settings audit) but
are not in `homebrew.casks`, so a fresh machine would not install them at all
and the login-item entries would point at nothing.

### The rest

`balenaetcher`, `bambu-studio`, `cap`, `cool-retro-term`, `cyberduck`,
`discord`, `displaylink`, `eclipse-ide`, `epic-games`, `imageoptim`,
`intune-company-portal`, `istat-menus`, `izotope-product-portal`,
`ledger-wallet`, `minecraft`, `mysqlworkbench`, `nordvpn`, `obs`,
`openshot-video-editor`, `onedrive`, `raspberry-pi-imager`,
`screenflow`, `sf-symbols`, `sketch`, `sublime-text`, `transmit`,
`trezor-suite`, `tunnelblick`, `virtualbox`, `visual-studio`, `vlc`,
`wireshark-app`, `handbrake-app`, `dbeaver-community`, `responsively`.

Microsoft Office is either five individual casks (`microsoft-outlook`,
`microsoft-word`, `microsoft-excel`, `microsoft-powerpoint`,
`microsoft-onenote`) or the single `microsoft-office`. One cask, five apps.

**Corrected 2026-08-13: six apps.** The `microsoft-office` pkg also carries
`OneDrive.pkg` as a component (`xar -tf` on the installer confirms it), and the
cask's own uninstall block claims the `com.microsoft.OneDrive` receipt and
`/Applications/OneDrive.app`. That is why the `onedrive` cask declares
`conflicts_with` it.

Notes on a few:
- `vlc`, `obs`, `virtualbox` are **not** in nixpkgs for aarch64-darwin. The
  cask is the only route.
- `virtualbox` needs a system-extension approval on first install, so it is
  not fully unattended.
- `onedrive` has **two copies installed**: a non-MAS one at
  `/Applications/OneDrive.app` and an older MAS one (25.046.0310) at
  `/Applications/OneDrive.localized/`. Declaring the cask orphans the MAS
  copy. Resolve which one you want first.
  **RESOLVED 2026-08-13.** Declaring the cask was tried and failed activation
  outright on the conflict above, so `onedrive` stays undeclared and the
  `microsoft-office` pkg installs it. The MAS copy was deleted. Removing it
  needs root, which is not obvious: moving a directory rewrites its `..`, and
  the bundle is `root:wheel` 755, so being in `admin` gets you write on
  `/Applications` but not on the bundle. Renaming it in place works, moving it
  out does not. Nothing pins the version either way, since OneDrive leaves
  Homebrew's control at install and self-updates through its own three
  `OneDriveStandaloneUpdater` launch daemons, not brew and not MAU.
- `google-drive` installs the Docs/Sheets/Slides stubs as a side effect, so
  those are not separate declarations.
- `intune-company-portal` is likely MDM-managed; declaring it may fight the
  MDM channel.

### Version drift in existing casks

Several declared casks record a much older version than what is installed,
because the apps self-update in place: iterm2 (record 3.4.19, installed
3.6.10), postman (10.9.4 vs 12.18.5), raycast (1.47.3 vs 1.104.1),
android-studio (2025.2.1.8 vs 2026.1).

Harmless today. A `brew upgrade --cask` would rewrite those bundles.

### Mac App Store (15, one since removed)

nix-darwin installs `mas` automatically once `homebrew.masApps` is non-empty,
so no manual step is needed.

**Amended 2026-08-13.** The `OneDrive` entry (823766827) was dropped from the
block below. It was the duplicate MAS copy, since deleted, and declaring it
would reinstall a second OneDrive on every fresh machine. Fourteen to declare.

```nix
homebrew.masApps = {
  "Xcode" = 497799835;
  "WhatsApp" = 310633997;
  "Microsoft Remote Desktop" = 1295203466;
  "Pixelmator Pro" = 1289583905;
  "GIPHY CAPTURE" = 668208984;
  "TestFlight" = 899247664;
  "DaisyDisk" = 411643860;
  "Microsoft To Do" = 1274495053;
  "BreakTime" = 427475982;
  "Keynote" = 409183694;
  "iMovie" = 408981434;
  "1Password for Safari" = 1569813296;
  "Toggl Track" = 1291898086;
  "Swift Playground" = 1496833156;
};
```

Caveats: `masApps` only redownloads apps already tied to the Apple ID; `mas`
cannot sign in to the App Store on modern macOS, so it automates reinstall,
not first purchase. Xcode is a very large download and will make a fresh
activation slow. WhatsApp, Microsoft Remote Desktop, and DaisyDisk also have
casks if you would rather avoid the MAS route entirely. OneDrive is not listed
and should not be added: it comes with the `microsoft-office` cask.

### No cask available (14)

Not declarable. Recorded so nobody re-audits them.

| App | Why |
|---|---|
| DaVinci Resolve and its four helper apps | Blackmagic gates downloads behind a registration form |
| Blackmagic Proxy Generator Lite, RAW Player, RAW Speed Test | same |
| VMware Fusion | Broadcom moved downloads behind a login |
| Visual Studio for Mac | discontinued and delisted by Microsoft in 2024; no upstream download exists. Strong removal candidate |
| Microsoft Defender, Remote Help, 365 Copilot | MDM-managed. Leave alone |
| iZotope RX 7 | installed by the iZotope Product Portal, itself declarable |
| FileZilla, FileZilla Server | no current cask |
| Exodus, Splitscreen, Parkwest Casino | no cask |
| Advantage 360 SmartSet App | Kinesis keyboard utility, vendor download |

Also: `/Applications/Python 3.12` and `Python 3.13` are python.org framework
installers. `python314` is already declared in `packages.nix`, so these two
are redundant and are removal candidates rather than declarations.

---

## Tier 3: macOS settings

**DONE 2026-08-10.** All 16 are declared, along with the eight disabled keyboard
shortcuts, the two text replacements and the dictation flag.

Two of this section's recorded values were wrong and would have silently changed
the machine, which is the specific hazard of an enforced setting. It listed both
Dock folders as grid view sorted by name; nix-darwin's own mapping is
`showas: fan=1, grid=2` and `arrangement: name=1, date-added=2`, and the machine
stores 1 and 2, so they are fan and date-added. The values actually declared were
re-read off the running system rather than taken from here.

The original survey follows.

`configuration.nix` declares 13 settings across 4 domains, all matching the
live system. 16 more are deliberate, undeclared, and expressible.

### Highest value

| Setting | Current | Option |
|---|---|---|
| Dock contents | Brave, Messages, Photos, System Settings, iPhone Mirroring, Teams | `dock.persistent-apps` |
| Dock folders | `~/Screenshots`, `~/Downloads`, both grid | `dock.persistent-others` |
| Top-right hot corner | Desktop (4) | `dock.wvous-tr-corner = 4` |
| Click wallpaper to show desktop | off (non-default) | `WindowManager.EnableStandardClickToShowDesktop = false` |
| Tiled window margins | off (non-default) | `WindowManager.EnableTiledWindowMargins = false` |
| Alert volume | muted | `NSGlobalDomain."com.apple.sound.beep.volume" = 0.0` |

The Dock is the biggest gap: entirely unmanaged, so a fresh machine gets
Apple's stock Dock. The two `WindowManager` settings both matter specifically
because Amethyst is the window manager; Sequoia's own tiling fights it.

Note `bottom-right` hot corner is already declared while `top-right` is not,
which is inconsistent half-coverage of the same feature.

### The rest

`WindowManager.AutoHide = true`, `WindowManager.GloballyEnabled = false`,
`".GlobalPreferences"."com.apple.sound.beep.sound"`,
`NSGlobalDomain.AppleEnableSwipeNavigateWithScrolls = false`,
`finder.FXRemoveOldTrashItems = true`,
`finder._FXSortFoldersFirstOnDesktop = true`,
`finder.NewWindowTarget = "OS volume"`,
`finder.ShowExternalHardDrivesOnDesktop = true`,
`finder.ShowRemovableMediaOnDesktop = true`,
`spaces.spans-displays = false`.

Two typing traps: `NewWindowTarget` takes the friendly enum `"OS volume"`, not
the raw `PfVo` code, and the beep volume is a **float**, so `0.0` not `"0"`.

### Checked and deliberately not recommended

trackpad (all 22 supported keys at stock values), menuExtraClock, magicmouse,
universalaccess, ActivityMonitor, controlcenter, LaunchServices, hitoolbox,
screensaver, SoftwareUpdate, loginwindow, smb. Nothing deliberate in any of
them. nix-darwin has no Safari module and Safari's domain holds only migration
flags and toolbar state.

### Customized but not typed by nix-darwin

Keyboard shortcut changes, all disabled: the four screenshot shortcuts
(`AppleSymbolicHotKeys` 28/29/30/31), input-source switching (60/61, which
frees Ctrl-Space), Dock hiding (52), and Quick Note (190). Plus two text
replacements (`omw`, `heroky`) and `AppleDictationAutoEnable = 0`.

**Do not put the hotkeys in `CustomUserPreferences`.** nix-darwin's
`defaults-write.nix` emits one `defaults write <domain> <key> <plist>` per
top-level key, which **replaces** the whole value. Declaring
`AppleSymbolicHotKeys` that way would wipe the other 29 entries in the dict.
These need `-dict-add` in
`system.activationScripts.postUserActivation.text`.

The text replacements and the dictation flag are whole-value writes, so those
two are safe via `CustomUserPreferences`.

**Login items** (Shottr, Raycast, OneDrive, Hammerspoon, Google Drive,
Dropbox, FigmaAgent) are managed by `SMAppService`. nix-darwin has no option
and `defaults write` cannot set them. Not declarable.

---

---

## Tier 4: home directory config

125 dot entries at the top level of `$HOME`, 35 in `~/.config`. Of those, 7
plus 7 are already managed and verified intact, including the dual
`karabiner.edn` link that `default.nix` documents as load-bearing for goku.

The 215 MB in `~/.config` is three directories (`gcloud` 91 M, `raycast`
91 M, `yarn` 32 M), all credentials and payloads. **Actual config in
`~/.config` totals under 250 KB.** Size was a red herring.

### Candidates with a home-manager module

| Path | Tool | Option |
|---|---|---|
| `~/.claude/{settings.json,CLAUDE.md,notify.sh,agents,commands,skills}` | Claude Code | `programs.claude-code.*` |
| `~/Library/Application Support/Code/User/settings.json` | VS Code | `programs.vscode.profiles.default.userSettings` |
| `…/keybindings.json`, `…/snippets/`, `…/mcp.json` | VS Code | `keybindings`, `languageSnippets`, `userMcp` |
| `~/.vscode/extensions/` (55 extensions, 1.6 GB) | VS Code | `…extensions`, declare the list not the payload |
| `~/.codex/{config.toml,AGENTS.md,hooks.json}` | Codex CLI | `programs.codex.*` |
| `~/.config/gh/config.yml` | GitHub CLI | `programs.gh.settings` |
| `~/.config/htop/htoprc` | htop | `programs.htop.settings` |

Only declare the small files under `~/.claude`, not the 367 MB of project
history and telemetry. Same for `~/.codex`, where 1.1 GB is sqlite logs.

`programs.htop.settings` has the same tradeoff as alacritty: htop rewrites
`htoprc` on quit, so declaring it makes the file read-only and htop can no
longer persist UI changes.

### Modules that would replace config already hand-written here

Cheaper than the rows above, because the config already exists in this repo
and would shrink:

- **`programs.fzf`.** `shell.nix` currently sets five `FZF_*` variables through
  `sessionVariables` plus a manual `eval "$(fzf --zsh)"`, with a comment
  explaining a quoting workaround. The module sets all of them natively and the
  workaround disappears. `fzf` is already in `packages.nix`. Best value-per-line
  in this section.
- `programs.btop`, `programs.ranger`: both tools are declared with no config
  yet. Nothing to migrate today, worth knowing for when they get configured.
- `programs.java` would replace the hand-set `JAVA_HOME` in `shell.nix`, but it
  points `JAVA_HOME` at a nixpkgs JDK rather than the system one. That is a
  behavior change, not a capture. Only do it if moving the JDK to Nix is the
  actual goal.

### The five loose files, individually

Each turned out different, and three of the five are not what they look like:

| File | Verdict |
|---|---|
| `~/.mailmap` | **Declare it.** 6 hand-written author mappings for Converge colleagues including 3 of Jose's own identities. Currently **inert**: `git config --global --get mailmap.file` exits 1, so git never reads it. Needs `home.file` plus `programs.git.settings.mailmap.file`. Declaring it makes it work for the first time. |
| `~/.gitignore_global` | **Delete.** Fully superseded by `programs.git.ignores`, which already generates byte-identical content at `~/.config/git/ignore`. Confirmed inert. |
| `~/.npmrc` | **Split, do not commit.** Contains a live `_authToken` for `registry.marmelab.com`. The registry lines belong in `programs.npm.npmrc`; the token belongs in `~/.secrets` or `NPM_TOKEN`. Also carries a stale `python=/opt/homebrew/bin/python3` now that `python314` comes from nixpkgs. |
| `~/.yarnrc` | **Leave alone.** Autogenerated, self-declares "DO NOT EDIT". `programs.yarn` does **not** apply: it writes `.yarnrc.yml` for Yarn Berry, a different file in a different format. |
| `~/.prettierrc` | Empty config, `{"plugins": [], "overrides": []}`. Completeness only. |

### Also worth knowing

- `~/.config/wireshark/preferences` is 225 KB but mostly a default dump. Diff
  before declaring; probably not worth it.
- iTerm2 preferences (28 KB) have no home-manager module. The clean route is
  iTerm2's own "load preferences from a custom folder" plus a `defaults write`.
  Real work, moderate payoff, and Alacritty is the primary terminal.
- Amethyst's and Karabiner's plists are redundant with the already-declared
  `.amethyst.yml` and `.edn`. Leave both alone.
- 16 credential files were catalogued and are listed in the source audit. None
  belong in the repo. The notable one is `~/.npmrc` above, because it is the
  only credential mixed into a file that also holds real config.

---

---

## Tier 5: runtimes, editors, services

### Runtimes that are declared and working

php 8.3.32, node 22.23.1, python 3.14.6, dotnet 9.0.316, maven, minikube,
helm, gcloud, azure-cli, mariadb, redis: all from Nix, all declared. Ruby
correctly falls through to the system 2.6.10 per the documented exception.

### Runtimes that are not

| Tool | Source | Issue |
|---|---|---|
| **Java 17** | manual Oracle installer | `shell.nix:78` hard-codes `JAVA_HOME=/Library/Java/.../jdk-17.jdk`, a path **Nix does not create**. A fresh machine gets a dangling `JAVA_HOME`. Six JVMs are installed; `java_home` defaults to 22 while the config forces 17. |
| **Go 1.22.1** | golang.org pkg | `/usr/local/go`, on PATH via `/etc/paths.d/go` |
| **Composer 2.6.5** | loose phar, Oct 2023 | Nearly three years old, and this is a Laravel-primary machine. `php83Packages.composer` is in nixpkgs |
| **AWS CLI 2.24.15** | AWS pkg installer | **Mach-O x86_64, running under Rosetta.** `nixpkgs.awscli2` is both a declaration win and a native-arch win |
| **AWS SAM CLI** | AWS pkg installer | `nixpkgs.aws-sam-cli` exists |
| **AWS CDK** | yarn global | outside both Nix and Homebrew, and CDK is in the CLAUDE.md conventions |
| **11 legacy .NET SDKs** | Microsoft pkg | 6.0.x and 7.0.x in `/usr/local/share/dotnet`, reachable only by absolute path |
| **Docker Desktop** | direct download | provides `docker` and the compose plugin, no cask declared. Daemon not currently running |

If `awscli2` moves to Nix, `shell.nix:206` hard-codes
`complete -C '/usr/local/bin/aws_completer' aws` and must change to the store
path or completion silently breaks.

### Two live breakages in declared packages

- **`npm ls -g` fails.** `nodejs_22` resolves to `nodejs-slim`, which omits the
  npm lib tree, so global npm installs error with ENOENT on the store path.
  A real consequence of the `nodejs_22` choice that the migration notes do not
  mention.
- **`/opt/homebrew/bin/pip` is broken.** Its shebang points at
  `python@3.11`, which no longer exists. "bad interpreter."

### Version managers: none

nvm, rbenv, pyenv, jenv, sdkman, asdf, mise, volta, direnv: all absent.
`~/.nvm` is genuinely gone, verified four ways.

**A trap for anyone re-checking this:** a non-clean shell still shows
`~/.nvm/versions/node/v20.19.1/bin`, `~/.rbenv/versions/bin`,
`~/dotfiles/bin/google-cloud-sdk/bin`, `/opt/homebrew/opt/php@8.3/bin`, and
`~/nvim-osx64/bin` in `$PATH`. **None of those directories exist.** It is
inherited environment from processes started before the migration, not
config. Always test with
`env -i HOME=/Users/jose /bin/zsh -lic 'echo $PATH'`.

Worth considering: `packages.nix` recommends devshells for per-project
versions, but without `direnv` nothing enters them automatically.

### VS Code: 54 extensions, none declared

Neither the app nor its extensions are declared. `programs.vscode` handles
`extensions`, `userSettings`, and `keybindings`.

**Do not declare the current list verbatim.** It is heavily
Java/Spring/.NET/mainframe weighted (`vscjava.*` ×7, `vmware.vscode-spring-boot`,
`redhat.java`, `ibm.zopeneditor`, `zowe.*`, `ms-mssql.*`), which does not match
a PHP/Laravel/Vue focus. And there is **no PHP extension at all** and no Vue
extension. Declaring it faithfully would reproduce a stale, mismatched set.
Prune first.

Several IDs are marketplace-only and absent from `nixpkgs.vscode-extensions`,
so a faithful declaration realistically needs the `nix-vscode-extensions` flake
input. The full list is in the source audit.

Also note home-manager makes `settings.json` a read-only store symlink by
default, so in-app settings changes stop persisting.

### Dead editor state

**No JetBrains IDE is installed**, verified three ways, yet config remains for
`IdeaIC2024.3`, `IntelliJIdea2024.3`, and `IntelliJIdea2023.2`. Not realistically
declarable anyway (per-release versioned dirs, machine state mixed with
preferences, no home-manager module). Delete or mark intentionally unmanaged.

Sublime Text **is** installed and undeclared. Codex.app too. No Cursor, Zed,
Windsurf, or VSCodium despite `~/.cursor-tutor` ×3 on disk.

### Other services worth a decision

- **Homebridge is running** via `/Library/LaunchDaemons/com.homebridge.server.plist`.
  Correction to an earlier note: `hb-service` is **not** a brew formula. It is
  an npm global (`homebridge-config-ui-x`) in brew's `node_modules`, so it
  **cannot** be declared via `homebrew.brews`. It also runs on a **third** node
  (`/usr/local/bin/node` v22.14.0, root-owned, from a nodejs.org pkg) and its
  baked PATH is a fossil full of directories that no longer exist.
- **FileZilla Server is running** an FTP daemon (PID 837). Worth a conscious
  keep or remove decision.
- **`de.beyondco.herd.helper`** is orphaned: Laravel Herd's app is gone, but
  the privileged helper and support dir remain, including a bundled php82.

---

## Tier 6: CLI tools

### `brew leaves` is not trustworthy here. Use `brew list --formula --full-name`

`brew leaves` returns exactly `ant pipx pytorch ruby`. Yet `themekit`,
`ecsplorer`, and `msodbcsql17` are all installed **and** all marked
`installed_on_request=true` in their install receipts. They simply do not
appear.

The mechanism is the untrusted-tap refusal. An earlier test used `brew info`,
which loads formulae by a different path and gave a false negative: `brew info
shopify/shopify/themekit` works fine here. `brew uses --installed themekit`
does not. Verified 2026-08-09:

```
Error: Refusing to load formula shopify/shopify/themekit from untrusted
tap shopify/shopify.
```

Same for `ecsplorer` and `msodbcsql17`. **Formulae can be installed,
requested, and invisible to `brew leaves`,** because `brew leaves` has to load
every formula to build its graph and silently drops the ones it cannot.

This is not in tension with `installed_on_request: true`: that flag is read
from the on-disk install receipt without loading the formula at all, which is
exactly why receipt-based checks saw all 16 on-request formulae while `brew
leaves` saw four.

The omission is not tap-specific, either. `node@16` vanished the same way for
an unrelated reason: `Invalid OS condition: :mojave`.

This is not academic. It is how three real formulae stayed hidden through an
entire migration. Always enumerate with `brew list --formula --full-name`.

### Three formulae nobody documented

| Formula | Installed | nixpkgs | Verdict |
|---|---|---|---|
| `ghostscript` | 10.07.1 | 10.07.1, exact match | Migrate. Provides `gs`, `ps2pdf` |
| `tesseract` | 5.5.3 | 5.5.2 | Migrate. Real CLI |
| `node@16` | 16.20.2_1 | not in nixpkgs | **Broken. Delete, do not migrate** |

`node@16` fails outright:

```
dyld[]: Library not loaded: /opt/homebrew/opt/brotli/lib/libbrotlidec.1.dylib
```

The migration removed brotli underneath it. It cannot run.

Of 70 installed formulae, 16 are installed-on-request and 54 are
dependency-only. `brew leaves --installed-as-dependency` is empty, so there is
nothing to autoremove.

### 64 broken shims in `/opt/homebrew/bin`

Sixty-four files there have a shebang pointing at an interpreter that no longer
exists, mostly `python@3.11` and `python@3.14`. Every one fails with "bad
interpreter." Among them: `poetry`, `virtualenv`, `playwright`, `uvicorn`,
`httpx`, `fastmcp`, `mcp`, `keyring`, `dulwich`, `pip`.

These need deleting, not migrating. The only judgement call is `poetry`, which
is in nixpkgs if it is still wanted.

**Recount 2026-08-11: it is 52, and 64 appears to be wrong.** See item 4 of
"Suggested order" for the corrected figures, and for the one file in that set
that brew owns and should not be hand-deleted.

### Loose binaries worth migrating

All verified present in the pinned nixpkgs. Note how often the attribute name
differs from the binary name, which is exactly where a guess fails:

| Binary | Version | nixpkgs attribute | Note |
|---|---|---|---|
| `aws` | 2.24.15 | `awscli2` | **x86_64 under Rosetta.** Native win as well as a declaration win |
| `sam` | 1.150.1 | `aws-sam-cli` | |
| `session-manager-plugin` | 1.2.694.0 | `ssm-session-manager-plugin` | attribute differs |
| `composer` | 2.6.5 (Oct 2023) | `php83Packages.composer` | namespaced; no top-level attribute |
| `wp` | 2.9.0 (Nov 2023) | `wp-cli` | attribute differs from binary |
| `go` | 1.22.1 | `go` (1.26.5) | well behind |
| `sentry-cli` | 2.58.2 | `sentry-cli` (2.58.2) | exact match, clean swap |
| `liquibase` | | `liquibase` | if still used |

**`cdk` is a trap.** The nixpkgs attribute is `aws-cdk-cli`. Plain `cdk` in
nixpkgs is the Curses Development Kit, an unrelated library. Relevant given the
CDK conventions in CLAUDE.md.

### Do not remove `/usr/local/bin/node`

It looks like a redundant third Node, shadowed by the declared `nodejs_22`, and
an obvious cleanup target. **It is load-bearing.** The Homebridge root daemon
hard-codes that exact absolute path:

```
/usr/local/bin/node /opt/homebrew/lib/node_modules/homebridge-config-ui-x/dist/bin/hb-service.js run -I -U /Users/jose/.homebridge
```

Deleting it silently kills Homebridge at its next restart. Annotate it before
anyone tidies loose binaries.

### npm globals (21) and yarn globals (5)

The npm tree at `/opt/homebrew/lib/node_modules` is orphaned from the deleted
brew `node` but still shimmed onto PATH ahead of `/usr/local/bin`. In nixpkgs
and worth moving: `typescript`, `typescript-language-server`, `prettier`,
`intelephense`, `vscode-langservers-extracted`, `http-server`, `turbo`, `yo`,
`mapscii`, `aws-cdk` (as `aws-cdk-cli`).

Worth noting: **`intelephense` is installed here as an npm global**, a PHP
language server, while VS Code has no PHP extension at all. Those two facts
sit oddly together and suggest the PHP tooling story is split across editors.

Stale duplicates to drop: `@anthropic-ai/claude-code` 2.0.8 (the live copy is
`~/.local/bin/claude` 2.1.226), `vscode-json-languageserver` (redundant with
`vscode-langservers-extracted`), and `corepack` 0.17.1.

yarn globals live at `~/.config/yarn/global` from the old brew yarn, not the
Nix yarn's `~/.local/share/yarn/global`, which is empty. `aws-cdk` there is the
`cdk` that actually wins on PATH. `create-next-app`, `create-playwright`, and
`create-vite` are one-shot scaffolders better served by `npx`.

`composer global` has `tightenco/takeout`, not in nixpkgs, leave it. `gem`,
`cargo`, `go`, `pipx`, and `uv tool` have nothing user-installed.

### One thing that needs you

`/usr/local/bin/1password-mcp` is a root-owned symlink, mode `lrwx------`, and
its target cannot be read without elevation. The auditor correctly declined to
escalate. If you want it identified, that needs a `sudo ls -l` from you.

---

## Disk, a separate concern

Not reproducibility, but the disk is at 97% and this surfaced during the audit.

### Caches and state (safe to clear, will regenerate)

| Path | Size |
|---|---|
| `~/.cache` | **34 GB** |
| `~/.npm` | **29 GB** |
| `~/.Trash` | **19 GB** |
| `~/.m2` | 3.9 GB |
| `~/.android` | 3.7 GB |
| `~/.local` | 2.1 GB |
| `~/.gradle` | 2.0 GB |
| `~/.docker` | 1.8 GB |
| `~/.codex` | 1.1 GB |
| `~/.minikube` | 785 MB |
| `~/.bun` | 384 MB |

Those top three are **82 GB**. Emptying the Trash alone reclaims 19 GB, and
`npm cache clean --force` another 29 GB, with no consequence beyond slower
first installs. Against 44 GB free on a 927 GB disk, this is the fastest
possible win and needs no config change at all.

The table above is the 2026-08-09 snapshot, kept as written. Two of those three
were cleared on 2026-08-10 for 45 GB back; see "Suggested order" below for the
current numbers and for what is left in `~/.cache`.

### Orphaned by uninstalled software

| Path | Left behind by | Size |
|---|---|---|
| `~/.ScreamingFrogSEOSpider` | Screaming Frog, app absent | **1.6 GB** |
| `~/.homebridge/homebridge.log` | Homebridge, unrotated and **still growing** | **396 MB** |
| `~/.sts4` | Spring Tools 4 | 11 MB |
| `~/.cursor-tutor` ×3 | Cursor tutorial, Cursor not installed | 1.5 MB |
| `~/.ServiceHub`, `~/.config/Microsoft*`, `~/.config/xbuild` | Visual Studio for Mac, discontinued | 2 MB |

Note the Homebridge log implies **Homebridge is still running**, via a
brew-installed `hb-service` that is not declared in `configuration.nix`. That
is the one remaining undeclared service now that goku is declared, and the log
needs rotation regardless.

**That inference was wrong, and Homebridge is gone as of 2026-08-12.** A large
unrotated log meant it had run, not that it was running: the daemon was loaded
but not up, and the log had stopped at 529 MB. Nothing needed rotating, and the
whole install was removed instead. Also note `hb-service` was not
brew-installed as stated here; it was an npm global living under Homebrew's
prefix, which is why `homebrew.brews` could never have declared it. See
"Suggested order" for the removal record.

Smaller orphans: `.zowe`, `.gk`, `.continue`, `.zlua`, `.putty`, `.knime`,
`.vnc`, `.vim`, `.viminfo`, `.hgignore_global`, `.gitflow_export` (points at
an uninstalled Sourcetree), `~/.config/fish/` (a conda block plus dead Fig
hooks), `~/.config/bpytop/` (replaced by btop), `~/.config/github-copilot/`,
`~/.config/git/ignore.hm-bak` (migration leftover), and the AeroSpace pair.

**`~/.tcshrc` and `~/.xonshrc` both contain `conda init` blocks** pointing at
the deleted `~/anaconda3`. Same class as the `~/.bash_profile` removed on
2026-08-09 and missed at the time because only bash and zsh were checked.

Cruft: six stale `.zcompdump*` files including one from a **different machine**
(`jose-m1.local`), two `.zshrc` backups, three `.claude.json` backup and temp
files (one of them 0 bytes).

---

## Suggested order

Rewritten 2026-08-10. Tiers 1, 2 and 3 are done, so what follows is only what
remains.

**Disk: mostly DONE 2026-08-10.** It first got worse, dropping to 24 GB free at
98 percent, then the Trash was emptied and `npm cache clean --force` was run.
That reclaimed 45 GB: `~/.npm` went 29 GB to 1.7 GB, `~/.Trash` 19 GB to zero,
and the disk went to **69 GB free at 93 percent**.

What remains is `~/.cache` at 35 GB, of which **31 GB is `~/.cache/uv/archive-v0`**,
uv's unpacked-wheel store. Worth knowing before clearing it: uv hardlinks from
that store into virtualenvs, so entries a venv still references would survive
deletion with the space unreclaimed. A full scan for files with a link count
above 1 found zero, so the cache does own its data here. On APFS uv can also
clone blocks, where the link count stays 1 while space is still shared, so treat
31 GB as an upper bound rather than a guarantee. `uv` itself is declared in
`packages.nix` and is unaffected either way.

**Do not clear it with `--force` while the MCP servers are up.** An attempt on
2026-08-10 failed: `uv cache prune` sat 300 seconds on `~/.cache/uv/.lock` and
timed out, because 28 `uv` processes hold that lock. Those are the Claude Code
MCP servers, and `lsof` shows more than a lock. Their Python interpreters have
`.so` files open as `txt`, mapped straight out of `~/.cache/uv/archive-v0`. The
cache is an execution root for live processes here, not just a store of
downloads, so `--force` would delete files out from under running programs.

That also corrects the hardlink reasoning above. The scan was accurate but it
was answering the wrong question: what makes deletion unsafe is not a link
count, it is a process executing from the directory. Clear the cache with
Claude Code and the MCP servers stopped, or leave it. At 66 GB free it is no
longer urgent.

Then, roughly in order of value:

1. **`programs.fzf`. DONE 2026-08-10.** The one item here that deleted config
   rather than adding any. Three hand-written `FZF_*` variables, a manual
   `eval "$(fzf --zsh)"` duplicated across `darwin/extras.nix` and
   `linux/default.nix`, and a quoting workaround all collapsed into the module.

   Three things moved, none of them changing what fzf does. The exports went
   from `programs.zsh.sessionVariables` to `home.sessionVariables`, which is a
   different part of the same `~/.zshenv` and still ahead of `~/.zshrc`. The
   integration went from the tail of the `mkOrder 1100` block to the module's
   `mkOrder 910`, so it now precedes those bindkeys. And it gained a
   `[[ $options[zle] = on ]]` guard plus an absolute store path, so it skips
   non-interactive shells and no longer depends on PATH.

   The ordering move was checked by running the generated `zshrc`, not by
   reasoning about it: all four widgets bind, on Tab, `^R`, `^T` and alt-c.

   Two things this section got wrong. It said five variables; there were three.
   And it said `fzf` was "already declared as a package on both machines" as if
   that made the package entries interchangeable. On darwin the entry in
   `packages.nix` has to stay even though the module also adds fzf to
   `home.packages`: `environment.systemPath` carries the per-user profile as the
   literal `/etc/profiles/per-user/$USER/bin`, expanded by the shell, so any
   context without `USER` set resolves it to `/etc/profiles/per-user//bin` and
   finds nothing. The launchd-started tmux server is such a context and
   tmux-fzf needs fzf on PATH. Same trap as the MANPATH false alarm recorded
   below.

2. **The four remaining known issues** in `docs/nix-reproducibility-review.md`.
   **Three fixed and one partly fixed, 2026-08-11.** The dead
   `select-bsp-layout` binding is gone and `mod1+b` is free. The Paw and React
   Native Debugger entries are out of `hsapp_list`, freeing `d` and `p`.
   `chain.lua`'s `lastSeenAt` is `local` and seeded to `0`.

   The `_G` item is deliberately only part done. `lrsplits`, `tbsplits` and
   `bundleId` are now `local`. `positions`, `currentLayout`, `layouts` and the
   16 functions in `helpers.lua` stay global: `helpers.lua` is loaded by a bare
   `require` that returns nothing, so its 114 call sites resolve only through
   `_G`, and converting it buys no behaviour for a large mechanical change that
   nothing here can verify beyond a parse and a reload. See the review doc for
   the full reasoning.

   Worth noting the review doc had the `chain.lua` diagnosis wrong, and this
   entry repeated it. Undeclared globals returning nil is not what made that
   line safe, since comparing nil to a number raises in Lua. It was `or`
   short-circuiting past the comparison on the first call.

3. **`~/.tcshrc`, `~/.xonshrc` and `~/.config/fish/`.** All three hold nothing
   but dead blocks: `conda init` stanzas pointing at the `~/anaconda3` deleted
   on 2026-08-09, and, in `fish/conf.d/`, two Amazon Q hooks calling the
   `~/.local/bin/q` removed with Amazon Q. Neither fish nor xonsh is installed.
   The tcsh one is the only one with any live effect, since its `else` branch
   prepends the missing `~/anaconda3/bin` to PATH in tcsh sessions.

   Same class as the `~/.bash_profile` removed on 2026-08-09 and missed because
   only bash and zsh were checked. The fish directory was found only by
   sweeping every shell's rc file rather than the two in use.

   **DONE 2026-08-11.** All three removed. A sweep of every shell rc file in
   `$HOME` afterwards found no remaining `conda` reference, so anaconda is now
   fully out of shell startup.

4. **The broken shims in `/opt/homebrew/bin`.** Recounted 2026-08-11: it is
   **52, not 64**, and the discrepancy is not explained by anything removed
   since. `/usr/local/bin`, the obvious candidate for the extra 12, has zero.
   Treat the original number as unreliable.

   The count also hid a distinction that changes the fix. 51 are regular files
   that pip wrote straight into `/opt/homebrew/bin`, so brew does not own them
   and deleting them is correct. One, `runant.py`, is a symlink into
   `../Cellar/ant/1.10.17/bin/`, owned by the `ant` formula this repo declares.
   Its shebang is `/usr/bin/python`, the Python 2 Apple removed, so it is
   equally broken, but hand-deleting it fights brew and it would return on the
   next reinstall. Leave it: nothing invokes `runant.py`, the `ant` entry point
   is the `ant` script, and it is broken upstream rather than here.

   Breakdown of the 51: 46 dead `python@3.11`, 5 dead `python@3.14`. All
   confirmed failing with "bad interpreter", not merely suspected.

   `poetry` resolved: **not worth declaring.** Two projects reference it,
   `screenshot-to-code` and `screenshot-to-code-jose`, whose last commits are
   2025-07-27 and 2024-12-26. Both dormant, and it is one line in
   `packages.nix` or a `nix shell nixpkgs#poetry` away if that changes.
   Deleting the shim turns "bad interpreter" into "command not found", which is
   the clearer failure of the two.

5. **`programs.vscode`.** The largest remaining block, but it wants a decision
   first: the 54 extensions are Java, Spring, .NET and mainframe weighted, with
   no PHP extension at all on a PHP machine. Prune before declaring rather than
   faithfully reproducing a stale set. Several IDs are marketplace-only and
   absent from `nixpkgs.vscode-extensions`, so a faithful declaration realistically
   needs the `nix-vscode-extensions` flake input.

6. **`masApps`, 15 Mac App Store apps.** Lowest value: `mas` can only redownload
   what is already tied to the Apple ID, so it automates reinstall rather than
   capturing state.

**Homebridge and FileZilla: REMOVED 2026-08-12.** Both were undeclared daemons,
and the decision was to drop them rather than declare them. FileZilla went
entirely, client as well as server.

Removed: two `/Library/LaunchDaemons` plists
(`com.homebridge.server`, `org.filezilla-project.filezilla-server.service`),
`FileZilla Server.app` and `FileZilla.app`, three npm packages under
`/opt/homebrew/lib/node_modules` with their three `bin` symlinks, and the data at
`~/.homebridge`, `~/.config/filezilla`, `/Library/Preferences/org.filezilla-project.filezilla-server.service`
and the client plist. About 563 MB. Configs were backed up first, minus the log.

Three things the audit had wrong or that caught us out:

- **Homebridge was not running,** contrary to the entry below claiming the
  396 MB log implied a live service. The daemon and its interpreter were both
  present, it simply was not up, so the log had stopped growing. It reached
  529 MB before stopping.
- **`npm uninstall -g` could not remove those packages.** `npm` on PATH is the
  nix one, whose global prefix is inside the read-only nix store, so the
  uninstall failed with EACCES on `mkdir` without ever looking at
  `/opt/homebrew`. The packages had been installed by the old Homebrew node,
  whose npm no longer exists. Deleting the three directories and three symlinks
  directly was the fix. Anything else installed by that vanished npm will need
  the same treatment.
- **Do not read `df` straight after a large delete on APFS.** The removal script
  did, and reported 68 MB reclaimed. Another 495 MB appeared once APFS caught
  up. There was no snapshot pinning anything; space reclamation is just
  asynchronous.

One leftover, deliberately not touched: `/usr/local/bin/node`, a root-owned
220 MB standalone from February 2025 that only the Homebridge daemon referenced.
Nothing in this repo points at it now.

## What this document got wrong

Worth recording, because the same mistakes are easy to repeat.

Two Dock values here were wrong in a way that would have silently changed the
machine rather than erroring: both folders were recorded as grid view sorted by
name, and they are fan and date-added. `system.defaults` is enforced, so a wrong
value reconfigures rather than fails. Every value actually declared was re-read
off the running system instead of taken from here.

The `persistent-others` syntax suggested here does not type-check; entries need
`folder = { ... }` tagging.

The activation-script advice named `system.activationScripts.postUserActivation`,
which nix-darwin has removed and now asserts on, because all activation runs as
root. The working form is `postActivation` plus the same
`launchctl asuser ... sudo --user=` wrapper nix-darwin uses internally.

The claim that `brew leaves` omits tap formulae was recorded as unproven here and
is now confirmed: `brew uses --installed themekit` throws "Refusing to load
formula from untrusted tap". An earlier test used `brew info`, which loads
formulae by a different path and succeeds, producing a false negative.

**The MANPATH conclusion referenced above was wrong twice.** It was first
reported as broken, which was a test artifact: `env -i` dropped `USER`, so
`/etc/profiles/per-user/$USER/bin` expanded to a path with an empty component.
It was then recorded as fine, which is also untrue. Checked properly on
2026-08-12: `man home-configuration.nix` does fail with "No manual entry",
because the per-user profile's `share/man` is not on the default `manpath`. The
page is installed, at
`/etc/profiles/per-user/$USER/share/man/man5/home-configuration.nix.5`, and
reading it requires passing that path directly.

A second trap sits behind the first. Even with the right file, `grep` for an
option name returns nothing, because `man` sets option names in bold using
overstrike sequences. `man <path> | col -b | grep 'programs\.direnv'` finds 13
matches where the same grep without `col -b` finds zero. That is a good way to
conclude a module does not exist when it does. `docs/nix-conventions.md`
documents the working invocation and prefers a `nix eval` existence check, which
has neither problem.
