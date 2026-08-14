# launchd declarative and PHP removal: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Declare the two launchd agents this machine needs, delete the three broken ones it has, and remove global PHP.

**Architecture:** Two user agents declared through home-manager's `launchd.agents`, each living beside the config it serves rather than in a shared `launchd.nix`. The goku agent deliberately invokes `watchexec` directly with absolute store paths instead of goku's own `gokuw` wrapper, because that wrapper's bare-name PATH lookup is the defect being fixed.

**Tech Stack:** nix-darwin 26.05, home-manager release-26.05, nixpkgs 26.05 aarch64-darwin, launchd, tmux-continuum from nixpkgs.

## Global Constraints

- `darwin-rebuild switch` requires sudo. **Never run it.** Build locally with `nix build` and hand Jose the exact command.
- Do not push. Commit only.
- Never add co-author trailers to commit messages.
- No em-dashes in any file content or output. Use commas, colons, or parentheses.
- Verification must be **runtime**, not build-time. A green `nix build` proves nothing about launchd. The old goku setup showed a live PID while being completely broken.
- The tool shell has no nix on PATH. Prefix commands with:
  `export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"`
- Nix only reads git-tracked files. `git add` any new file **before** building or the build reports it does not exist.
- Verified facts, do not re-derive: `pkgs.watchexec` is 2.5.1 and already declared at `nix/packages.nix:31`. `pkgs.goku` is 0.8.0. home-manager's option is `launchd.agents.<name>.{enable,config}` and its label defaults to `org.nix-community.home.<name>`.

---

## Task 1: karabiner.nix and the goku watcher

**Files:**
- Create: `nix/home/karabiner.nix`
- Modify: `nix/home/default.nix:11-17` (imports), `nix/home/default.nix:33-38` (remove the `xdg.configFile` block)

**Interfaces:**
- Produces: a launchd agent labelled `org.nix-community.home.goku`, and the two `karabiner.edn` out-of-store links previously owned by `default.nix`.
- Consumes: nothing from other tasks.

- [ ] **Step 1: Record the current state so the fix is provable**

Run:
```bash
export PATH="/run/current-system/sw/bin:$PATH"
stat -c '%y' ~/.config/karabiner/karabiner.json
launchctl list | grep -c "homebrew.mxcl.goku" || true
```
Write both values down. Expected: an mtime of 2026-08-06, and `1`. These are the before-values that Step 10 compares against.

- [ ] **Step 2: Create `nix/home/karabiner.nix`**

```nix
{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  xdg.configFile = {
    # Linked to both paths because goku searches both. Dropping either one
    # silently stops the .edn from compiling to karabiner.json.
    "karabiner.edn".source = link "karabiner/karabiner.edn";
    "karabiner/karabiner.edn".source = link "karabiner/karabiner.edn";
  };

  # Recompile karabiner.edn to karabiner.json on save.
  #
  # This deliberately does NOT call goku's own `gokuw` wrapper. gokuw is a
  # two-line shell script that runs `watchexec` and `goku` by bare name, and
  # that bare-name lookup is exactly what broke: the Homebrew LaunchAgent it
  # shipped with handed the job a PATH containing neither binary, so the
  # watcher ran for days unable to compile anything while still showing a
  # live PID. Absolute store paths make that failure mode impossible.
  launchd.agents.goku = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.watchexec}/bin/watchexec"
        "-r"
        "-e"
        "edn"
        "-w"
        "${config.home.homeDirectory}/.config/karabiner.edn"
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

- [ ] **Step 3: Add the import to `nix/home/default.nix`**

Replace lines 11 to 17:
```nix
  imports = [
    ./git.nix
    ./shell.nix
    ./alacritty.nix
    ./tmux.nix
    ./nvim.nix
  ];
```
with:
```nix
  imports = [
    ./git.nix
    ./shell.nix
    ./alacritty.nix
    ./tmux.nix
    ./nvim.nix
    ./karabiner.nix
  ];
