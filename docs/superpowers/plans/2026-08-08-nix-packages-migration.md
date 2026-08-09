# Nix Packages Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move 55 Homebrew formulae and 734 MB of vendored binaries into nixpkgs, declared in the existing nix-darwin flake.

**Architecture:** A new `nix/packages.nix` module holds `environment.systemPackages` as named groups concatenated together. `nix/configuration.nix` imports it and stays a wiring file. A `nix/verify.sh` script asserts that each expected binary resolves from a Nix path rather than Homebrew, and runs after every batch. Migration proceeds in six batches ordered by blast radius, each one commit.

**Tech Stack:** Nix flakes, nix-darwin 26.05, nixpkgs 26.05 (`aarch64-darwin`), nix-homebrew, zsh.

**Spec:** `docs/superpowers/specs/2026-08-08-nix-packages-migration-design.md`

## Global Constraints

- Repo is `~/dotfiles`, branch `nix-darwin`. All paths below are relative to `~/dotfiles`.
- **Do not push.** A `pre-push` hook at `.git/hooks/pre-push` blocks all pushes. Leave it in place.
- **`darwin-rebuild switch` requires sudo and will prompt for a password.** An agent cannot run it non-interactively. Every rebuild step must be handed to Jose to run as `! sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1`. Wait for confirmation before proceeding to the verification step.
- Never set `homebrew.onActivation.cleanup` to anything other than `"none"`. Changing it would uninstall the 13 declared casks' undeclared neighbours, including all 243 formulae.
- Do not touch `~/.zprofile`. It is untracked and bracketed by Amazon Q blocks.
- Nix attribute names and binary names diverge. `verify.sh` checks **binary names**.
- Uncommitted WIP exists in `hammerspoon/appBundles.lua`, `hammerspoon/init.lua`, and `zsh/custom/aliases.zsh`. Never `git add -A` or `git commit -a`. Stage explicit paths only.
- Commit messages: no `Co-Authored-By` trailer.

## Rollback

Every task has the same shape: declare in Nix, rebuild, verify, **then** uninstall from Homebrew. That ordering is what makes rollback cheap.

**Before the `brew uninstall` step**, the Homebrew copy is still installed and nothing has been lost. Recovery is a rebuild against the previous generation:

```bash
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1 --rollback
```

Or list generations and pick one explicitly:

```bash
ls -l /nix/var/nix/profiles/ | grep system
```

**After the `brew uninstall` step**, recovery needs both halves:

```bash
brew install <formulae from the uninstall command in that task>
git revert <the task's commit>
```

then rebuild.

**If the shell itself breaks** (the risk in Task 2, which edits `source` lines in `zshrc`), you are not locked out. `zsh -f` starts without rc files, and `/bin/bash` is untouched by any of this. Repair `zsh/zshrc` from there, or `git checkout zsh/zshrc` to discard.

## File Structure

| File | Responsibility |
|---|---|
| `nix/packages.nix` | **Create.** All `environment.systemPackages` declarations, grouped |
| `nix/verify.sh` | **Create.** Per-batch binary resolution assertions |
| `nix/configuration.nix` | **Modify.** Add one `imports` line |
| `zsh/zshrc` | **Modify.** PATH precedence, dead entries, plugin source paths |

---

### Task 0: PATH precedence and the verification harness

No packages move in this task. It establishes that Nix can win over Homebrew and gives every later task its test cycle.

**Files:**
- Create: `nix/verify.sh`
- Modify: `zsh/zshrc:21-42`, `zsh/zshrc:165`

**Interfaces:**
- Produces: `nix/verify.sh <batch>` where batch is `0`-`5` or `all`. Exits 0 if every binary in that batch resolves from a Nix path, 1 otherwise.

- [ ] **Step 1: Record the current failing state**

```bash
cd ~/dotfiles
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'print -l $path' | head -12
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'which -a rg'
```

Expected: `/opt/homebrew/bin` appears above `/run/current-system/sw/bin`, and `rg` resolves to `/opt/homebrew/bin/rg`. This is the baseline the fix inverts.

- [ ] **Step 2: Write `nix/verify.sh`**

