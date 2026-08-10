# Shared core across macOS and WSL: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `nix/home/` into shared, darwin and linux trees, and add a standalone home-manager output for a WSL2 box, without changing the Mac's behaviour at all.

**Architecture:** Two tasks do the Mac side in halves that can each be verified independently: a pure file move first, then the platform split. Both must leave the Mac's system hash byte-identical. A third task adds the Linux output, which can only be evaluated from the Mac, not built.

**Tech Stack:** nix flakes, nix-darwin 26.05, home-manager release-26.05 (both as a nix-darwin module and standalone), nixpkgs 26.05.

## Global Constraints

- **The Mac's system hash must stay `8j0sbgyka96z1rmm0nfq5nbkbqbkd2rp` through Tasks 1 and 2.** This is a file move plus a platform split, not a behaviour change. A different hash means something moved that should not have.
- `darwin-rebuild switch` needs sudo. **Never run it.** Build with `nix build` and hand Jose the command.
- **The Linux side cannot be built on this machine.** Cross-building x86_64-linux from darwin needs a remote builder. Verify with `nix eval` only.
- Do not push. Commit only.
- No co-author trailers in commit messages.
- No em-dashes (the character) in any file content or output. Use commas, colons, or parentheses.
- The tool shell has no nix on PATH. Prefix nix commands with:
  `export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"`
- Nix only reads git-tracked files. `git add` every new file **before** building, or the build reports it does not exist.
- Verify a build succeeded by checking the printed path exists (`[ -d "$out" ]`). The last line of `nix build` output can be part of an error trace.

---

## Task 1: Move the files, change nothing else

The point of doing this separately is attribution: if the hash changes here, it was the move. If it changes in Task 2, it was the split.

**Files:**
- Move: `nix/home/{git,shell,tmux,nvim}.nix` to `nix/home/shared/`
- Move: `nix/home/{alacritty,karabiner,java}.nix` to `nix/home/darwin/`
- Move: `nix/home/default.nix` to `nix/home/darwin/default.nix`
- Modify: `nix/home/shared/nvim.nix` (one relative path)
- Modify: `nix/home/darwin/default.nix` (the imports list)
- Modify: `nix/configuration.nix:56`

**Interfaces:**
- Produces: `nix/home/darwin/default.nix` as the darwin entry point, importing four modules from `../shared/` and three siblings.
- Consumes: nothing from other tasks.

- [ ] **Step 1: Record the before-hash**

```bash
cd ~/dotfiles
export PATH="/run/current-system/sw/bin:$PATH"
readlink /run/current-system
```
Expected: a path ending `8j0sbgyka96z1rmm0nfq5nbkbqbkd2rp-darwin-system-26.05.c3e90c8`. Write it down; Step 8 compares against it.

- [ ] **Step 2: Move the files with git mv**

Use `git mv` rather than `mv`, so git records renames and the diff stays readable.
```bash
cd ~/dotfiles
mkdir -p nix/home/shared nix/home/darwin
git mv nix/home/git.nix       nix/home/shared/git.nix
git mv nix/home/shell.nix     nix/home/shared/shell.nix
git mv nix/home/tmux.nix      nix/home/shared/tmux.nix
git mv nix/home/nvim.nix      nix/home/shared/nvim.nix
git mv nix/home/alacritty.nix nix/home/darwin/alacritty.nix
git mv nix/home/karabiner.nix nix/home/darwin/karabiner.nix
git mv nix/home/java.nix      nix/home/darwin/java.nix
git mv nix/home/default.nix   nix/home/darwin/default.nix
ls nix/home nix/home/shared nix/home/darwin
```
Expected: `nix/home/` contains only the two directories.

- [ ] **Step 3: Fix the one relative path that shifted**

`nix/home/shared/nvim.nix` is now one directory deeper, so its read of the Lua file must go up one more level. Change line 67 from:
```nix
    initLua = builtins.readFile ../../nvim/init.lua;
```
to:
```nix
    initLua = builtins.readFile ../../../nvim/init.lua;
```

This is the only relative Nix path in any moved file. The `./vendor/bin/...` strings in `shell.nix` are shell alias text, not Nix paths, and do not shift.

