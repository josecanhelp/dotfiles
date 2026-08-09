# Reproducibility audit

**Date:** 2026-08-09
**Scope:** everything on this Mac that a fresh machine would not get from
`darwin-rebuild switch`.
**Status:** findings only. Nothing here has been acted on.

## The headline

| | Count |
|---|---|
| Applications installed | 111 |
| Declared as casks | 13 |
| Mac App Store, undeclared | 13 |
| Direct download with an official cask available | 60 |
| Direct download with no cask | ~20 |

The 13 declared casks exactly match the 13 installed casks, with no drift in
either direction. That part of the config is correct and complete. The gap is
everything else: **60 applications could be declared today and are not.**

Four things are already broken or will break on next login. Those come first.

---

## Tier 1: broken, or breaks on a fresh machine

### 1. The goku LaunchAgent is running on borrowed time

`~/Library/LaunchAgents/homebrew.mxcl.goku.plist` runs
`/opt/homebrew/opt/goku/bin/gokuw`, which no longer exists. The packages
migration moved goku to Nix and removed the Homebrew formula.

`launchctl list` shows it with PID 7508, so it is running right now. It
survives only because the process started at login while the old binary still
existed. **It will not come back after the next reboot.**

`gokuw` is the watcher that recompiles `karabiner.edn` into `karabiner.json`
on save. Without it, edits to `karabiner.edn` silently stop taking effect and
`goku` has to be run by hand.

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

If php-fpm is actually wanted, it should be declared, not left to Homebrew.

### 3. Dangling `~/.aerospace.toml`

Symlink dated 2025-08-13 pointing at
`/Users/jose/dotfiles/aerospace/aerospace.toml`, deleted when AeroSpace was
removed. dotbot created it, so home-manager never owned it and never cleaned
it up. Harmless but confusing. `rm ~/.aerospace.toml`.

This is worth a general note: **dotbot-era symlinks in `$HOME` are invisible
to home-manager.** Anything dotbot linked that home-manager does not now
declare will sit there dangling forever. This is the only one found.

### 4. Four Homebrew formulae are used but not declared

`brew leaves --installed-on-request` and the `homebrew.brews` list in
`configuration.nix` are **disjoint sets**.

Installed but not declared: `ant`, `pipx`, `pytorch`, `ruby`.

These are the documented exceptions in `packages.nix`, but they are documented
in a *comment* explaining why they are not in nixpkgs. Nothing actually
installs them. A fresh machine gets none of them.

Declared but absent from `brew leaves`: `themekit`, `ecsplorer`,
`msodbcsql17`. These are fine. `brew leaves` omits third-party tap formulae,
which is the same blind spot that hid tools from an earlier audit. They are
installed and on `PATH`.

Fix: add the four to `homebrew.brews` so the exception is enforced rather than
merely described.

### 5. Hostname is assumed, never set

`flake.nix` keys its configuration on `REM-JoseS-MBP1`, and
`scutil --get ComputerName` currently returns that. But `configuration.nix`
contains no `networking.*` settings, so the flake does not *set* the hostname,
it only *requires* it. On a fresh machine `darwin-rebuild switch --flake
.#REM-JoseS-MBP1` fails until the hostname is set by hand first.

```nix
networking.computerName = "REM-JoseS-MBP1";
networking.hostName = "REM-JoseS-MBP1";
networking.localHostName = "REM-JoseS-MBP1";
```

---

## Tier 2: applications

The single largest win. 60 apps have an official cask and are installed by
direct download today.

### Exact-match casks (50)

Verified against the Homebrew cask index (7,687 casks, 4,143 app artifacts),
matched on the app bundle name rather than guessed.

```
1password              balenaetcher           bambu-studio
brave-browser          cap                    chatgpt
claude                 codex-app              cool-retro-term
cyberduck              dbeaver-community      dbngin
discord                docker-desktop         dropbox
eclipse-cpp            epic-games             figma
firefox@developer-edition                     fork
google-chrome          hammerspoon            handbrake-app
imageoptim             istat-menus            ledger-wallet
local                  minecraft              monologue
mysqlworkbench         obs                    obsidian
openshot-video-editor  raspberry-pi-imager    responsively
screenflow             shottr                 sizzy
sketch                 slack                  sublime-text
tableplus              transmit               trezor-suite
tunnelblick            visual-studio-code     visual-studio
vlc                    wireshark-app
```

Note `iterm2` also appeared in this list. It is already declared; the app
bundle is named `iTerm` so a name match flags it spuriously. Ignore it.

### Casks under a different app name (10)

Found by searching the index rather than exact-matching:

| App(s) | Cask |
|---|---|
| Karabiner-Elements, Karabiner-EventViewer | `karabiner-elements` |
| Excel, Word, PowerPoint, OneNote, Outlook | `microsoft-office` |
| Microsoft Teams | `microsoft-teams` |
| OneDrive | `onedrive` |
| NordVPN | `nordvpn` |
| VirtualBox | `virtualbox` |
| zoom.us | `zoom` |
| DisplayLink Manager | `displaylink` |
| Company Portal | `intune-company-portal` |
| iZotope Product Portal | `izotope-product-portal` |

