# home-manager Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add home-manager as a nix-darwin module, convert zsh/git/starship/alacritty to `programs.*` modules, move the remaining dotbot symlinks under home-manager, and delete dotbot.

**Architecture:** home-manager enters via `darwinModules.home-manager` inside `mkHost`, so every host gets it. A new `nix/home.nix` holds the link table and the four `programs.*` blocks. Links use `mkOutOfStoreSymlink` into `~/dotfiles` so edits need no rebuild; `~/.zshrc` is the deliberate exception since `programs.zsh` generates it.

**Tech Stack:** Nix flakes, nix-darwin 26.05, home-manager release-26.05, nixpkgs 26.05 (`aarch64-darwin`), zsh.

**Spec:** `docs/superpowers/specs/2026-08-09-home-manager-design.md`

## Global Constraints

- Repo is `~/dotfiles`, branch `main`. All paths relative to it.
- **`darwin-rebuild switch` requires sudo and cannot be run by an agent.** Always `nix build .#darwinConfigurations."REM-JoseS-MBP1".system --no-link` first to surface build errors, then hand the switch to Jose as `sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1` and wait for confirmation. Verify by comparing `readlink /run/current-system` to the built path; do not take "it worked" at face value.
- **Never `git add -A` or `git commit -a`.** Uncommitted WIP exists in `hammerspoon/appBundles.lua`, `hammerspoon/init.lua`, and `zsh/custom/aliases.zsh`. Stage explicit paths only. The hammerspoon WIP must survive this entire plan untouched.
- Flakes only read git-tracked files. `git add` any new file before building or the rebuild will not see it.
- Commit messages: no `Co-Authored-By` trailer.
- `homebrew.onActivation.cleanup` stays `"none"`.
- Do not push. Pushing is Jose's decision.

## File Structure

| File | Responsibility |
|---|---|
| `flake.nix` | **Modify.** Add `home-manager` input; add its darwin module to `mkHost` |
| `nix/configuration.nix` | **Modify.** home-manager wiring; remove the `pathsToLink` workaround |
| `nix/home.nix` | **Create.** Link table plus four `programs.*` blocks |
| `nix/packages.nix` | **Modify.** Remove the two zsh plugin packages |
| `nix/verify.sh` | **Modify.** Add a `links` batch |
| `install.conf.yaml`, `install` | **Delete** in Task 4 |
| `README.md` | **Modify.** Remove the `./install` step |

## Rollback

Tasks 1 to 3 are reversible: dotbot is still in the repo, so `sudo darwin-rebuild switch --rollback` followed by `cd ~/dotfiles && ./install` restores the previous state. After Task 4 deletes dotbot, recovery is `git revert` of that commit plus a rebuild.

If the shell breaks (the risk in Task 3), `zsh -f` starts without rc files and `/bin/bash` is untouched.

---

### Task 1: home-manager foundation and the link table

No configs are converted here. This proves home-manager can take over dotbot's symlinks without changing any behaviour.

**Files:**
- Modify: `flake.nix`
- Modify: `nix/configuration.nix`
- Create: `nix/home.nix`
- Modify: `nix/verify.sh`

**Interfaces:**
- Produces: `nix/home.nix` exporting a `link` helper used by all later tasks, and `nix/verify.sh links` asserting the nine paths resolve into `~/dotfiles`.

- [ ] **Step 1: Add the links batch to `nix/verify.sh`**

Insert after the `batch6` definition:

```bash
# Paths home-manager should symlink back into ~/dotfiles.
links=("$HOME/.tmux.conf" "$HOME/.tmux" "$HOME/.hammerspoon"
       "$HOME/.amethyst.yml" "$HOME/.hushlogin" "$HOME/.bin"
       "$HOME/.config/nvim" "$HOME/.config/karabiner.edn"
       "$HOME/.config/karabiner/karabiner.edn")
```

Then add this function after `check()`:

```bash
check_link() {
  local p="$1" target
  if [ ! -L "$p" ]; then
    printf 'NOT LINK  %s\n' "$p"
    fail=1
    return
  fi
  target="$(readlink "$p")"
  case "$target" in
    "$HOME"/dotfiles/*)
      printf 'OK        %-34s -> %s\n' "$p" "$target"
      ;;
    /nix/store/*)
      printf 'IN STORE  %-34s -> %s (mkOutOfStoreSymlink missed)\n' "$p" "$target"
      fail=1
      ;;
    *)
      printf 'WRONG     %-34s -> %s\n' "$p" "$target"
      fail=1
      ;;
  esac
}
```