- [ ] **Step 4: Rewrite the imports in `nix/home/darwin/default.nix`**

Replace lines 11 to 19:
```nix
  imports = [
    ./git.nix
    ./shell.nix
    ./alacritty.nix
    ./tmux.nix
    ./nvim.nix
    ./karabiner.nix
    ./java.nix
  ];
```
with:
```nix
  imports = [
    # Shared with the WSL box. Anything in here must work on both.
    ../shared/git.nix
    ../shared/shell.nix
    ../shared/tmux.nix
    ../shared/nvim.nix

    # macOS only.
    ./alacritty.nix
    ./karabiner.nix
    ./java.nix
  ];
```

- [ ] **Step 5: Point `nix/configuration.nix` at the new entry**

Change line 56 from:
```nix
    users.${user} = import ./home;
```
to:
```nix
    users.${user} = import ./home/darwin;
```

- [ ] **Step 6: Track everything, then build**

```bash
cd ~/dotfiles
export PATH="/run/current-system/sw/bin:$PATH"
git add -A nix/
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>&1 | tail -1)
echo "$out"
[ -d "$out" ] && echo "BUILD OK" || echo "BUILD FAILED"
```
Expected: `BUILD OK`. If it failed, the most likely cause is the `nvim.nix` path in Step 3 or a stale `./` import in Step 4.

- [ ] **Step 7: The hash check, which is the whole point of this task**

```bash
export PATH="/run/current-system/sw/bin:$PATH"
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>/dev/null | tail -1)
echo "built: $out"
echo "live:  $(readlink /run/current-system)"
[ "$out" = "$(readlink /run/current-system)" ] && echo "IDENTICAL, move was pure" || echo "HASH CHANGED, stop and investigate"
```
Expected: `IDENTICAL, move was pure`.

If it changed, do not continue. Diff the generated `.zshrc` against the live one to find out what moved:
```bash
new=$(nix-store -qR "$out" | grep home-manager-files | while read d; do [ -f "$d/.zshrc" ] && echo "$d/.zshrc"; done | head -1)
diff "$new" ~/.zshrc
```
The likely cause is `initContent` ordering: `shell.nix`'s `mkOrder 1100` comment explains that a tie with starship's default-priority block is broken by module-encounter order, and moving a module changes that order.

- [ ] **Step 8: Commit**

```bash
cd ~/dotfiles
git add -A nix/
git commit -m "refactor: move nix/home into shared and darwin trees

Pure file move ahead of adding a Linux target. No behaviour change: the
system hash is identical before and after, which is the check that proves
it, because this repo has already lost a hash to an initContent ordering
tie during what was supposed to be a pure move.

git, shell, tmux and nvim go to shared/ because they will be imported by
both platforms. alacritty, karabiner and java go to darwin/ because they
cannot work anywhere else. The shared modules still contain macOS-specific
lines at this point; splitting those out is the next commit, kept separate
so a hash change can be attributed to one or the other.

nvim.nix's builtins.readFile path gains one level. It is the only relative
Nix path in any moved file."
```

---

## Task 2: Split the platform-specific lines out of the shared modules

**Files:**
- Create: `nix/home/darwin/extras.nix`
- Modify: `nix/home/shared/git.nix` (remove one line)
- Modify: `nix/home/shared/tmux.nix` (remove the alert hook and the launchd agent)
- Modify: `nix/home/shared/shell.nix` (remove five darwin pieces)
- Modify: `nix/home/darwin/default.nix` (import extras.nix)

**Interfaces:**
- Consumes: the tree produced by Task 1.
- Produces: `shared/` modules that contain nothing macOS-specific, so Task 3 can import them from Linux.

- [ ] **Step 1: Create `nix/home/darwin/extras.nix`**

Every block below is moved verbatim from a shared module, not rewritten. The
`mkOrder` values are the load-bearing part: see the comments.