```bash
#!/usr/bin/env bash
# Assert that each expected binary resolves from Nix, not Homebrew.
# Usage: nix/verify.sh <0|1|2|3|4|5|all>
#
# Checks BINARY names, not nixpkgs attribute names. The two diverge:
# inetutils provides telnet, kubernetes-helm provides helm, coreutils
# provides sha256sum.
set -uo pipefail

batch0=()
batch1=(rg fzf jq tree htop wget pstree watchexec nmap pandoc typst
        actionlint git-filter-repo joker yt-dlp ranger jadx gh telnet
        sha256sum btop pkgconf ffmpeg magick pdfinfo pdftotext
        rsvg-convert woff2_compress cjpeg)
batch2=(git tmux starship z.lua)
batch3=(gcloud bq gsutil mvn nvim)
batch4=(php python3 node ruby dotnet yarn pipx ttx)
batch5=(mariadb redis-server minikube helm az svn qemu-system-aarch64)

fail=0

check() {
  local bin="$1" path
  if ! path="$(command -v "$bin" 2>/dev/null)"; then
    printf 'MISSING   %s\n' "$bin"
    fail=1
    return
  fi
  case "$path" in
    /nix/store/*|/run/current-system/sw/bin/*|"$HOME"/.nix-profile/bin/*)
      printf 'OK        %-18s %s\n' "$bin" "$path"
      ;;
    *)
      printf 'NOT NIX   %-18s %s\n' "$bin" "$path"
      fail=1
      ;;
  esac
}

run_batch() {
  local name="batch$1[@]"
  local list=("${!name}")
  [ ${#list[@]} -eq 0 ] && { printf 'batch %s: nothing to check\n' "$1"; return; }
  printf '=== batch %s ===\n' "$1"
  for b in "${list[@]}"; do check "$b"; done
}

if [ "${1:-all}" = all ]; then
  for i in 0 1 2 3 4 5; do run_batch "$i"; done
else
  run_batch "$1"
fi

if [ "$fail" -ne 0 ]; then
  printf '\nFAILED\n'
  exit 1
fi
printf '\nPASSED\n'
```

- [ ] **Step 3: Make it executable and confirm it fails correctly**

```bash
chmod +x nix/verify.sh
nix/verify.sh 1
```

Expected: FAIL. Every batch 1 binary either reports `MISSING` or `NOT NIX` pointing at `/opt/homebrew/bin`. This proves the harness detects the pre-migration state rather than passing vacuously.

- [ ] **Step 4: Replace the PATH block in `zsh/zshrc`**

Replace lines 21-40 (leave line 41 `ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX` and line 42 `php@8.3` alone for now) with:

```zsh
export PATH=${PATH}:/usr/local/aws/bin
export PATH=${PATH}:/usr/local/opt
export PATH=${PATH}:/usr/local/opt/coreutils/libexec/gnubin
export PATH=${PATH}:~/.composer/vendor/bin
export PATH=${PATH}:~/.dotfiles/bin
export PATH=${PATH}:~/.local/bin
export PATH=${PATH}:~/go/bin
export PATH=${PATH}:/opt/homebrew/opt/mysql-client/bin
```

Removed and why:
- `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`, `/usr/local/bin`, `/usr/local/sbin`: already present from nix-darwin's `set-environment`
- `/opt/homebrew/lib`: a library directory, never a `bin` directory
- `~/.dotfiles/bin/apache-maven-3.9.9/bin`: replaced in Task 3
- `~/.dotfiles/bin/jdt-java-lang-server/bin`: directory does not exist, never tracked in git
- `~/.rbenv/versions/bin`: directory does not exist
- `~/nvim-osx64/bin`: directory does not exist
- `/Users/jose/dotfiles/bin/nvim-macos-arm64/bin`: replaced in Task 3

- [ ] **Step 5: Append the precedence line to the end of `zsh/zshrc`**

After line 165 (`export PATH="$HOME/.yarn/bin:...`), which is currently the last line, append:

```zsh

# Nix must win over Homebrew. brew shellenv in ~/.zprofile prepends
# /opt/homebrew/bin, and several lines above prepend their own paths.
# This runs last, so it wins. Keep it at the bottom of this file.
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
```

- [ ] **Step 6: Verify precedence flipped**

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'print -l $path' | head -6
```

Expected: `/run/current-system/sw/bin` and `$HOME/.nix-profile/bin` are positions 1 and 2, above `/opt/homebrew/bin`.

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'which -a rg'
```

