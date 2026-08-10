# launchd declarative, and removing PHP (sub-project 5)

**Date:** 2026-08-09
**Status:** Approved, not yet implemented
**Repo:** `~/dotfiles`, branch `main`

## Goal

Declare the three launchd jobs this machine actually needs, delete the three
broken ones it has, and remove global PHP.

## Context

`docs/reproducibility-audit-2026-08-09.md` found three broken launchd jobs.
All three were invisible to `brew services list`, which returns empty with
exit 0. That is precisely why they survived a four-part migration unnoticed.

Nothing under `nix/` declares any launchd job today.

### The three broken jobs

**goku.** `~/Library/LaunchAgents/homebrew.mxcl.goku.plist` runs
`/opt/homebrew/opt/goku/bin/gokuw`, deleted with the formula when goku moved to
Nix. Both processes are still alive:

```
7508  /bin/sh /opt/homebrew/opt/goku/bin/gokuw
7532  watchexec -r -e edn -w /Users/jose/.config/karabiner.edn goku
```

but PID 7532's environment is
`PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin`, and
neither `goku` nor `watchexec` exists on it. Verified rather than inferred:

```
$ env -i PATH="/opt/homebrew/bin:...:/sbin" sh -c 'command -v goku'
goku: NOT FOUND on this PATH
```

So the watcher runs but cannot execute the command it exists to run.
`karabiner.edn` auto-compilation is dead now, not at the next reboot. It is
latent only because the `.edn` has not been edited since 2026-01-01.

There is also a duplicate root-owned
`/Library/LaunchDaemons/homebrew.mxcl.goku.plist` in a failing respawn loop,
`last exit code = 78: EX_CONFIG`.

`~/Library/Logs/goku.log` holds 4.3 million lines of
`gokuw: line 2: watchexec: command not found`.

**php@8.1.** `homebrew.mxcl.php@8.1.plist` targets a php-fpm that is gone. Not
loaded, not scheduled. Inert since Oct 2023.

**Tmux.Start.** Registered in the user domain with no backing file in
`~/Library/LaunchAgents`, because tmux-continuum registers it dynamically. Its
program is `~/.tmux/plugins/tmux-continuum/.../osx_alacritty_start_tmux.sh`, a
tpm path deleted when tmux plugins moved to nixpkgs. `LastExitStatus = 1`,
failing at every login.

### How continuum's boot agent works

Read from the pinned plugin source, not assumed:

- `continuum.tmux:68` calls `handle_tmux_automatic_start` when the plugin loads.
- With `@continuum-boot on`, `osx_enable.sh` writes
  `~/Library/LaunchAgents/Tmux.Start.plist` with
  `ProgramArguments = [<plugin dir>/osx_alacritty_start_tmux.sh, "fullscreen"]`.
- With it off, `osx_disable.sh` deletes that same file.

The nixpkgs plugin **does** ship the script, at
`${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/handle_tmux_automatic_start/osx_alacritty_start_tmux.sh`.

**Unresolved.** `@continuum-boot on` is set in the running server and the
plugin calls the enable path on load, yet the plist does not exist. Either the
enable path is failing silently or the running server predates the plugin
switch. Determining which requires restarting the tmux server, which would kill
the session doing the work. This does not change the design: declaring the
agent is more reliable than depending on a self-heal that cannot be observed.

## Decisions

**Skip the `gokuw` wrapper.** It is a two-line shell script that calls
`watchexec` and `goku` by bare name, and that bare-name lookup is the actual
defect. Declaring `gokuw` with a patched `EnvironmentVariables.PATH` would work
but preserves the fragility. Declaring the `watchexec` invocation directly with
absolute store paths removes the failure mode entirely.

**Use home-manager's `launchd.agents`, not nix-darwin's `launchd.user.agents`.**
Both produce user agents. home-manager already owns `$HOME` in this repo, and
its activation handles teardown when an agent is removed. Verified against the
pinned source (`d4fd246`): `launchd.agents.<name>.{enable,config}`, label
defaults to `org.nix-community.home.<name>`, written to
`~/Library/LaunchAgents/`.

**`@continuum-boot` goes to `off`.** Leaving it `on` alongside a declared agent
means two agents both launching Alacritty at login. Setting it off makes
continuum delete its own `Tmux.Start.plist` through `osx_disable.sh`, so it
cleans up after itself while the declared agent takes over under a different
label. `@continuum-restore` and the resurrect settings stay untouched.