```nix
{ config, lib, ... }:

{
  # The macOS half of the shared modules. Kept here rather than behind
  # `lib.mkIf pkgs.stdenv.isDarwin` guards inside each shared module, so that
  # "is this shared?" is answered by the file path.
  #
  # macOS keychain. Does not exist on Linux, where git will prompt instead.
  programs.git.settings.credential.helper = "osxkeychain";

  programs.tmux.extraConfig = lib.mkAfter ''
    set-hook -g alert-bell 'run-shell "osascript -e \"display notification \\\"Claude requires your attention\\\" with title \\\"Claude Code\\\"\""'
  '';

  programs.zsh = {
    # ~/.zprofile, login shells only. The whole reason /opt/homebrew/bin is on
    # PATH. brew shellenv PREPENDS, so the mkOrder 1600 block below is what
    # takes precedence back for Nix.
    profileExtra = ''
      # Set PATH, MANPATH, etc., for Homebrew.
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    sessionVariables.ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX = "YES";

    # pbcopy is macOS only.
    shellAliases.gdesc = "git log --no-merges --pretty=format:'- %s' master.. | pbcopy";

    initContent = lib.mkMerge [
      # mkBefore, same as the shared block, because this MUST precede compinit.
      # Two mkBefore blocks tie at 500, which is harmless here: one sources
      # ~/.secrets and this one prepends to fpath, and neither depends on the
      # other's ordering.
      (lib.mkBefore ''
        # MUST be before compinit, which home-manager's enableCompletion
        # runs early in the generated .zshrc. fpath mutations after compinit
        # are ignored, so `docker <TAB>` would silently stop completing.
        fpath=(${config.home.homeDirectory}/.docker/completions $fpath)
      '')

      # This entire block is verbatim from the pre-split shared/shell.nix, at
      # the same mkOrder, deliberately NOT split along platform lines.
      #
      # Two of its six items are macOS-only (the functions.zsh source, whose
      # functions call `open`, and the aws_completer path under /usr/local),
      # and they are interleaved with the four portable ones. Splitting the
      # block would reorder the generated .zshrc and change the system hash,
      # so the whole thing stays here and linux/default.nix carries its own
      # copy of the four portable items instead.
      (lib.mkOrder 1100 ''
        source $HOME/dotfiles/zsh/custom/functions.zsh

        zstyle ':completion:*' verbose yes
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        zmodload zsh/complist
        _comp_options+=(globdots)

        autoload bashcompinit && bashcompinit
        complete -C '/usr/local/bin/aws_completer' aws

        bindkey -v '^?' backward-delete-char
        bindkey -M menuselect 'h' vi-backward-char
        bindkey -M menuselect 'k' vi-up-line-or-history
        bindkey -M menuselect 'l' vi-forward-char
        bindkey -M menuselect 'j' vi-down-line-or-history

        autoload edit-command-line; zle -N edit-command-line
        bindkey '^e' edit-command-line

        eval "$(fzf --zsh)"
      '')

      # 1600, above the shared mkAfter block's 1500. This must run LAST of all
      # PATH manipulation or Homebrew wins: brew shellenv in profileExtra above
      # prepends /opt/homebrew/bin, and this is what takes precedence back.
      #
      # /run/current-system/sw/bin is a nix-darwin path and does not exist on
      # Linux, which is why this line cannot live in the shared module.
      (lib.mkOrder 1600 ''
        export PATH="/run/current-system/sw/bin:$PATH"
      '')
    ];
  };
}
```

- [ ] **Step 2: Move the launchd agent out of `shared/tmux.nix`**

Cut the whole `launchd.agents.tmux-boot = { ... };` block, including its comment
block above it, from `nix/home/shared/tmux.nix` and append it to
`nix/home/darwin/extras.nix` inside the top-level attribute set. Keep the
comments verbatim: they record the mid-rebuild-fires hazard and the
Accessibility caveat, both of which cost real time to discover.

Also delete the `set-hook -g alert-bell` line from `shared/tmux.nix`'s
`extraConfig`, since Step 1 re-adds it in `extras.nix`.

After this, `shared/tmux.nix` should have no `osascript` and no `launchd`. Its
header is already `{ pkgs, ... }:` and stays that way; it never took `config`.
Check with:
```bash
grep -nE "osascript|launchd" nix/home/shared/tmux.nix
```
Expected: no output.

Note `extras.nix` as written in Step 1 does take `config`, because the docker
completions fpath line uses `config.home.homeDirectory`.