```

- [ ] **Step 4: Remove the karabiner block from `nix/home/default.nix`**

Delete this entire block (it moved to `karabiner.nix`):
```nix
  xdg.configFile = {
    # Linked to both paths because goku searches both. Dropping either one
    # silently stops the .edn from compiling to karabiner.json.
    "karabiner.edn".source = link "karabiner/karabiner.edn";
    "karabiner/karabiner.edn".source = link "karabiner/karabiner.edn";
  };
```

The `link` helper and `dotfiles` binding at the top of `default.nix` stay: `home.file` still uses them for `.hammerspoon`, `.amethyst.yml`, `.hushlogin`, and `.bin`.

- [ ] **Step 5: Track the new file, then build**

Nix will not see an untracked file.
```bash
cd ~/dotfiles
export PATH="/run/current-system/sw/bin:$PATH"
git add nix/home/karabiner.nix nix/home/default.nix
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths
```
Expected: a store path printed, no error. If it says `karabiner.nix` does not exist, Step 5's `git add` was skipped.

- [ ] **Step 6: Confirm the generated plist is correct before activating**

```bash
export PATH="/run/current-system/sw/bin:$PATH"
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>/dev/null | tail -1)
hm=$(nix-store -qR "$out" | grep 'home-manager-files' | head -1)
cat "$hm/Library/LaunchAgents/org.nix-community.home.goku.plist"
```
Expected: a plist whose `ProgramArguments` are `/nix/store/...` paths for both `watchexec` and `goku`. If any argument contains `/opt/homebrew`, stop and fix.

- [ ] **Step 7: Stop the old goku job BEFORE activating**

Doing this after activation would leave two watchers racing on the same file.
```bash
launchctl bootout gui/$(id -u)/homebrew.mxcl.goku 2>/dev/null || true
pkill -f "gokuw" 2>/dev/null || true
pkill -f "watchexec -r -e edn" 2>/dev/null || true
rm -f ~/Library/LaunchAgents/homebrew.mxcl.goku.plist
pgrep -fl "gokuw|watchexec" || echo "no goku processes remain"
```
Expected: `no goku processes remain`.

- [ ] **Step 8: Remove the duplicate root daemon and the oversized log**

The daemon needs sudo, so hand Jose this exact block:
```bash
sudo rm /Library/LaunchDaemons/homebrew.mxcl.goku.plist
sudo launchctl bootout system/homebrew.mxcl.goku 2>/dev/null || true
rm -f ~/Library/Logs/goku.log
```
The log is 4.3 million lines of `watchexec: command not found`. The new agent writes to that same path, so clearing it first makes the next verification readable.

- [ ] **Step 9: Hand Jose the rebuild**

```
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```
Wait for confirmation. Do not proceed until he reports it succeeded.

- [ ] **Step 10: Verify goku end to end**

This is the decisive test. A running process is not evidence; the broken setup had one.
```bash
export PATH="/run/current-system/sw/bin:$PATH"
launchctl print gui/$(id -u)/org.nix-community.home.goku | grep -E "state|program"
before=$(stat -c '%Y' ~/.config/karabiner/karabiner.json)
touch ~/dotfiles/karabiner/karabiner.edn
sleep 5
after=$(stat -c '%Y' ~/.config/karabiner/karabiner.json)
[ "$after" -gt "$before" ] && echo "PASS: karabiner.json regenerated" || echo "FAIL: not regenerated"
cat ~/Library/Logs/goku.log 2>/dev/null | head -5
```
Expected: `state = running`, program paths under `/nix/store`, `PASS: karabiner.json regenerated`, and a log that is either empty or shows goku's own output rather than `command not found`.

If it says FAIL, check the log first. Do not proceed to Task 2.

- [ ] **Step 11: Confirm no Homebrew goku registration survives**

```bash
launchctl list | grep "homebrew.mxcl.goku" && echo "STILL PRESENT" || echo "clean"
```
Expected: `clean`.

- [ ] **Step 12: Commit**

```bash
cd ~/dotfiles
git add nix/home/karabiner.nix nix/home/default.nix
git commit -m "feat: declare the goku watcher, move karabiner config to its own module

The Homebrew LaunchAgent ran /opt/homebrew/opt/goku/bin/gokuw, deleted when
goku moved to Nix. It still showed a live PID, which read as working, but its
child watchexec had a PATH containing neither goku nor watchexec, so
karabiner.edn had not compiled since the migration.