One cask covers five Office apps, and `karabiner-elements` covers two. Karabiner
is worth doing early since its config is already version controlled here.

### Mac App Store (13)

nix-darwin supports these via `homebrew.masApps`, which needs the `mas`
formula. `mas` is **not currently installed**. IDs resolved from Spotlight
metadata:

```nix
homebrew.masApps = {
  "1Password for Safari" = 1569813296;
  "BreakTime" = 427475982;
  "DaisyDisk" = 411643860;
  "GIPHY CAPTURE" = 668208984;
  "iMovie" = 408981434;
  "Keynote" = 409183694;
  "Microsoft Remote Desktop" = 1295203466;
  "Microsoft To Do" = 1274495053;
  "Pixelmator Pro" = 1289583905;
  "Swift Playground" = 1496833156;
  "TestFlight" = 899247664;
  "Toggl Track" = 1291898086;
  "Xcode" = 497799835;
};
```

Caveat: `masApps` only reinstalls apps already tied to the Apple ID, and `mas`
cannot sign in to the App Store on modern macOS. It automates redownload, not
first purchase.

### No cask available (~20)

Not declarable. Listed so nobody re-audits them later.

| App | Why |
|---|---|
| Safari, SF Symbols | Apple |
| Microsoft Defender, Remote Help, 365 Copilot | IT-managed, likely via Intune |
| Google Docs / Drive / Sheets / Slides | Chrome PWA shortcuts, not real apps |
| FileZilla, FileZilla Server | no cask |
| VMware Fusion | no cask; Broadcom changed distribution |
| Exodus, Parkwest Casino, Splitscreen | no cask |
| Advantage 360 SmartSet App | Kinesis keyboard config utility |
| Blackmagic Proxy Generator Lite | vendor download |
| iZotope RX 7 | installed by iZotope Product Portal |

---

## Tier 3: configuration candidates

Not yet investigated in depth. Listed as leads.

- `~/.config/` is 215 MB and was not enumerated per-entry. Most is app state,
  but it is where modern tools put real config and is the best place to look
  for further `programs.*` wins.
- `~/.gitignore_global`, `~/.mailmap`, `~/.prettierrc`, `~/.npmrc`, `~/.yarnrc`
  are all small, real, user-authored config sitting untracked in `$HOME`.
  Good candidates for `home.file` or the relevant `programs.*` module.
  `programs.git` can absorb the global gitignore directly.
- VS Code is installed. `programs.vscode` can declare extensions and settings.
  Extension list not captured.
- `composer global` has `takeout`. Not declared.
- `~/.gem` exists with user gems. Not enumerated.

## Not audited

Be honest about the gaps in this document:

- **macOS `system.defaults`.** Not surveyed. `configuration.nix` declares some
  dock, finder, NSGlobalDomain, and screencapture settings; whether the machine
  has further deliberate customisation is unknown. This needs nix-darwin's own
  `modules/system/defaults/` read first to establish which options exist,
  because guessed option names fail at build time.
- **`~/.config/` per-entry classification.**
- **VS Code extensions and JetBrains config.**
- **Login items** beyond LaunchAgents.

---

## Disk, a separate concern

Not reproducibility, but the disk is at 97% and this surfaced during the audit.

| Path | Size | Notes |
|---|---|---|
| `~/.cache` | 34 GB | by far the largest single item |
| `~/.m2` | 3.9 GB | Maven |
| `~/.android` | 3.7 GB | |
| `~/.gradle` | 2.0 GB | |
| `~/.local` | 2.1 GB | |
| `~/.docker` | 1.8 GB | |
| `~/.codex` | 1.1 GB | |
| `~/.minikube` | 785 MB | |
| `~/.homebridge` | 401 MB | Homebridge is not installed |
| `~/.bun` | 384 MB | |
| `~/.claude` | 368 MB | |

Plus small orphaned state from software that is gone: `.eclipse`, `.p2`,
`.sts4`, `.oracle_jre_usage`, `.knime`, `.putty`, `.vnc`, `.mono`, `.redhat`,
`.ServiceHub`, `.templateengine`, `.installbuilder`, `.nemo`, `.ipython`,
three copies of `.cursor-tutor` (Cursor is not installed), `.vim` and
`.viminfo` (nvim is the editor now).

Also cruft: seven stale `.zcompdump*` files including one from a previous
hostname `jose-m1.local`, two `.zshrc` backups, and three `.claude.json`
backup/temp files.

`~/.cache` alone would take the disk from 97% to about 93%.

---

## Suggested order

1. **Tier 1 items 1 and 2.** goku is a live regression with a known fix.
2. **Tier 1 items 4 and 5.** Two small edits that make a fresh machine viable.
3. **Karabiner and the dev-tool casks.** Highest value per line: the config is
   already in this repo, the app is not.
4. **The remaining 50-odd casks**, in batches, verifying each activates.
5. **masApps**, which needs `mas` added to `homebrew.brews` first.
6. **Tier 3 config**, once the app layer is done.

Casks can be added in batches and are low risk: `homebrew.onActivation.cleanup`
is `"none"`, so declaring an already-installed app is a no-op rather than a
reinstall.