- [ ] **Step 3: Remove the darwin lines from `shared/git.nix`**

Delete this line and the comment attached to it if one exists:
```nix
      credential.helper = "osxkeychain";
```
Verify:
```bash
grep -nE "osxkeychain|Library|/opt/" nix/home/shared/git.nix
```
Expected: no output.

- [ ] **Step 4: Remove the five darwin pieces from `shared/shell.nix`**

Delete each of these, all now provided by `extras.nix`:

1. The whole `profileExtra = '' ... '';` block and its comment.
2. The line `ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX = "YES";`
3. The line `gdesc = "git log --no-merges --pretty=format:'- %s' master.. | pbcopy";`
4. The `fpath=(...docker/completions...)` line from inside the `mkBefore` block, and the comment above it that explains compinit ordering. Keep the `[ -f ~/.secrets ] && source ~/.secrets` line and the `mkBefore` wrapper.
5. The entire `(lib.mkOrder 1100 '' ... '')` block, comment included.
6. From the `mkAfter` block, only the final `export PATH="/run/current-system/sw/bin:$PATH"` line and the comment paragraph above it. **Keep** the three portable exports (`~/.bin`, `~/.local/bin`, yarn).

Verify:
```bash
grep -nE "profileExtra|ITERM_|pbcopy|docker/completions|mkOrder 1100|run/current-system" nix/home/shared/shell.nix
```
Expected: no output.

- [ ] **Step 5: Import extras.nix**

In `nix/home/darwin/default.nix`, add `./extras.nix` to the macOS-only group:
```nix
    # macOS only.
    ./alacritty.nix
    ./karabiner.nix
    ./java.nix
    ./extras.nix
```

- [ ] **Step 6: Build**

```bash
cd ~/dotfiles
export PATH="/run/current-system/sw/bin:$PATH"
git add -A nix/
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>&1 | tail -1)
echo "$out"; [ -d "$out" ] && echo "BUILD OK" || echo "BUILD FAILED"
```
Expected: `BUILD OK`.

- [ ] **Step 7: The hash check again**

```bash
export PATH="/run/current-system/sw/bin:$PATH"
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>/dev/null | tail -1)
[ "$out" = "$(readlink /run/current-system)" ] && echo "IDENTICAL, split was behaviour-neutral" || { echo "HASH CHANGED"; echo "built: $out"; }
```
Expected: `IDENTICAL, split was behaviour-neutral`.

If it changed, diff the generated `.zshrc` and look at line order first:
```bash
new=$(nix-store -qR "$out" | grep home-manager-files | while read d; do [ -f "$d/.zshrc" ] && echo "$d/.zshrc"; done | head -1)
diff "$new" ~/.zshrc
```
The three most likely causes, in order: the `mkOrder 1600` block landed at a
different priority; a line was dropped in Step 4 rather than moved; or the two
`mkBefore` blocks resolved in the opposite order.

- [ ] **Step 8: Confirm the shared modules are genuinely platform-neutral**

This is the check that Task 3 depends on.
```bash
cd ~/dotfiles
grep -rnE "osascript|launchd|pbcopy|osxkeychain|/opt/homebrew|/run/current-system|/usr/local|ITERM_|Library/" nix/home/shared/
```
Expected: no output. Any hit is something that will break on Linux.

- [ ] **Step 9: Commit**

```bash
cd ~/dotfiles
git add -A nix/
git commit -m "refactor: extract the macOS-specific half into darwin/extras.nix

The shared modules now contain nothing macOS-specific, which is what lets a
Linux target import them. System hash is unchanged again, so the split is
behaviour-neutral as well as the move was.

The mkOrder 1100 block moved whole rather than being split along platform
lines. Two of its six items are macOS-only and they are interleaved with the
four portable ones, so splitting it would have reordered the generated .zshrc
and changed the hash. linux/default.nix carries its own copy of the four
portable items instead, which is about 12 duplicated lines bought in exchange
for the strongest available verification here.

The new PATH override sits at mkOrder 1600, above the shared mkAfter block's
1500, because it has to run after every other PATH manipulation or Homebrew
wins."
```

---

## Task 3: The Linux target