Declares watchexec directly with absolute store paths rather than going
through gokuw. gokuw calls both binaries by bare name, and that lookup is the
defect; patching its PATH would preserve the fragility.

karabiner.nix now owns the two .edn links alongside the agent, since the links
and the watcher are meaningless apart."
```

---

## Task 2: tmux boot agent

**Files:**
- Modify: `nix/home/tmux.nix:49-52` (the continuum settings) and the module body (add the agent)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: a launchd agent labelled `org.nix-community.home.tmux-boot`.

- [ ] **Step 1: Confirm the stale registration is still there**

```bash
launchctl list Tmux.Start.plist 2>&1 | grep -E "LastExitStatus|Program"
```
Expected: `LastExitStatus = 1` and a Program under `~/.tmux/plugins/`. That is the thing being replaced.

- [ ] **Step 2: Flip `@continuum-boot` off in `nix/home/tmux.nix`**

Replace these two lines:
```
      set -g @continuum-boot 'on'
      set -g @continuum-boot-options 'alacritty,fullscreen'
```
with:
```
      # Off deliberately. Continuum's own osx_enable.sh writes
      # ~/Library/LaunchAgents/Tmux.Start.plist pointing at whatever directory
      # the plugin happens to live in, which is why the old registration still
      # pointed into ~/.tmux/plugins long after tpm was retired, failing with
      # exit 1 at every login. The launchd.agents.tmux-boot block below
      # declares the same thing against a store path instead.
      #
      # Setting this off is also what makes continuum run osx_disable.sh and
      # delete its own stale plist, so it cleans up after itself.
      set -g @continuum-boot 'off'
```

`@continuum-restore 'on'` and the `@resurrect-*` settings on the following lines stay exactly as they are.

- [ ] **Step 3: Add the agent to `nix/home/tmux.nix`**

The file's header is already `{ pkgs, ... }:`, which is all this needs. Add this block after the closing `};` of `programs.tmux`, still inside the outer attribute set:

```nix
  # Open Alacritty fullscreen with the restored session at login.
  #
  # The script drives osascript and System Events keystrokes, so it needs
  # Accessibility permission. macOS keys that approval to the program path,
  # and this is a store path, so a continuum update may require re-approving
  # under System Settings, Privacy and Security, Accessibility.
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

- [ ] **Step 4: Build and confirm the script path actually exists**

A store path that does not exist produces an agent that fails exactly like the one being replaced.
```bash
cd ~/dotfiles
export PATH="/run/current-system/sw/bin:$PATH"
git add nix/home/tmux.nix
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>/dev/null | tail -1)
hm=$(nix-store -qR "$out" | grep 'home-manager-files' | head -1)
prog=$(grep -A2 ProgramArguments "$hm/Library/LaunchAgents/org.nix-community.home.tmux-boot.plist" | grep string | head -1 | sed 's/.*<string>//;s|</string>||')
echo "program: $prog"
[ -x "$prog" ] && echo "PASS: script exists and is executable" || echo "FAIL: bad path"
```
Expected: `PASS`.

- [ ] **Step 5: Clear the stale registration**

```bash
launchctl bootout gui/$(id -u)/Tmux.Start.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/Tmux.Start.plist
launchctl list Tmux.Start.plist 2>&1 | head -1
```
Expected: an error saying it could not be found.

- [ ] **Step 6: Hand Jose the rebuild**

```
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```
Wait for confirmation.

- [ ] **Step 7: Verify the agent loaded and continuum stopped fighting it**

```bash
export PATH="/run/current-system/sw/bin:$PATH"
launchctl print gui/$(id -u)/org.nix-community.home.tmux-boot | grep -E "state|program" | head -3
tmux show-options -g 2>/dev/null | grep continuum-boot
ls ~/Library/LaunchAgents/Tmux.Start.plist 2>&1 | head -1
```
Expected: the agent prints, `@continuum-boot off`, and `Tmux.Start.plist` does not exist.

Note `tmux show-options` reads the **running** server, which still has the old value until it restarts. If it shows `on`, that is expected and not a failure; the declared file is what matters. Confirm with:
```bash
grep -A1 "continuum-boot" ~/.config/tmux/tmux.conf | head -3
```