Expected: still `/opt/homebrew/bin/rg` only. No package has migrated yet. If this now shows a Nix path, something is wrong: stop and investigate.

- [ ] **Step 7: Commit**

```bash
git add nix/verify.sh zsh/zshrc
git commit -m "Add Nix PATH precedence and package verification harness"
```

---

### Task 1: CLI tools

**Files:**
- Create: `nix/packages.nix`
- Modify: `nix/configuration.nix`

**Interfaces:**
- Consumes: `nix/verify.sh` from Task 0
- Produces: `nix/packages.nix` exposing groups `cli` and `media`, concatenated into `environment.systemPackages`. Later tasks append groups `shell`, `vendored`, `languages`, `services` to the same `let` block and to the concatenation.

- [ ] **Step 1: Confirm the batch currently fails**

```bash
cd ~/dotfiles && nix/verify.sh 1
```

Expected: FAIL, every entry `NOT NIX` or `MISSING`.

- [ ] **Step 2: Create `nix/packages.nix`**

```nix
{ pkgs, ... }:

let
  cli = with pkgs; [
    actionlint
    btop            # replaces brew bpytop, which nixpkgs does not package
    coreutils       # replaces brew sha2; provides sha256sum and friends
    fzf
    gh
    git-filter-repo
    htop
    inetutils       # provides telnet
    jadx
    jq
    joker
    nmap
    pandoc
    pkgconf
    pstree
    ranger
    ripgrep
    tree
    typst
    watchexec
    wget
    yt-dlp
  ];

  media = with pkgs; [
    ffmpeg
    imagemagick
    libjpeg         # provides cjpeg, djpeg, jpegtran
    librsvg         # provides rsvg-convert
    poppler-utils   # plain `poppler` ships no bin/
    woff2           # provides woff2_compress, woff2_decompress
  ];
in
{
  environment.systemPackages = cli ++ media;
}
```

- [ ] **Step 3: Import it from `nix/configuration.nix`**

Add as the first line inside the top-level attribute set, immediately after the opening `{`:

```nix
  imports = [ ./packages.nix ];
```

- [ ] **Step 4: Stage the new file so the flake can see it**

```bash
git add nix/packages.nix nix/configuration.nix
```

Flakes only read git-tracked files. An untracked `packages.nix` is invisible to `darwin-rebuild` and produces a confusing "path does not exist" error. Staging is enough; no commit needed yet.

- [ ] **Step 5: Confirm the flake still evaluates**

```bash
nix eval ~/dotfiles#darwinConfigurations.\"REM-JoseS-MBP1\".system.outPath
```

Expected: a `/nix/store/...-darwin-system-26.05...` path, and it must differ from the currently active one. Compare against `readlink /run/current-system`.

- [ ] **Step 6: Hand the rebuild to Jose**

Ask Jose to run:

```
! sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

Wait for confirmation. Do not proceed until it reports success.

- [ ] **Step 7: Verify Nix now wins, before uninstalling anything**

```bash
nix/verify.sh 1
```

Expected: PASS. Every binary resolves under `/run/current-system/sw/bin`.

If `magick` or any binary reports MISSING, list what the package actually installed rather than guessing:

```bash
ls /run/current-system/sw/bin | grep -i <name>
```

Then correct the name in `verify.sh` and re-run.

- [ ] **Step 8: Uninstall the batch from Homebrew**

```bash
brew uninstall actionlint bpytop fzf gh git-filter-repo htop jadx jq joker \
  nmap pandoc pkgconf pstree ranger ripgrep sha2 telnet tree typst \
  watchexec wget yt-dlp ffmpeg imagemagick jpeg librsvg poppler woff2