**Accepted cost:** `osx_alacritty_start_tmux.sh` drives `osascript` and System
Events keystrokes, which needs Accessibility permission. The program is a
`/nix/store` path and macOS keys approvals to the path, so a plugin update may
require re-approving. The user accepted this explicitly in favour of keeping
login auto-start working.

**PHP: drop the runtime, keep the Docker workflow.** `php83` is 253.5 MiB and
there is no local-PHP work happening. The Laravel aliases split cleanly: four
shell out to a local `php artisan` and must go; four go through Laravel Sail
(Docker) and one uses `./vendor/bin`, and none of those five ever needed local
PHP. The `php` treesitter grammar stays so PHP files still highlight in nvim.

**`msodbcsql17` goes with PHP.** It is a SQL Server ODBC driver, present for
PHP's `pdo_odbc`. Dropping it also makes the `microsoft/mssql-release` tap
vestigial, so that goes too.

## Architecture

```
nix/home/karabiner.nix   NEW. The two karabiner.edn links (moved out of
                         default.nix) plus the goku watcher agent.
                         One unit: keyboard remapping.
nix/home/tmux.nix        Gains the boot agent, next to the continuum
                         settings it pairs with.
nix/home/default.nix     Loses the karabiner links, gains the import.
nix/home/shell.nix       Loses four aliases.
nix/packages.nix         Loses php83.
nix/configuration.nix    Loses msodbcsql17 and the mssql-release tap.
nix/verify.sh            Loses `php` from batch4, which would otherwise
                         fail with MISSING on the next run.
```

Agents live with the thing they serve rather than in a `launchd.nix`
grab-bag. The goku agent is meaningless without the karabiner links, and the
tmux agent is meaningless without `@continuum-boot`.

### nix/home/karabiner.nix

```nix
{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  # Both paths, deliberately. Karabiner-Elements reads
  # ~/.config/karabiner/, goku reads ~/.config/karabiner.edn. Dropping
  # either silently stops the .edn from compiling to karabiner.json.
  xdg.configFile."karabiner.edn".source = link "karabiner/karabiner.edn";
  xdg.configFile."karabiner/karabiner.edn".source = link "karabiner/karabiner.edn";

  # Recompile karabiner.edn to karabiner.json on save.
  #
  # This deliberately does NOT invoke goku's own `gokuw` wrapper. gokuw is a
  # two-line shell script that calls `watchexec` and `goku` by bare name, and
  # that bare-name lookup is exactly what broke: the Homebrew LaunchAgent it
  # shipped with gave the job a PATH containing neither binary, so the watcher
  # ran for days without ever being able to compile anything. Absolute store
  # paths make that failure impossible.
  launchd.agents.goku = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.watchexec}/bin/watchexec"
        "-r"
        "-e" "edn"
        "-w" "${config.home.homeDirectory}/.config/karabiner.edn"
        "${pkgs.goku}/bin/goku"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/goku.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/goku.log";
    };
  };
}
```

Label: `org.nix-community.home.goku`.

### The tmux boot agent

Added to `nix/home/tmux.nix`:

```nix
  # Launch Alacritty fullscreen with the restored session at login.
  #
  # Declared here rather than left to continuum's own osx_enable.sh, which
  # writes ~/Library/LaunchAgents/Tmux.Start.plist pointing at whatever
  # directory the plugin happens to live in. That is why the old registration
  # still pointed into ~/.tmux/plugins after tpm was retired, failing with
  # exit 1 at every login.
  #
  # @continuum-boot is off below so continuum deletes its own plist rather
  # than competing with this agent.
  #
  # Note: the script drives osascript and System Events, so it needs
  # Accessibility permission. The program is a store path, and macOS keys
  # those approvals to the path, so a continuum update may require
  # re-approving in System Settings.
  launchd.agents.tmux-boot = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/handle_tmux_automatic_start/osx_alacritty_start_tmux.sh"
        "fullscreen"
      ];
      RunAtLoad = true;
    };
  };
```

And in `extraConfig`, `@continuum-boot` changes from `'on'` to `'off'`, with
`@continuum-boot-options` deleted since it no longer has any effect.

Label: `org.nix-community.home.tmux-boot`.

### PHP changes

`nix/packages.nix`: remove `php83` from the `languages` group.