- [ ] **Step 8: Confirm session restore is untouched**

```bash
grep -E "continuum-restore|resurrect-capture" ~/.config/tmux/tmux.conf
ls ~/.tmux/resurrect | wc -l
```
Expected: both settings present, and a non-zero count of resurrect files. Dropping boot must not have touched saving or restoring.

- [ ] **Step 9: Commit**

```bash
cd ~/dotfiles
git add nix/home/tmux.nix
git commit -m "feat: declare the tmux login agent, stop continuum registering its own

Tmux.Start.plist was registered with no backing file, pointing at
~/.tmux/plugins/tmux-continuum, a tpm path deleted when plugins moved to
nixpkgs. It failed with exit 1 at every login and was invisible to a
directory listing because continuum registers it dynamically.

Declares the agent against the nixpkgs plugin's store path instead. Setting
@continuum-boot off is load-bearing twice over: it stops continuum writing a
competing plist, and it makes continuum delete the stale one through
osx_disable.sh.

Session saving and restore are unchanged."
```

**Deferred verification:** the full test is logging out and back in, expecting Alacritty to open fullscreen with the session restored, and an Accessibility prompt the first time. Flag this for Jose rather than forcing a logout.

---

## Task 3: Remove PHP

**Files:**
- Modify: `nix/packages.nix:67` (remove `php83`)
- Modify: `nix/home/shell.nix:102,115,138,141` (remove four aliases)
- Modify: `nix/verify.sh:19` (remove `php` from batch4)
- Modify: `nix/configuration.nix:100` (remove `msodbcsql17`) and the `taps` list (remove `microsoft/mssql-release`)

**Interfaces:**
- Consumes: nothing from Tasks 1 or 2.
- Produces: nothing consumed later.

- [ ] **Step 1: Remove `php83` from `nix/packages.nix`**

Delete the line `    php83` (line 67, between `nodejs_22` and the `# pipx omitted:` comment).

- [ ] **Step 2: Remove the four local-PHP aliases from `nix/home/shell.nix`**

Delete these four lines exactly:
```nix
      art = "php artisan";
      artclear = "php artisan cache:clear && php artisan config:clear && php artisan view:clear && php artisan route:clear";
      pad = "php artisan dusk";
      tinkpw = "php artisan tinker --execute=\"echo bcrypt('password')\" | pbcopy";
```

**Do not touch these five.** They go through Docker or `./vendor/bin` and never needed a local php:
```nix
      phpunit = "./vendor/bin/phpunit";
      smfs = "./vendor/bin/sail artisan migrate:fresh --seed";
      mfs = "sail artisan migrate:fresh";
      mfss = "sail artisan migrate:fresh --seed";
      arl = "sail artisan route:list";
```

- [ ] **Step 3: Remove `php` from `nix/verify.sh`**

Change line 19 from:
```bash
batch4=(php python3 node dotnet yarn ttx)
```
to:
```bash
# php intentionally absent: removed 2026-08-09, no local PHP on this machine.
# The surviving Laravel aliases run through Docker (sail) or ./vendor/bin.
batch4=(python3 node dotnet yarn ttx)
```

- [ ] **Step 4: Remove the ODBC driver and its tap from `nix/configuration.nix`**

Delete this line from `brews`:
```nix
      "msodbcsql17"   # microsoft/mssql-release
```
and this line from `taps`:
```nix
      "microsoft/mssql-release"
```
The tap exists only to supply that formula, so it becomes vestigial.

- [ ] **Step 5: Build**

```bash
cd ~/dotfiles
export PATH="/run/current-system/sw/bin:$PATH"
git add nix/packages.nix nix/home/shell.nix nix/verify.sh nix/configuration.nix
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths
```
Expected: a store path, no error.

- [ ] **Step 6: Confirm php is gone from the built closure before activating**

```bash
export PATH="/run/current-system/sw/bin:$PATH"
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>/dev/null | tail -1)
nix-store -qR "$out" | grep -c "php-with-extensions" || echo "0"
```
Expected: `0`. If it prints 1, something still references php83.

- [ ] **Step 7: Hand Jose the rebuild**