```

If Homebrew refuses because another formula depends on one of these, leave that formula installed and note it. `brew autoremove` in Task 6 handles the dependency graph properly.

- [ ] **Step 9: Re-verify after uninstall**

```bash
nix/verify.sh 1
```

Expected: PASS. This is the step that catches a brew uninstall removing a binary Nix did not actually replace.

- [ ] **Step 10: Commit**

```bash
git add nix/packages.nix nix/configuration.nix
git commit -m "Move CLI tools from Homebrew to nixpkgs"
```

---

### Task 2: Shell-critical packages

git, tmux, starship, and the two zsh plugins. Separated from Task 1 because a mistake here breaks the shell you are working in, and because both plugin `source` lines must change in the same commit.

**Files:**
- Modify: `nix/packages.nix`, `zsh/zshrc:132`, `zsh/zshrc:138`, `zsh/zshrc:141`

**Interfaces:**
- Consumes: `nix/packages.nix` `let` block from Task 1
- Produces: a `shell` group appended to the concatenation

- [ ] **Step 1: Confirm the batch currently fails**

```bash
cd ~/dotfiles && nix/verify.sh 2
```

Expected: FAIL, `git`, `tmux`, and `starship` all `NOT NIX`.

- [ ] **Step 2: Add the `shell` group to `nix/packages.nix`**

Insert after the `media` group inside the `let` block:

```nix
  shell = with pkgs; [
    git
    starship
    tmux
    z-lua                   # provides z and z.lua
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
```

And change the concatenation to:

```nix
  environment.systemPackages = cli ++ media ++ shell;
```

- [ ] **Step 3: Repoint the zsh plugin source lines**

Replace line 132:

```zsh
source /run/current-system/sw/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

Replace line 138:

```zsh
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/run/current-system/sw/share/zsh-syntax-highlighting/highlighters
```

Replace line 141:

```zsh
source /run/current-system/sw/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

Note that the trailing `2>/dev/null` is dropped from both `source` lines deliberately. It is what hid the fact that line 141 pointed at `/usr/local/share/zsh-syntax-highlighting`, an Intel Homebrew path that has never existed on this machine. Without the suppression, a wrong path fails loudly.

- [ ] **Step 4: Stage and rebuild**

```bash
git add nix/packages.nix zsh/zshrc
```

Ask Jose to run:

```
! sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

Wait for confirmation.

- [ ] **Step 5: Confirm the plugin paths actually exist before opening a new shell**

```bash
ls /run/current-system/sw/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ls /run/current-system/sw/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

Expected: both listed. If either is missing, find the real location before proceeding, because a broken `source` without `2>/dev/null` now produces an error on every new shell:

```bash
find /run/current-system/sw/share -name 'zsh-syntax-highlighting.zsh'
```

- [ ] **Step 6: Verify in a clean shell**

```bash
nix/verify.sh 2
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'echo SHELL_OK' 2>&1 | tail -5
```

Expected: verify PASSES, and the shell prints `SHELL_OK` with no error output above it.

- [ ] **Step 7: Uninstall from Homebrew**

```bash
brew uninstall git tmux starship z.lua zsh-autosuggestions zsh-syntax-highlighting
```

- [ ] **Step 8: Re-verify and commit**

```bash
nix/verify.sh 2
git add nix/packages.nix zsh/zshrc
git commit -m "Move git, tmux, starship, and zsh plugins to nixpkgs"
```

---

### Task 3: Vendored binaries

Replaces 734 MB of checked-out SDKs with nixpkgs packages and deletes the directories.

**Files:**
- Modify: `nix/packages.nix`, `zsh/zshrc:154-158`
- Delete: `bin/google-cloud-sdk`, `bin/apache-maven-3.9.9`, `bin/nvim-macos-arm64`

**Interfaces:**
- Produces: a `vendored` group appended to the concatenation

- [ ] **Step 1: Record what the vendored gcloud provides**

```bash
ls ~/dotfiles/bin/google-cloud-sdk/bin
du -sh ~/dotfiles/bin/google-cloud-sdk ~/dotfiles/bin/apache-maven-3.9.9 ~/dotfiles/bin/nvim-macos-arm64
```

Expected: `bq`, `gcloud`, `gsutil`, `docker-credential-gcloud` among others, and roughly 689M, 10M, 35M.

- [ ] **Step 2: Add the `vendored` group**

```nix
  vendored = with pkgs; [
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    maven
    neovim
  ];
```

And update the concatenation:

```nix
  environment.systemPackages = cli ++ media ++ shell ++ vendored;
```

Nix cannot run `gcloud components install` into a read-only store, so every component must be declared at build time.

`bq` and `gsutil` are expected to ship in the base `google-cloud-sdk` package, but this is **unverified** and Step 3 checks it explicitly. If either is missing after the rebuild, add it to the component list:

```nix
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
      google-cloud-sdk.components.bq
      google-cloud-sdk.components.gsutil
    ])