`nix/home/shell.nix`, remove four aliases:

| Alias | Definition |
|---|---|
| `art` | `php artisan` |
| `artclear` | `php artisan cache:clear && ...` |
| `pad` | `php artisan dusk` |
| `tinkpw` | `php artisan tinker --execute=...` |

Keep `smfs`, `mfs`, `mfss`, `arl` (all Laravel Sail, so Docker) and `phpunit`
(`./vendor/bin/phpunit`). None invoke a local `php`.

`nix/configuration.nix`: remove `"msodbcsql17"` from `brews` and
`"microsoft/mssql-release"` from `taps`.

`nix/home/nvim.nix` is untouched. The `php` treesitter grammar stays.

## Manual cleanup, outside Nix

These are files in `$HOME` and `/Library` that no rebuild will remove:

```sh
# Homebrew launchd leftovers
rm ~/Library/LaunchAgents/homebrew.mxcl.goku.plist
rm ~/Library/LaunchAgents/homebrew.mxcl.php@8.1.plist
sudo rm /Library/LaunchDaemons/homebrew.mxcl.goku.plist

# the stale registration with no backing file
launchctl bootout gui/$(id -u)/Tmux.Start.plist

# 4.3 million lines
rm ~/Library/Logs/goku.log

# orphaned by removing php
rm /usr/local/bin/composer
rm -rf ~/.composer
```

The running goku pair (PIDs 7508 and 7532) must be stopped, or two watchers
will race on the same file. Booting out the old agent handles the supervisor;
the `watchexec` child may need a separate kill.

`brew uninstall msodbcsql17` and `brew untap microsoft/mssql-release` are not
needed: `homebrew.onActivation.cleanup` is `"none"`, so removing the
declaration leaves the formula installed. Uninstalling is a separate, optional
step.

## Verification

A green `nix build` proves nothing about launchd. Every check below is a
runtime check.

**goku**

- `launchctl print gui/$(id -u)/org.nix-community.home.goku` shows `state = running`
- Its `ProgramArguments` are store paths, not `/opt/homebrew`
- **End to end:** `touch ~/dotfiles/karabiner/karabiner.edn`, wait, then confirm
  `~/.config/karabiner/karabiner.json` has a fresh mtime. This is the only check
  that proves the actual bug is fixed, because the old setup also showed a
  running process.
- No process anywhere still references `/opt/homebrew/opt/goku`

**tmux**

- `launchctl print gui/$(id -u)/org.nix-community.home.tmux-boot` loads
- `launchctl list Tmux.Start.plist` returns nothing
- `~/Library/LaunchAgents/Tmux.Start.plist` does not exist and does not come
  back after a tmux server restart
- `tmux show-options -g | grep continuum-boot` shows `off`
- `@continuum-restore` is still `on` and session restore still works
- Log out and back in: Alacritty opens fullscreen with the session restored.
  Expect an Accessibility prompt the first time.

**php**

- `command -v php` returns nothing
- A clean login shell has no `art`, `artclear`, `pad`, or `tinkpw`
- `alias | grep -c artisan` returns 4, the surviving sail aliases
- `phpunit` alias still present
- `nvim` still highlights a `.php` file, proving the grammar survived
- `nix/verify.sh all` passes after `php` is removed from its batch 4 list

**general**

- `launchctl list | grep -c homebrew.mxcl` returns 0
- Built system hash differs from the pre-change one, confirming the change
  actually landed

## Done when

- Three broken launchd jobs are gone, two working ones are declared in Nix
- Editing `karabiner.edn` regenerates `karabiner.json` without manual `goku`
- Logging in opens Alacritty fullscreen with the restored session
- No PHP on the system; the Docker-based Laravel aliases still work
- `docs/reproducibility-audit-2026-08-09.md` Tier 1 items 1, 2, 3 marked done
- `nix/verify.sh` no longer checks for `php`

## Out of scope

- The other Tier 1 items (4 through 9): aerospace symlink, undeclared brews,
  hostname, `notify.sh`, `.nix-profile`, barrier/drawio
- The 64 casks
- Homebridge's undeclared root daemon, and the FileZilla Server daemon
- Uninstalling the `msodbcsql17` formula itself
- Reinstating PHP through a devshell. If per-project PHP is wanted later,
  that is a devshell plus `direnv`, not a global package.