```
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```
Wait for confirmation.

- [ ] **Step 8: Verify with a clean login shell**

The current shell predates the change and carries stale state, so `env -i` is required.
```bash
export PATH="/run/current-system/sw/bin:$PATH"
env -i HOME="$HOME" TERM=dumb /bin/zsh -lic 'command -v php || echo "php: gone"' 2>/dev/null | tail -1
env -i HOME="$HOME" TERM=dumb /bin/zsh -lic 'alias' 2>/dev/null | grep -cE "^(art|artclear|pad|tinkpw)="
env -i HOME="$HOME" TERM=dumb /bin/zsh -lic 'alias' 2>/dev/null | grep -c "sail artisan"
env -i HOME="$HOME" TERM=dumb /bin/zsh -lic 'alias' 2>/dev/null | grep -c "vendor/bin/phpunit"
```
Expected in order: `php: gone`, `0`, `4`, `1`.

- [ ] **Step 9: Confirm nvim still highlights PHP**

The treesitter grammar is deliberately kept.
```bash
export PATH="/run/current-system/sw/bin:$PATH"
printf '<?php\n$x = 1;\n' > /tmp/hl-test.php
nvim --headless "+edit /tmp/hl-test.php" "+lua print(vim.treesitter.language.get_lang('php'))" +qa 2>&1 | tail -2
rm -f /tmp/hl-test.php
```
Expected: prints `php`, no error.

- [ ] **Step 10: Run the full verification script**

```bash
cd ~/dotfiles && bash nix/verify.sh all 2>&1 | tail -5
```
Expected: `PASSED`. If it reports `MISSING php`, Step 3 was skipped.

- [ ] **Step 11: Remove the orphaned composer and the dead php plist**

Composer is shebanged `#!/usr/bin/env php` and cannot run now.
```bash
sudo rm -f /usr/local/bin/composer
rm -rf ~/.composer
rm -f ~/Library/LaunchAgents/homebrew.mxcl.php@8.1.plist
command -v composer || echo "composer: gone"
```
Expected: `composer: gone`.

`msodbcsql17` stays installed in Homebrew because `onActivation.cleanup` is `"none"`. Uninstalling it with `brew uninstall msodbcsql17 && brew untap microsoft/mssql-release` is optional and separate.

- [ ] **Step 12: Commit**

```bash
cd ~/dotfiles
git add nix/packages.nix nix/home/shell.nix nix/verify.sh nix/configuration.nix
git commit -m "feat: remove global PHP

php83 was 253 MB of runtime for work that now happens in Docker. Drops the
four aliases that shell out to a local php artisan (art, artclear, pad,
tinkpw) and keeps the five that do not: the four Sail aliases run through
Docker and phpunit runs ./vendor/bin.

The php treesitter grammar stays, so PHP files still highlight in nvim.

msodbcsql17 goes too. It is a SQL Server ODBC driver present for PHP's
pdo_odbc, and it was the only formula from microsoft/mssql-release, so the
tap goes with it.

verify.sh loses php from batch4, which would otherwise fail with MISSING."
```

---

## Task 4: Update the audit and review docs

**Files:**
- Modify: `reproducibility-audit-2026-08-09.md` (Tier 1 items 1, 2, 3)
- Modify: `docs/nix-reproducibility-review.md` (Tier 3 sub-project list)

**Interfaces:**
- Consumes: the completed state of Tasks 1 through 3.
- Produces: nothing.

- [ ] **Step 1: Mark Tier 1 items 1, 2 and 3 done in the audit**

In `reproducibility-audit-2026-08-09.md`, change the three headings to strike through the title and append the resolution, matching the style already used in `../nix-reproducibility-review.md`:

```markdown
### 1. ~~goku is already broken, not "will break"~~ FIXED 2026-08-09
```
```markdown
### 2. ~~Dead php@8.1 LaunchAgent~~ FIXED 2026-08-09
```
```markdown
### 3. ~~A third broken launchd job, from our own tmux migration~~ FIXED 2026-08-09
```