And add a `links` branch to the dispatcher, replacing the `if` block at the bottom:

```bash
if [ "${1:-all}" = links ]; then
  printf '=== links ===\n'
  for p in "${links[@]}"; do check_link "$p"; done
elif [ "${1:-all}" = all ]; then
  for i in 0 1 2 3 4 5 6; do run_batch "$i"; done
  printf '=== links ===\n'
  for p in "${links[@]}"; do check_link "$p"; done
else
  run_batch "$1"
fi
```

- [ ] **Step 2: Run it to confirm it currently passes for the wrong reason**

```bash
cd ~/dotfiles && nix/verify.sh links
```

Expected: PASS. dotbot's links already point into `~/dotfiles`, so this is the baseline. The check proves the target shape, not who created it. Task 1 keeps it passing while changing the owner.

- [ ] **Step 3: Add the home-manager input to `flake.nix`**

In `inputs`, after the `nix-homebrew` line:

```nix
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
```

And add `home-manager` to the `outputs` function arguments:

```nix
  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
```

Forgetting the argument gives `error: undefined variable 'home-manager'`.

- [ ] **Step 4: Add the module to `mkHost`**

In the `modules` list inside `mkHost`, after the nix-homebrew block's closing `}`:

```nix
        home-manager.darwinModules.home-manager
```

- [ ] **Step 5: Wire home-manager in `nix/configuration.nix`**

Add after the `system.stateVersion` line:

```nix
  # home-manager manages files in $HOME. nix-darwin manages the machine.
  # useGlobalPkgs makes it share this system's nixpkgs instead of
  # instantiating a second one.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # dotbot already owns these paths; without this, activation aborts with
    # "would be clobbered". Backups are deleted in Task 4.
    backupFileExtension = "hm-bak";
    users.jose = import ./home.nix;
  };
```

- [ ] **Step 6: Create `nix/home.nix` with links only**

```nix
{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  # Out-of-store symlink: points at the live repo, so edits take effect
  # immediately with no rebuild. A plain `source = ./path` would copy into
  # /nix/store and make the file read-only.
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.stateVersion = "26.05";

  # XDG is off by default on darwin. Without this, every xdg.configFile
  # entry below silently does nothing.
  xdg.enable = true;

  home.file = {
    ".tmux.conf".source = link "tmux.conf";
    # tpm writes plugins/ here, so it must stay out-of-store.
    ".tmux".source = link "tmux";
    # Hammerspoon writes Spoons/ here.
    ".hammerspoon".source = link "hammerspoon";
    ".amethyst.yml".source = link "amethyst/amethyst.yml";
    ".hushlogin".source = link "hushlogin";
    ".bin".source = link "bin";
  };

  xdg.configFile = {
    # lazy.nvim writes lazy-lock.json here.
    "nvim".source = link "nvim";
    # Linked to both paths because that is goku's search path. Preserved
    # exactly as dotbot had it.
    "karabiner.edn".source = link "karabiner/karabiner.edn";
    "karabiner/karabiner.edn".source = link "karabiner/karabiner.edn";
  };
}
```

- [ ] **Step 7: Stage and build**

```bash
cd ~/dotfiles
git add flake.nix nix/configuration.nix nix/home.nix nix/verify.sh
nix build .#darwinConfigurations.\"REM-JoseS-MBP1\".system --no-link --print-out-paths
```

Expected: a `/nix/store/...-darwin-system-...` path. Record it for Step 8.

- [ ] **Step 8: Hand the rebuild to Jose**

Ask Jose to run:

```
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

Wait for confirmation, then verify it actually landed:

```bash
readlink /run/current-system
```

Expected: matches the path from Step 7. If it does not, the switch did not happen; do not proceed.

- [ ] **Step 9: Verify home-manager owns the links now**

```bash
cd ~/dotfiles && nix/verify.sh links
ls -la ~/*.hm-bak ~/.config/*.hm-bak 2>/dev/null
```

Expected: `links` PASSES, and `.hm-bak` files exist, proving home-manager took over rather than silently doing nothing.

- [ ] **Step 10: Confirm nothing behavioural broke**

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'echo SHELL_OK' 2>&1 | grep -v starship
tmux new-session -d -s hmtest && tmux ls && tmux kill-session -t hmtest
nvim --headless +qa 2>&1 | head -5
```

Expected: `SHELL_OK` with no errors, tmux session created and killed cleanly, nvim exits silently.

- [ ] **Step 11: Commit**

```bash
git add flake.nix nix/configuration.nix nix/home.nix nix/verify.sh
git commit -m "Add home-manager and move dotbot symlinks under it"
```

---

### Task 2: Convert git, starship, and alacritty

Three mechanical conversions. Each is verified by comparing generated output against the file it replaces.

**Files:**
- Modify: `nix/home.nix`

**Interfaces:**
- Consumes: the `link` helper and module skeleton from Task 1.
- Produces: `~/.config/git/config`, `~/.config/git/ignore`,
  `~/.config/starship.toml`, `~/.config/alacritty/alacritty.toml` as generated
  files.

**Note the git path.** With `xdg.enable = true`, home-manager writes
`~/.config/git/config`, **not** `~/.gitconfig`. Those are different files and
git reads both, with `~/.gitconfig` taking precedence for any overlapping key.
A stale `~/.gitconfig` therefore silently shadows the generated config. Step 8a
removes it. Starship and alacritty do not have this problem: home-manager
writes them to the same paths dotbot used, so `backupFileExtension` moves the
old ones aside automatically.

- [ ] **Step 1: Capture the current behaviour to compare against**

```bash
cd ~/dotfiles
git config --get user.email > /tmp/hm-before-email
git config --get init.defaultBranch > /tmp/hm-before-branch
git config --get filter.lfs.clean > /tmp/hm-before-lfs
cat /tmp/hm-before-email /tmp/hm-before-branch /tmp/hm-before-lfs
```

Expected: `josecanhelp@gmail.com`, `main`, `git-lfs clean -- %f`.

- [ ] **Step 2: Add `programs.git` to `nix/home.nix`**

Insert before the closing `}`:

```nix
  programs.git = {
    enable = true;
    userName = "Jose Soto";
    userEmail = "josecanhelp@gmail.com";
    # Generates the entire [filter "lfs"] block.
    lfs.enable = true;
    # Writes ~/.config/git/ignore, which git reads via XDG. This replaces
    # ~/.gitignore_global, which was never tracked in this repo and would
    # be missing on a new machine. core.excludesfile is dropped, not
    # repointed, because it hardcoded /Users/jose.
    ignores = [
      ".DS_Store"
      ".vscode/*"
      ".secrets"
      "CLAUDE.md"
      "scratch*.md"
      "**/.claude/settings.local.json"
    ];
    extraConfig = {
      github.user = "josecanhelp";
      init.defaultBranch = "main";
      pull.rebase = false;
      color.ui = "auto";
      status.short = true;
      help.autocorrect = 1;
      core.editor = "vim";
      credential.helper = "osxkeychain";
      mergetool = {
        prompt = false;
        keepBackup = false;
      };
      # Percent signs are literal in Nix, but keep this on one line so the
      # colour codes are not broken by wrapping.
      format.pretty = "format:%Cblue%h%Creset %Creset%Cgreen%cn, %cr%Creset : %s%Creset%C(red)%d%Creset";
    };
  };
```

- [ ] **Step 3: Add `programs.starship`**

```nix
  programs.starship = {
    enable = true;
    # Adds the init line to the .zshrc home-manager will own in Task 3.
    # Until then it is inert, because zshrc is still hand-written.
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 500;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
      package.disabled = true;
      aws.disabled = true;
      python = {
        symbol = "🐍 ";
        # Nix indented string: backslashes stay literal, matching the TOML
        # single-quoted original. A double-quoted Nix string would treat
        # \( as an escape and silently change the prompt.
        format = ''via [$symbol$version( \($virtualenv\))]($style) '';
        style = "yellow bold";
        detect_files = [
          "pyproject.toml"
          ".python-version"
          "uv.lock"
          "requirements.txt"
          "Pipfile"
        ];
        detect_folders = [ ".venv" ];
      };
      nodejs.symbol = "⬢ ";
      conda = {
        format = "[$symbol$environment](dimmed green) ";
        symbol = "🅒 ";
      };
    };
  };