```

To see the full set of available component names:

```bash
nix eval --raw nixpkgs#google-cloud-sdk.components --apply \
  'c: builtins.concatStringsSep "\n" (builtins.attrNames c)'
```

- [ ] **Step 3: Stage, rebuild, verify before deleting anything**

```bash
git add nix/packages.nix
```

Ask Jose to run:

```
! sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

Then:

```bash
nix/verify.sh 3
gcloud version
mvn -version
nvim --version | head -1
```

Expected: verify PASSES and all three commands report versions. Do not proceed to deletion until this passes. The vendored copies are still on PATH as a fallback at this point.

- [ ] **Step 4: Remove the gcloud shell integration lines from `zsh/zshrc`**

Delete lines 154-158, which are:

```zsh
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jose/dotfiles/bin/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/jose/dotfiles/bin/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jose/dotfiles/bin/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/jose/dotfiles/bin/google-cloud-sdk/completion.zsh.inc'; fi
```

The nixpkgs `google-cloud-sdk` package installs its own completions into the zsh function path, so no replacement lines are needed.

- [ ] **Step 5: Delete the vendored directories**

```bash
rm -rf ~/dotfiles/bin/google-cloud-sdk \
       ~/dotfiles/bin/apache-maven-3.9.9 \
       ~/dotfiles/bin/nvim-macos-arm64
```

`bin/git-wtf` and `bin/zsh-colors` are tracked in git and must remain.

- [ ] **Step 6: Remove the now-dead gitignore entries**

In `.gitignore`, delete these three lines:

```
bin/apache-maven-3.9.9/*
bin/nvim-macos-arm64/*
bin/google-cloud-sdk/*
```

- [ ] **Step 7: Verify in a clean shell and confirm the reclaim**

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'which -a gcloud mvn nvim'
du -sh ~/dotfiles/bin
```

Expected: all three resolve under `/run/current-system/sw/bin`, and `bin/` is now well under 1 MB.

- [ ] **Step 8: Commit**

```bash
git add nix/packages.nix zsh/zshrc .gitignore bin/
git commit -m "Replace vendored gcloud, maven, and neovim with nixpkgs"
```

---

### Task 4: Language runtimes

Highest blast radius. Touches every project on the machine.

**Files:**
- Modify: `nix/packages.nix`, `zsh/zshrc:42`, `zsh/zshrc:146-149`

**Interfaces:**
- Produces: a `languages` group appended to the concatenation

- [ ] **Step 1: Record current versions to compare against**

```bash
php --version | head -1
python3 --version
node --version
ruby --version
```

Write these down. Nix versions will differ and that is expected, but a major version jump is worth knowing about before it surprises you.

- [ ] **Step 2: Add the `languages` group**

```nix
  languages = with pkgs; [
    dotnet-sdk
    nodejs
    php83
    pipx
    python312
    python3Packages.fonttools   # provides ttx, pyftsubset
    ruby
    yarn
  ];
```

And update the concatenation:

```nix
  environment.systemPackages =
    cli ++ media ++ shell ++ vendored ++ languages;
```

Deliberately excluded, per the spec's one-version-per-runtime decision:
- `php` (bare) is superseded by `php83`
- `python@3.11` is superseded by `python312`
- `python@3.10` was removed from nixpkgs 26.05
- `nvm` has no nixpkgs equivalent by design

- [ ] **Step 3: Remove the php@8.3 PATH prepend**

Delete `zsh/zshrc:42`:

```zsh
export PATH="/opt/homebrew/opt/php@8.3/bin:$PATH"
```

- [ ] **Step 4: Remove the nvm block**

Delete `zsh/zshrc:146-149`:

```zsh
# NVM
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
```

`~/.nvm` itself is left on disk untouched. Deleting it is a separate decision and not part of this migration.

- [ ] **Step 5: Stage, rebuild, verify**

```bash
git add nix/packages.nix zsh/zshrc
```

Ask Jose to run:

```
! sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

Then:

```bash
nix/verify.sh 4
```

Expected: PASS.

- [ ] **Step 6: Uninstall from Homebrew**

```bash
brew uninstall php php@8.3 python@3.10 python@3.11 python@3.12 node nvm \
  ruby dotnet yarn pipx fonttools
```

