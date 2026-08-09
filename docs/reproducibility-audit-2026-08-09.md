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
nix-darwin, and five things that are already broken or break on next boot.

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
about whether the applications still exist. See Tier 1 item 6.

---

## Tier 1: broken, or breaks on a fresh machine

### 1. The goku LaunchAgent is running on borrowed time

`~/Library/LaunchAgents/homebrew.mxcl.goku.plist` runs
`/opt/homebrew/opt/goku/bin/gokuw`, which no longer exists. The packages
migration moved goku to Nix and removed the Homebrew formula.

`launchctl list` shows it with PID 7508, so it is running right now. It
survives only because the process started at login while the old binary still
existed. **It will not come back after the next reboot.**

`gokuw` watches `karabiner.edn` and recompiles it into the `karabiner.json`
that Karabiner-Elements actually reads. Without it, edits to `karabiner.edn`
silently stop taking effect and `goku` must be run by hand.

Nix already provides it at `/run/current-system/sw/bin/gokuw`. Fix by
declaring it and deleting the Homebrew plist:

```nix
launchd.user.agents.goku = {
  command = "${pkgs.goku}/bin/gokuw";
  serviceConfig = {
    KeepAlive = true;
    RunAtLoad = true;
    StandardOutPath = "/tmp/goku.out.log";
    StandardErrorPath = "/tmp/goku.err.log";
  };
};
```

### 2. Dead php@8.1 LaunchAgent

`homebrew.mxcl.php@8.1.plist` points at
`/opt/homebrew/opt/php@8.1/sbin/php-fpm`, removed in the migration. Not
loaded. php is now 8.3.32 from Nix. The plist is inert and should be deleted.

### 3. Dangling `~/.aerospace.toml`

Symlink dated 2025-08-13 pointing at
`/Users/jose/dotfiles/aerospace/aerospace.toml`, deleted when AeroSpace was
removed. dotbot created it, so home-manager never owned it and never cleaned
it up.

The general lesson matters more than this one file: **dotbot-era symlinks in
`$HOME` are invisible to home-manager.** Anything dotbot linked that
home-manager does not now declare will dangle forever with no warning.

### 4. Four Homebrew formulae are used but not declared

`brew leaves --installed-on-request` and the `homebrew.brews` list in
`configuration.nix` are **disjoint sets**.

Installed but not declared: `ant`, `pipx`, `pytorch`, `ruby`. These are the
documented exceptions in `packages.nix`, but they are documented in a
*comment* explaining why they are not in nixpkgs. Nothing installs them. A
fresh machine gets none of them.

Declared but absent from `brew leaves`: `themekit`, `ecsplorer`,
`msodbcsql17`. These are fine. `brew leaves` omits third-party tap formulae,
the same blind spot that hid tools from an earlier audit.

### 5. Hostname is assumed, never set

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

### 6. The declared tmux config depends on an undeclared file

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

### 7. `~/.nix-profile` is dangling, and `shell.nix` puts it on PATH

`~/.nix-profile` points at `~/.local/state/nix/profiles/profile`, which does
not exist. Meanwhile `nix/home/shell.nix:231` ends with:

```sh
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
```

That middle entry resolves to nothing. Harmless today because
`/run/current-system/sw/bin` carries everything, but the line is misleading
and `verify.sh:46` accepts `$HOME/.nix-profile/bin/*` as a valid Nix path in a
case that can now never match.

Either remove the entry or fix the profile link. Do not leave it as is: the
next person to debug a PATH problem will lose time on it.

### 8. Two declared casks whose apps are gone

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

Notes on a few:
- `vlc`, `obs`, `virtualbox` are **not** in nixpkgs for aarch64-darwin. The
  cask is the only route.
- `virtualbox` needs a system-extension approval on first install, so it is
  not fully unattended.
- `onedrive` has **two copies installed**: a non-MAS one at
  `/Applications/OneDrive.app` and an older MAS one (25.046.0310) at
  `/Applications/OneDrive.localized/`. Declaring the cask orphans the MAS
  copy. Resolve which one you want first.
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

### Mac App Store (15)

nix-darwin installs `mas` automatically once `homebrew.masApps` is non-empty,
so no manual step is needed.

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
  "OneDrive" = 823766827;
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
casks if you would rather avoid the MAS route entirely. The OneDrive entry
here is the duplicate discussed above.

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

## Not yet reported

Two audits are still outstanding:

- **Global package managers.** Spot check found `composer global` has
  `takeout` and `~/.gem` has user gems; not enumerated properly.
- **Language runtimes, Docker/cloud state, and the VS Code extension ID list.**
  The extension count is known (55), the IDs are not.

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
is a second undeclared service alongside goku, and the log needs rotation
regardless.

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

**Free, immediate, no config change:** empty the Trash and run `npm cache
clean --force`. 48 GB, zero risk. Do this first regardless of everything else.

Then:

1. **Tier 1 items 1, 2, 6.** goku and `notify.sh` are both live regressions
   where declared config depends on something that is gone or was never
   declared. Item 2 is a one-line deletion.
2. **Tier 1 items 4, 5, 7, 8.** Small edits that make a fresh machine viable,
   plus decisions on barrier/drawio and the dangling `.nix-profile` PATH entry.
3. **`karabiner-elements`, `hammerspoon`, `shottr`.** Highest value per line:
   config or login-item entries already exist here, the applications do not.
4. **`programs.fzf` and `~/.mailmap`.** Both small. fzf deletes existing config
   rather than adding any; mailmap starts working for the first time.
5. **The macOS Dock settings.** Biggest single settings gap, one block.
6. **The remaining casks**, in batches, verifying each activation.
7. **`programs.vscode`**, once the extension IDs are resolved.
8. **`masApps`**, after resolving the OneDrive duplicate.
9. **The activation-script settings**, carefully, given the `-dict-add`
   requirement.

A cleanup pass on the junk list is worth folding in wherever convenient; none
of it is urgent, but `~/.tcshrc` and `~/.xonshrc` should go with the rest of
the anaconda removal since they were missed the first time.

Casks are low risk to add in batches: `homebrew.onActivation.cleanup` is
`"none"`, so declaring an already-installed app is a no-op rather than a
reinstall.