```

- [ ] **Step 4: Add `programs.alacritty`**

```nix
  programs.alacritty = {
    enable = true;
    # Alacritty itself comes from the Homebrew cask. `package = null` is
    # supported (the option is declared nullable) and installs nothing,
    # while still writing the config file.
    #
    # Do NOT use `enable = false` here: the module body is wrapped in
    # `lib.mkIf cfg.enable`, so disabling it writes no config at all.
    package = null;
    settings = {
      general = {
        # Do NOT use the module's `theme` option here. With `package = null`
        # it evaluates `cfg.package.version` unguarded and dies with
        # "expected a set but found null" (alacritty.nix:95). The module's
        # own docs point at settings.general.import for this case.
        #
        # Versioned by flake.lock. Replaces the import of
        # alacritty/alacritty-theme/, a gitignored clone that would not
        # exist on a new machine.
        import = [
          "${pkgs.alacritty-theme}/share/alacritty-theme/seashells.toml"
        ];
        # Boolean, and under [general]. In the source TOML this line sits
        # after [env] with no table header, so it parsed as
        # env.live_config_reload = "true" (a string) and never worked.
        live_config_reload = true;
      };
      env.TERM = "alacritty";
      font = {
        size = 16;
        normal.family = "FiraCode Nerd Font Mono";
        bold.style = "Regular";
        glyph_offset.y = 7;
        offset.y = 12;
      };
      window = {
        decorations = "Full";
        dynamic_padding = true;
        padding = { x = 0; y = 0; };
      };
      terminal.shell = {
        program = "/bin/zsh";
        args = [ "-l" "-c" "tmux attach || tmux" ];
      };
    };
  };
```

`enable = false` with `settings` set still writes the config file but does not add the `alacritty` package, which would collide with the cask.

- [ ] **Step 5: Remove the three files from the dotbot link list**

In `install.conf.yaml`, delete these three lines from the `link:` block so dotbot stops fighting home-manager for them:

```yaml
    ~/.config/alacritty/alacritty.toml: alacritty/alacritty.toml
    ~/.config/starship.toml: starship.toml
    ~/.gitconfig: gitconfig
```

- [ ] **Step 6: Stage and build**

```bash
cd ~/dotfiles
git add nix/home.nix install.conf.yaml
nix build .#darwinConfigurations.\"REM-JoseS-MBP1\".system --no-link --print-out-paths
```

- [ ] **Step 7: Hand the rebuild to Jose, then confirm it landed**

```
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

```bash
readlink /run/current-system
```

Expected: matches Step 6's path.

- [ ] **Step 8a: Remove the stale `~/.gitconfig` before verifying anything**

`~/.gitconfig` is a dotbot symlink to `~/dotfiles/gitconfig`. home-manager
writes `~/.config/git/config` instead, and git gives `~/.gitconfig`
precedence, so leaving it in place makes the new config inert.

Confirm the situation, then remove it:

```bash
ls -l ~/.gitconfig
git config --show-origin --get core.excludesfile
```

Expected: a symlink into `~/dotfiles`, and `core.excludesfile` resolving from
`file:/Users/jose/.gitconfig`. Then:

```bash
rm ~/.gitconfig
git config --show-origin --get user.email
```

Expected: now resolves from `file:/Users/jose/.config/git/config`. Nothing
recreates `~/.gitconfig`, because Step 5 already removed it from
`install.conf.yaml`.

If `core.excludesfile` still returns a value after this, the old file is still
being read somewhere; stop and investigate rather than continuing.

- [ ] **Step 8: Diff generated output against the originals**

```bash
cd ~/dotfiles
git config --show-origin --get user.email
diff <(git config --get user.email) /tmp/hm-before-email && echo "email OK"
diff <(git config --get init.defaultBranch) /tmp/hm-before-branch && echo "branch OK"
git config --get core.excludesfile || echo "excludesfile correctly gone"
git config --get filter.lfs.clean
git config --get format.pretty
cat ~/.config/git/ignore
```

Expected: two OKs, `format.pretty` matching the original exactly, and the six
ignore entries present.

`filter.lfs.clean` is checked by eye, not diffed. `lfs.enable = true` renders
it as an absolute `/nix/store/.../bin/git-lfs` path rather than the bare
`git-lfs` string it was before. That is equivalent behaviour and arguably
better, since the binary is now pinned, but it will not string-match the
captured baseline. Confirm it ends in `/bin/git-lfs clean -- %f`.

```bash
grep -c . ~/.config/starship.toml
grep "virtualenv" ~/.config/starship.toml
```

Expected: the python format line reads `via [$symbol$version( \($virtualenv\))]($style)` with backslashes intact. If the backslashes are gone, the Nix string was double-quoted; fix and rebuild.