If Homebrew refuses to remove a python because another formula depends on it, leave it and let Task 6 handle it.

- [ ] **Step 7: Re-verify in a clean shell**

```bash
nix/verify.sh 4
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'php --version; python3 --version; node --version; ruby --version'
```

Expected: verify PASSES and all four report versions with no `command not found`.

- [ ] **Step 8: Commit**

```bash
git add nix/packages.nix zsh/zshrc
git commit -m "Move language runtimes to nixpkgs, drop nvm"
```

---

### Task 5: Services and heavy packages

**Files:**
- Modify: `nix/packages.nix`

**Interfaces:**
- Produces: a `services` group appended to the concatenation

- [ ] **Step 1: Confirm the batch currently fails**

```bash
cd ~/dotfiles && nix/verify.sh 5
```

Expected: FAIL.

- [ ] **Step 2: Add the `services` group**

```nix
  services = with pkgs; [
    azure-cli
    kubernetes-helm   # provides helm
    mariadb
    minikube
    qemu
    redis
    subversion        # provides svn
  ];
```

And update the concatenation:

```nix
  environment.systemPackages =
    cli ++ media ++ shell ++ vendored ++ languages ++ services;
```

- [ ] **Step 3: Stage, rebuild, verify**

```bash
git add nix/packages.nix
```

Ask Jose to run:

```
! sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

Then:

```bash
nix/verify.sh 5
```

Expected: PASS.

- [ ] **Step 4: Check that the MariaDB data directory still works**

```bash
mysql --version
ls /opt/homebrew/var/mysql 2>/dev/null | head -3
```

The Nix `mariadb` client will not automatically find a Homebrew-created data directory or a running Homebrew service. If you were running MariaDB as a brew service, note it: relocating the datadir is out of scope for this migration and should be tracked separately.

- [ ] **Step 5: Uninstall from Homebrew**

```bash
brew uninstall azure-cli helm mariadb minikube qemu redis subversion
```

- [ ] **Step 6: Re-verify and commit**

```bash
nix/verify.sh 5
git add nix/packages.nix
git commit -m "Move services and heavy packages to nixpkgs"
```

---

### Task 6: Sweep dependencies and document exceptions

**Files:**
- Modify: `nix/packages.nix`

- [ ] **Step 1: See what is left**

```bash
brew leaves
brew list --formula | wc -l
```

Expected: `brew leaves` returns only `ant`, plus anything a batch could not uninstall due to dependency ordering.

- [ ] **Step 2: Sweep orphaned dependencies**

```bash
brew autoremove --dry-run
```

Read the list. It should be transitive dependencies of the formulae just removed, not anything you recognise as directly useful. Then:

```bash
brew autoremove
```

- [ ] **Step 3: Add the exceptions block to `nix/packages.nix`**

Add as a comment block inside the attribute set, immediately above the `environment.systemPackages` line:

```nix
  # Exceptions: deliberately NOT migrated from Homebrew.
  #
  #   ant          apacheAnt evaluates unavailable on aarch64-darwin.
  #                Remains a brew formula.
  #   nvm          No nixpkgs equivalent by design. Superseded by the
  #                global `nodejs` above; use devshells for per-project
  #                versions.
  #   python@3.10  Removed from nixpkgs 26.05. Use a devshell if a
  #                project still requires it.
  #   pytorch      python3Packages.torch exists but is heavy and rarely
  #                wanted globally. Use a devshell.
  #
  # Recorded here rather than omitted silently, so the reason survives.
```

- [ ] **Step 4: Full verification**

```bash
nix/verify.sh all
```

Expected: PASS across every batch.

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'print -l $path' | head -4
du -sh ~/dotfiles/bin
brew leaves
```

Expected: Nix paths first, `bin/` under 1 MB, `brew leaves` showing only documented exceptions.

- [ ] **Step 5: Confirm a clean rebuild still works**

Ask Jose to run:

```
! sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

Expected: succeeds with no changes to apply beyond the exceptions comment.

- [ ] **Step 6: Commit**

```bash
git add nix/packages.nix
git commit -m "Document unmigrated Homebrew exceptions"
```

- [ ] **Step 7: Report, do not push**

Summarise for Jose: packages migrated, disk reclaimed, exceptions remaining. The `pre-push` hook stays in place. Pushing is Jose's decision, not part of this plan.