Under each, add one line stating what was done. For item 1: `Replaced by launchd.agents.goku in nix/home/karabiner.nix, invoking watchexec directly with store paths. Both Homebrew registrations and the 4.3M-line log removed.` For item 2: `Plist deleted. PHP removed from the system entirely in the same sub-project.` For item 3: `Replaced by launchd.agents.tmux-boot in nix/home/tmux.nix; @continuum-boot set off so continuum deletes its own plist.`

Leave items 4 through 9 untouched.

- [ ] **Step 2: Update the headline count**

The summary currently reads `**nine** things that are already broken or that break on a fresh machine. Three of the nine are launchd jobs failing silently right now.` Change it to:

```markdown
nix-darwin, 54 undeclared VS Code extensions, and nine things that are already
broken or that break on a fresh machine. **Three of the nine, all launchd jobs,
were fixed on 2026-08-09; six remain.**
```

- [ ] **Step 3: Add the sub-project to `docs/nix-reproducibility-review.md`**

In the `## Tier 3: all complete` list, after the nvim entry, add:

```markdown
- ~~**launchd declarative, and removing PHP.**~~ **Done.** Two agents declared
  through home-manager (`goku`, `tmux-boot`), three broken Homebrew and tpm-era
  jobs deleted. php83 removed with its four local-php aliases; the Docker-based
  Sail aliases stay. Found by the 2026-08-09 reproducibility audit, which is
  the first thing that ever surfaced them: `brew services list` returns empty,
  so no brew command showed any of the three.
```

- [ ] **Step 4: Check for em-dashes and commit**

```bash
cd ~/dotfiles
grep -n "—" reproducibility-audit-2026-08-09.md ../nix-reproducibility-review.md && echo "FIX THESE" || echo "clean"
git add reproducibility-audit-2026-08-09.md ../nix-reproducibility-review.md
git commit -m "docs: mark the three launchd findings resolved

Tier 1 items 1, 2 and 3 of the reproducibility audit are fixed. Six of the
original nine remain."
```

---

## Final verification

Run after all four tasks, before reporting completion.

- [ ] **Both agents load and no Homebrew job survives**

```bash
export PATH="/run/current-system/sw/bin:$PATH"
launchctl list | grep -c "org.nix-community.home" 
launchctl list | grep -E "homebrew.mxcl|Tmux.Start" && echo "STILL PRESENT" || echo "clean"
```
Expected: at least `2`, then `clean`.

- [ ] **The decisive goku test, repeated**

```bash
before=$(stat -c '%Y' ~/.config/karabiner/karabiner.json)
touch ~/dotfiles/karabiner/karabiner.edn
sleep 5
after=$(stat -c '%Y' ~/.config/karabiner/karabiner.json)
[ "$after" -gt "$before" ] && echo "PASS" || echo "FAIL"
```
Expected: `PASS`.

- [ ] **Everything else still works**

```bash
cd ~/dotfiles && bash nix/verify.sh all 2>&1 | tail -3
nvim --headless +qa && echo "nvim clean"
git status --short && echo "(tree clean if blank above)"
echo "built vs live:"; readlink /run/current-system
```
Expected: `PASSED`, `nvim clean`, a clean tree, and a live system matching the last build.

- [ ] **Report to Jose**

State plainly: which agents are declared, that the goku end-to-end test passed, that the tmux login behavior is unverified until he logs out and back in, and that an Accessibility prompt is expected the first time. Do not push.

---

## Notes for the implementer

**Three sudo handoffs.** Tasks 1, 2 and 3 each end with a `darwin-rebuild switch`. They are independent, so if Jose prefers, Tasks 1 through 3 can be edited and built first and switched once at the end. The cost is that a failure becomes harder to attribute. Ask before batching.

**Do not run `tmux kill-server`.** The session doing this work runs inside it.

**Why the plan does not trust a running process.** The bug being fixed presented as a healthy `launchctl list` entry with a live PID for days. Any check of the form "is it running" is worthless here. Only the touch-and-compare test in Task 1 Step 10 proves the fix.

**One thing is genuinely unknown.** `@continuum-boot on` is set in the running tmux server and `continuum.tmux` calls the enable path on load, yet `Tmux.Start.plist` does not exist. Either the enable path fails silently or the running server predates the plugin switch. Determining which requires restarting the tmux server, which would kill the session. It does not change any step here.