```bash
grep import ~/.config/alacritty/alacritty.toml
ls "$(grep -oE '/nix/store[^"]+seashells.toml' ~/.config/alacritty/alacritty.toml)"
```

Expected: the import points into `/nix/store` and that file exists.

- [ ] **Step 9: Commit**

```bash
git add nix/home.nix install.conf.yaml
git commit -m "Convert git, starship, and alacritty to home-manager modules"
```

---

### Task 3: Convert zsh

The highest-risk task. It replaces the shell you are working in.

**Files:**
- Modify: `nix/home.nix`
- Modify: `nix/packages.nix`
- Modify: `nix/configuration.nix`
- Delete: `zsh/custom/aliases.zsh`

**Interfaces:**
- Consumes: the module skeleton from Task 1 and `programs.starship.enableZshIntegration` from Task 2, which only becomes functional once home-manager owns `.zshrc`.

- [ ] **Step 1: Snapshot current shell behaviour**

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'alias' 2>/dev/null | sort > /tmp/hm-aliases-before
wc -l /tmp/hm-aliases-before
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'echo $EDITOR $LANG $KEYTIMEOUT' 2>/dev/null
```

Record the counts and values. Step 9 diffs against this.

- [ ] **Step 2: Add `programs.zsh` to `nix/home.nix`**

```nix
  programs.zsh = {
    enable = true;

    # Write ~/.zshrc, not ~/.config/zsh/.zshrc.
    #
    # home-manager 26.05 changed this default: with `xdg.enable = true` and
    # stateVersion >= 26.05 it now uses $XDG_CONFIG_HOME/zsh and sets ZDOTDIR
    # to point there. That also moves where zsh looks for .zprofile, and
    # ~/.zprofile here is load-bearing: it runs `brew shellenv` and the
    # Amazon Q blocks. Under the XDG layout zsh would look for
    # ~/.config/zsh/.zprofile, find nothing, and /opt/homebrew/bin would
    # silently drop off PATH, taking themekit, ecsplorer, msodbcsql17 and
    # the cask CLIs with it.
    #
    # This is the module's own documented way to keep the previous layout.
    dotDir = config.home.homeDirectory;

    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
    };
    syntaxHighlighting.enable = true;
    defaultKeymap = "viins";

    sessionVariables = {
      EDITOR = "nvim";
      LANG = "en_US.UTF-8";
      SAM_CLI_TELEMETRY = "0";
      KEYTIMEOUT = "1";
      ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX = "YES";
      JAVA_HOME = "/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      # ripgrep, not ag: the previous value referenced `ag`, which is not
      # installed, so fzf's Ctrl-T has been silently broken.
      FZF_DEFAULT_COMMAND = "rg --files --hidden --glob '!.git'";
      FZF_CTRL_T_COMMAND = "rg --files --hidden --glob '!.git'";
      # Quotes deliberately omitted around the --color and --bind values.
      # home-manager interpolates sessionVariables into a double-quoted
      # export without escaping, so embedded quotes are stripped by the
      # shell anyway. fzf's tokenizer strips quotes too, so the effective
      # value is identical either way; writing it unquoted makes the Nix
      # source, the generated export, and the effective value agree.
      FZF_DEFAULT_OPTS = "--preview-window right:50%:noborder:hidden --color preview-bg:234 --bind alt-p:toggle-preview";
    };

    shellAliases = {
      heroky = "heroku";
      glog = "git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative";
      gp = "git push origin HEAD";
      gd = "git diff";
      gac = "git add -A && git commit -m";
      gco = "git checkout";
      guncommit = "git reset HEAD~1";
      art = "php artisan";
      ee = "cd ~/Code/engineering_department/";
      tt = "cd ~/Code/Converge/";
      jj = "cd ~/Code/JoseCanHelp/";
      dot = "cd ~/dotfiles";
      gsa = "git submodule add";
      vs = "vagrant status";
      vu = "vagrant up";
      vh = "vagrant halt";
      vd = "vagrant destroy";
      cda = "composer dump-autoload";
      dpostgres = "docker run --name postgres -v data:/var/lib/postgresql/data -e POSTGRES_USER=perk -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=myapp -p 5432:5432 -d postgres";
      dmysql = "docker run --name mysql -v mysql_data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=secret -p 3306:3306 -d mysql:5.7";
      artclear = "php artisan cache:clear && php artisan config:clear && php artisan view:clear && php artisan route:clear";
      cl = "clear";
      nah = "git reset --hard && git clean -df";
      wip = "git add . && git commit -m 'WIP'";
      wipa = "git add . && git commit --amend -m 'WIP'";
      gempty = "git commit --allow-empty -m 'Empty Commit'";
      phpunit = "./vendor/bin/phpunit";
      nrs = "npm run serve";
      nrw = "npm run watch";
      nrd = "npm run dev";
      nrb = "npm run build";
      # Was `vim ~/.zshrc`, which home-manager now generates read-only.
      editzshrc = "vim ~/dotfiles/nix/home.nix";
      mutt = "neomutt";
      dockerps = "docker ps --format \"table {{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Ports}}\"";
      dp = "dockerps";
      dockerpsa = "docker ps -a --format \"table {{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Ports}}\"";
      dpa = "dockerpsa";
      dvp = "docker volume prune";
      l = "ls -alh";
      src = "exec zsh";
      ".." = "cd ..";
      zz = "z -c";
      zi = "z -i";
      zf = "z -I";
      zb = "z -b";
      pb = "pianobar";
      pad = "php artisan dusk";
      jig = "./vendor/bin/jigsaw";
      to = "./bin/run";
      tinkpw = "php artisan tinker --execute=\"echo bcrypt('password')\" | pbcopy";
      lll = "ranger";
      vimlog = "nvim -V9myNvim.log .";
      forceprune = "docker volume prune --force && docker system prune --force";
      pest = "./vendor/bin/pest";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      sup = "./vendor/bin/sail up -d";
      stp = "./vendor/bin/sail test -p";
      sail = "[ -f sail ] && bash sail || bash vendor/bin/sail";
      strap = "[ -f strap ] && bash strap || bash ./bin/strap";
      gdesc = "git log --no-merges --pretty=format:'- %s' master.. | pbcopy";
      gitamend = "git commit --amend";
      ghweb = "gh repo view --web";
      ghopen = "gh repo view --web";
      ecrlogin = "aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/v9v6w9r0";
      sss = "myssh";
      aa = "cd ~/Code/AWS";
      kube = "kubectl";
      gitprune = "git branch --merged | egrep -v \"(^\\*|master|main|dev)\" | xargs git branch -d && git remote prune origin";
      findlargedir = "find ./  -maxdepth 1 -mindepth 1  -type d  -exec du -hs {} \\;| sort -rh | head -n 1";
      kubectl = "minikube kubectl --";
      javahome = "java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'";
      setjava8 = "export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home";
      smfs = "./vendor/bin/sail artisan migrate:fresh --seed";
      # `mfs` was defined twice in aliases.zsh. zsh silently kept the last
      # definition; a Nix attrset would be an evaluation error. The last
      # one wins here too, preserving current behaviour.
      mfs = "sail artisan migrate:fresh";
      mfss = "sail artisan migrate:fresh --seed";
      arl = "sail artisan route:list";
      vim = "nvim";
      python = "python3";
    };

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        [ -f ~/.secrets ] && source ~/.secrets

        # MUST be before compinit, which home-manager's enableCompletion
        # runs early in the generated .zshrc. In the original zshrc this
        # line sat immediately before a second manual compinit; that second
        # call existed precisely to pick these up. fpath mutations after
        # compinit are ignored, so `docker <TAB>` would silently stop
        # completing. home-manager's own `typeset -U ... fpath` de-dupes
        # rather than resets, so prepending here is safe.
        fpath=(/Users/jose/.docker/completions $fpath)
      '')

      ''
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
      ''

      (lib.mkAfter ''
        export PATH=''${PATH}:~/.composer/vendor/bin
        export PATH=''${PATH}:~/.dotfiles/bin
        export PATH=''${PATH}:~/.local/bin
        export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

        # Nix must win over Homebrew. brew shellenv in ~/.zprofile prepends
        # /opt/homebrew/bin. This runs last, so it wins.
        export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
      '')
    ];
  };