**Files:**
- Create: `nix/home/linux/default.nix`
- Modify: `flake.nix` (add the `homeConfigurations` output)

**Interfaces:**
- Consumes: `nix/home/shared/{git,shell,tmux,nvim}.nix`, which Task 2 guaranteed are platform-neutral.
- Produces: `homeConfigurations."jose@RockemSockem"`.

- [ ] **Step 1: Create `nix/home/linux/default.nix`**

```nix
{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  imports = [
    # The same four modules the Mac uses. Task 2 removed everything
    # macOS-specific from them.
    ../shared/git.nix
    ../shared/shell.nix
    ../shared/tmux.nix
    ../shared/nvim.nix
  ];

  # Standalone home-manager needs these three explicitly. On the Mac they come
  # from nix-darwin via users.users.<name>.home and system.primaryUser.
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # Terminal dev core. The Mac declares 51 packages through
  # environment.systemPackages, which is a nix-darwin option, so this list is
  # written fresh rather than shared.
  #
  # Deliberately absent: coreutils (Linux already has GNU coreutils, unlike
  # macOS), goku (drives Karabiner), jadx, inetutils, nmap, pandoc, typst,
  # ranger, joker, yt-dlp, uv, shopify-cli, stripe-cli, and everything in the
  # media, vendored, languages and services groups.
  home.packages = with pkgs; [
    actionlint
    btop
    fzf
    gh
    git-filter-repo
    htop
    jq
    pstree
    ripgrep
    tree
    watchexec
    wget
  ];

  # git-wtf and zsh-colors, both portable shell scripts. The Mac's other
  # linked files are macOS-specific or depend on osascript.
  home.file.".bin".source = link "bin";

  # The four portable items from the Mac's mkOrder 1100 block, copied rather
  # than shared. See darwin/extras.nix for why that block did not split: two of
  # its six items are macOS-only and interleaved with these, so splitting it
  # would have reordered the Mac's generated .zshrc.
  programs.zsh.initContent = lib.mkOrder 1100 ''
    zstyle ':completion:*' verbose yes
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
    zmodload zsh/complist
    _comp_options+=(globdots)

    bindkey -v '^?' backward-delete-char
    bindkey -M menuselect 'h' vi-backward-char
    bindkey -M menuselect 'k' vi-up-line-or-history
    bindkey -M menuselect 'l' vi-forward-char
    bindkey -M menuselect 'j' vi-down-line-or-history

    autoload edit-command-line; zle -N edit-command-line
    bindkey '^e' edit-command-line

    eval "$(fzf --zsh)"
  '';
}
```

- [ ] **Step 2: Add the flake output**

In `flake.nix`, after the closing brace of `darwinConfigurations`, add a sibling
attribute inside the same output set:

```nix
    # Standalone home-manager for the WSL2 box. nix-darwin cannot serve it, so
    # this is a separate output rather than another mkHost entry. Only $HOME is
    # managed there; the machine itself is not.
    homeConfigurations."jose@RockemSockem" =
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { user = "jose"; };
        modules = [ ./nix/home/linux ];
      };
```

- [ ] **Step 3: Track the new file, then confirm it evaluates**

The Linux side cannot be built here, so evaluation is the available check. It
still proves the module tree resolves and that no macOS-only option leaked into
`shared/`.
```bash
cd ~/dotfiles
export PATH="/run/current-system/sw/bin:$PATH"
git add -A nix/ flake.nix
nix eval --raw '.#homeConfigurations."jose@RockemSockem".config.home.homeDirectory'
```
Expected: `/home/jose`.

- [ ] **Step 4: Confirm the shared modules really did evaluate on Linux**

An empty module set would also satisfy Step 3, so check something that can only
come from `shared/`.
```bash
export PATH="/run/current-system/sw/bin:$PATH"
nix eval --raw '.#homeConfigurations."jose@RockemSockem".config.programs.git.settings.user.name'
nix eval '.#homeConfigurations."jose@RockemSockem".config.programs.zsh.enable'
nix eval '.#homeConfigurations."jose@RockemSockem".config.programs.neovim.enable'
nix eval '.#homeConfigurations."jose@RockemSockem".config.programs.tmux.enable'
```
Expected: `Jose Soto`, then `true` three times.