```

Note `''${PATH}` : in a Nix indented string, `''${` escapes what would otherwise be Nix interpolation.

Aliases deliberately dropped, all approved in the spec or made obsolete here:
`gsup` (quoting behaviour change), `gs` (commented out in your working tree),
`updatedotbot` (references the submodule Task 4 deletes), `editalias`
(pointed at `~/.oh-my-zsh-custom/`, which does not exist), `runprod`
(400-character classpath better kept as a script than an alias; it stays
available in git history).

- [ ] **Step 3: Remove the zsh plugin packages from `nix/packages.nix`**

Delete these two lines from the `shell` group:

```nix
    zsh-autosuggestions
    zsh-syntax-highlighting
```

home-manager references the plugin store paths directly, so the system copies are redundant.

- [ ] **Step 4: Remove the now-unnecessary `pathsToLink` workaround**

In `nix/configuration.nix`, delete the `environment.pathsToLink` block and its comment. It existed only so the system profile exposed
`/share/zsh-syntax-highlighting`, which home-manager does not use.

- [ ] **Step 5: Remove zshrc and aliases from dotbot**

In `install.conf.yaml`, delete this line:

```yaml
    ~/.zshrc: zsh/zshrc
```

- [ ] **Step 6: Stage and build**

```bash
cd ~/dotfiles
git add nix/home.nix nix/packages.nix nix/configuration.nix install.conf.yaml
nix build .#darwinConfigurations.\"REM-JoseS-MBP1\".system --no-link --print-out-paths
```

Expected: builds. A duplicate key in `shellAliases` fails here with
`attribute '<name>' already defined`, which is why the build runs before the switch.

- [ ] **Step 7: Hand the rebuild to Jose, then confirm it landed**

Warn Jose first: this replaces `~/.zshrc`. Their current shell is unaffected; new shells use the generated file.

```
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

```bash
readlink /run/current-system
ls -l ~/.zshrc
```

Expected: the system path matches Step 6, and `~/.zshrc` is now a symlink into `/nix/store`.

- [ ] **Step 8: Verify the shell starts cleanly before anything else**

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'echo SHELL_OK' 2>&1 | grep -v starship
```

Expected: `SHELL_OK` with no error lines. If there are errors, fix them before continuing; `zsh -f` gives you a working shell in the meantime.

- [ ] **Step 9: Diff the alias set against the snapshot**

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'alias' 2>/dev/null | sort > /tmp/hm-aliases-after
diff /tmp/hm-aliases-before /tmp/hm-aliases-after
```

Expected: exactly five differences, no more.

Four aliases removed: `gsup`, `updatedotbot`, `editalias`, `runprod`.
One alias changed: `editzshrc`, now pointing at `~/dotfiles/nix/home.nix`.

`gs` does not appear because it is already commented out in the working
tree, so it was never in the before-snapshot either. That commented-out
state is what the conversion preserves by omitting it.

The source file defines 83 unique aliases; `shellAliases` defines 79.
Any difference beyond those five is a transcription error; fix it before
committing.

- [ ] **Step 10: Verify the interactive features**

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'echo $EDITOR $LANG $KEYTIMEOUT; echo $FZF_DEFAULT_COMMAND' 2>/dev/null
grep -c "zsh-autosuggestions" ~/.zshrc
grep -c "zsh-syntax-highlighting" ~/.zshrc
grep -c "starship init" ~/.zshrc
```

Expected: `nvim en_US.UTF-8 1`, the ripgrep command, and a non-zero count for each of the three greps, proving home-manager wired the plugins and starship.

- [ ] **Step 11: Delete the converted files and commit**

Remove them one at a time. `git rm a b` is atomic: if either path fails the
whole command aborts and neither is removed, which is confusing mid-task.

```bash
cd ~/dotfiles
git rm zsh/zshrc
```

Expected: succeeds. `zsh/zshrc` has no uncommitted changes.

```bash
git rm zsh/custom/aliases.zsh
```

Expected: **fails** with "has local modifications". That refusal is the
safety check. It confirms the file carries the uncommitted WIP that Step 2
absorbed (the `gs` alias omitted from `shellAliases`).

Re-read Step 2's alias list and confirm `gs` is absent from it, then force:

```bash
git rm -f zsh/custom/aliases.zsh
```

```bash
git add nix/home.nix nix/packages.nix nix/configuration.nix install.conf.yaml
git commit -m "Convert zsh to home-manager, absorbing aliases and plugin wiring"
```

---

### Task 4: Retire dotbot

**Files:**
- Delete: `install.conf.yaml`, `install`, `dotbot/`, `dotbot-pip/`, `alacritty/alacritty-theme/`
- Modify: `.gitmodules`, `.gitignore`, `README.md`

- [ ] **Step 1: Confirm nothing still depends on dotbot**

```bash
cd ~/dotfiles
cat install.conf.yaml
grep -rn "dotbot" --include="*.md" --include="*.nix" --include="*.zsh" . | grep -v "^./docs/" | grep -v "^./dotbot"
```

Expected: `install.conf.yaml` still lists the six `home.file` paths plus the three `xdg.configFile` ones, all now also managed by home-manager. No live references outside `docs/` and the submodule itself.

- [ ] **Step 2: Remove the submodules**

```bash
cd ~/dotfiles
git submodule deinit -f dotbot dotbot-pip
git rm -f dotbot dotbot-pip
rm -rf .git/modules/dotbot .git/modules/dotbot-pip
```

- [ ] **Step 3: Delete the dotbot entrypoints, the vendored theme, and dead code**

```bash
cd ~/dotfiles
git rm -f install.conf.yaml install
rm -rf alacritty/alacritty-theme
```

`zsh/custom/artisan.plugin.zsh` is dead code: a repo-wide search finds no
reference to it outside its own header comment, so nothing has ever sourced it.
Confirm that is still true, then remove it:

```bash
grep -rn "artisan.plugin" --include="*.zsh" --include="*.nix" --include="*.yaml" . \
  | grep -v "^./docs/" | grep -v "^./.superpowers/" \
  || echo "no references, safe to remove"
git rm zsh/custom/artisan.plugin.zsh
```

Expected: the grep prints only the file's own header comment line, or nothing.
If it prints a real reference, stop and investigate rather than deleting.

- [ ] **Step 4: Remove the theme's gitignore entry**

In `.gitignore`, delete this line:

```
alacritty/alacritty-theme/
```

- [ ] **Step 5: Verify `.gitmodules` has only the theme left**

```bash
cat .gitmodules
```

Expected: a single entry, `themes/tomorrow-theme`. If `dotbot` entries remain, `git rm` did not update it; remove them by hand.

- [ ] **Step 6: Update the README bootstrap**

In `README.md`, delete step 4 entirely:

```markdown
4. **Link the dotfiles** that Nix does not manage yet.

   ```sh
   cd ~/dotfiles && ./install
   ```
```

Renumber step 5 to 4. Then in the "How this is managed" section, delete the dotbot table row and replace the sentence below it:

```markdown
The plan is for home-manager to take over that third row. Until then, `./install` is still a required step on a new machine.
```

with:

```markdown
Every file is managed by one of these three. A new machine needs nothing beyond a clone and a rebuild.
```

Change the `dotbot` table row to:

```markdown
| **home-manager** | Symlinking config files into `$HOME`, plus zsh, git, starship, alacritty | `nix/home.nix` |
```

- [ ] **Step 7: Clean up the backup files**

```bash
rm -f ~/*.hm-bak ~/.config/*.hm-bak ~/.config/karabiner/*.hm-bak
ls ~/*.hm-bak 2>/dev/null || echo "backups cleared"
```

- [ ] **Step 8: Full verification**

```bash
cd ~/dotfiles
nix/verify.sh all
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'echo SHELL_OK; alias | wc -l' 2>&1 | grep -v starship
tmux new-session -d -s hmtest && tmux ls && tmux kill-session -t hmtest
nvim --headless +qa 2>&1 | head -5
git config --get user.email
```

Expected: all batches and `links` PASS, `SHELL_OK` with an alias count matching Step 9 of Task 3, tmux and nvim clean, and the git email correct.

- [ ] **Step 9: Confirm the build is unchanged by the deletions**

```bash
nix build .#darwinConfigurations.\"REM-JoseS-MBP1\".system --no-link --print-out-paths
readlink /run/current-system
```

Expected: identical paths. Deleting dotbot changes nothing Nix builds, so no rebuild is needed. If they differ, something in `nix/` was touched unintentionally.

- [ ] **Step 10: Commit**

```bash
cd ~/dotfiles
git add -u
git add .gitignore .gitmodules README.md
git status --short
```

Confirm `hammerspoon/appBundles.lua` and `hammerspoon/init.lua` are still listed as unstaged modifications. If they are staged, unstage them with `git restore --staged hammerspoon/` before committing.

```bash
git commit -m "Retire dotbot in favour of home-manager"
```

- [ ] **Step 11: Report**

Summarise for Jose: files removed, what home-manager now owns, and that `README.md` bootstrap is down to clone plus rebuild. Do not push.