- [ ] **Step 5: Confirm no macOS option leaked in**

If a darwin-only option had survived in `shared/`, this is where it shows up.
```bash
export PATH="/run/current-system/sw/bin:$PATH"
nix eval '.#homeConfigurations."jose@RockemSockem".config.programs.git.settings.credential' 2>&1 | tail -1
```
Expected: an error saying the attribute is missing, or an empty set. If it
returns `{ helper = "osxkeychain"; }`, Task 2 Step 3 was not applied.

- [ ] **Step 6: Confirm the Mac is still untouched**

Adding an output must not change the existing one.
```bash
export PATH="/run/current-system/sw/bin:$PATH"
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>/dev/null | tail -1)
[ "$out" = "$(readlink /run/current-system)" ] && echo "Mac unchanged" || echo "Mac hash CHANGED"
```
Expected: `Mac unchanged`.

- [ ] **Step 7: Commit**

```bash
cd ~/dotfiles
git add -A nix/ flake.nix
git commit -m "feat: add a standalone home-manager target for the WSL2 box

RockemSockem is x86_64-linux, so mkHost cannot serve it: that builds
nix-darwin systems and nix-darwin is macOS-only. This is a separate
homeConfigurations output driven by standalone home-manager, managing \$HOME
only rather than the machine.

It imports the same four shared modules the Mac uses, and declares its own
12-package terminal dev set, because the Mac's 51 come through
environment.systemPackages, which is a nix-darwin option and cannot be shared.

Verified by evaluation rather than by building: cross-building x86_64-linux
from darwin needs a remote builder this machine does not have. Evaluation
still proves the module tree resolves and that nothing macOS-only leaked into
shared/. Building and activating happen on that box."
```

---

## Task 4: Document the WSL bootstrap

**Files:**
- Modify: `README.md`
- Modify: `docs/nix-reproducibility-review.md`

**Interfaces:**
- Consumes: the completed state of Tasks 1 to 3.
- Produces: nothing.

- [ ] **Step 1: Add a WSL section to `README.md`**

Insert after the "Adding another machine" section. The two gotchas are the
reason this section exists; they are both discovered-the-hard-way items.

```markdown
## The WSL2 box

`RockemSockem` is Linux, so it cannot use `mkHost`: that builds nix-darwin
systems and nix-darwin is macOS-only. It gets a separate output driven by
standalone home-manager, which manages `$HOME` and nothing else.

```sh
home-manager switch --flake ~/dotfiles#jose@RockemSockem
```

It shares four modules with the Mac, `nix/home/shared/`: git, zsh and starship,
tmux, and neovim. Everything macOS-specific lives in `nix/home/darwin/`, and the
Linux-only pieces in `nix/home/linux/`.

Two things to expect on a first run:

**The first switch will refuse to overwrite the distro's dotfiles.** WSL images
ship a `.bashrc` and `.profile`, and home-manager will not clobber them. Pass a
backup extension once:

```sh
home-manager switch -b bak --flake ~/dotfiles#jose@RockemSockem
```

**zsh will be installed but will not be your login shell.** `programs.zsh` puts
zsh in the profile; it does not change your shell. One time:

```sh
command -v zsh | sudo tee -a /etc/shells
chsh -s "$(command -v zsh)"
```

Deliberately not on that box: Java, cloud CLIs, media tooling, Alacritty (WSL
uses Windows Terminal), and `zsh/custom/functions.zsh`, whose functions call
macOS's `open`.
```

- [ ] **Step 2: Update the layers table in `README.md`**

The "The three layers" table's home-manager row currently says its config lives
in `nix/home/`. Change that cell to `nix/home/shared/`, `darwin/`, `linux/` so
the split is visible from the overview.

- [ ] **Step 3: Update the generated-vs-linked table paths**

Every `nix/home/<x>.nix` reference in the "Generated vs linked" table now points
one level deeper. Update them:

| Old | New |
|---|---|
| `nix/home/shell.nix` | `nix/home/shared/shell.nix` |
| `nix/home/git.nix` | `nix/home/shared/git.nix` |
| `nix/home/tmux.nix` | `nix/home/shared/tmux.nix` |
| `nix/home/nvim.nix` | `nix/home/shared/nvim.nix` |
| `nix/home/alacritty.nix` | `nix/home/darwin/alacritty.nix` |
| `nix/home/java.nix` | `nix/home/darwin/java.nix` |

Also update the "Where things live" table and the "Background jobs" table, whose
`nix/home/karabiner.nix` and `nix/home/tmux.nix` references move to
`nix/home/darwin/karabiner.nix` and `nix/home/darwin/extras.nix`.

- [ ] **Step 4: Add the sub-project to `docs/nix-reproducibility-review.md`**

In the `## Tier 3: all complete` list, after the launchd entry, add:

```markdown
- ~~**Shared core across macOS and WSL.**~~ **Done.** nix/home split into
  shared, darwin and linux. The Mac's system hash was identical through both
  the file move and the platform split, which is what proved the refactor was
  behaviour-neutral. A second machine, x86_64-linux under WSL2, now shares git,
  zsh, tmux and neovim through a standalone home-manager output.
```

- [ ] **Step 5: Check every path the README names still exists**

The README references many files, and this task moved eight of them.
```bash
cd ~/dotfiles
for p in $(grep -oE '`nix/home/[a-z/]+\.nix`' README.md | tr -d '`' | sort -u); do
  [ -e "$p" ] || echo "MISSING: $p"
done
echo "(no output = every path in the README exists)"
grep -c "—" README.md docs/nix-reproducibility-review.md
```
Expected: no MISSING lines, and `0` em-dashes in both.

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles
git add README.md docs/nix-reproducibility-review.md
git commit -m "docs: document the WSL2 target and the shared/darwin/linux split

Adds the WSL bootstrap, including the two things that are discovered the hard
way otherwise: the first switch refuses to clobber the distro's .bashrc without
-b bak, and zsh gets installed without becoming the login shell.

Updates every nix/home path in the README, since eight files moved one level
deeper."
```

---

## Final verification

Run after all four tasks.

- [ ] **The Mac, end to end**

```bash
cd ~/dotfiles
export PATH="/run/current-system/sw/bin:$PATH"
out=$(nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths 2>/dev/null | tail -1)
[ "$out" = "$(readlink /run/current-system)" ] && echo "hash unchanged across all four tasks" || echo "HASH CHANGED"
bash nix/verify.sh all 2>&1 | tail -4
nvim --headless +qa && echo "nvim clean"
git status --short; echo "(clean if blank)"
```
Expected: hash unchanged, `PASSED`, `nvim clean`, clean tree.

Note that **no `darwin-rebuild switch` is needed** if the hash is unchanged: the
running system already is the built system. That is the point of the check.

- [ ] **The Linux target evaluates**

```bash
export PATH="/run/current-system/sw/bin:$PATH"
nix eval --raw '.#homeConfigurations."jose@RockemSockem".config.home.homeDirectory'
nix eval '.#homeConfigurations."jose@RockemSockem".config.home.packages' --apply 'builtins.length'
```
Expected: `/home/jose`, and a count of at least 12. The count will exceed 12
because `programs.*` modules add their own packages.

- [ ] **Report to Jose**

State plainly: the Mac's hash was unchanged through every task so no rebuild is
required; the Linux side is evaluated but unbuilt; and the two commands to run on
RockemSockem are the `-b bak` first switch and the `chsh`. Do not push.

---

## Notes for the implementer

**The hash check is the whole design.** Tasks 1 and 2 are deliberately separate
so that a hash change is attributable. If Task 1's hash changes, the move broke
something. If Task 2's changes, the split did. Do not proceed past a changed
hash by rationalising it.

**Why the mkOrder 1100 block was not split.** Its six items interleave two
macOS-only ones with four portable ones, so any split reorders the generated
`.zshrc`. That is why `linux/default.nix` duplicates about 12 lines instead. The
duplication is the deliberate price of the hash check.

**You cannot test the Linux side.** Resist the urge to try `nix build` on the
homeConfiguration. It will fail for want of an x86_64-linux builder, and that
failure means nothing about whether the config is correct.
