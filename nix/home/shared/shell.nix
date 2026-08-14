{ config, lib, ... }:

{
  programs.starship = {
    enable = true;
    # Adds the init line to the .zshrc home-manager generates. This only
    # works because programs.zsh owns that file; with a hand-written
    # zshrc the option silently does nothing.
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
    };
  };

  # fzf's own module, replacing three hand-written FZF_* exports and a manual
  # `eval "$(fzf --zsh)"` that was duplicated in darwin/extras.nix and
  # linux/default.nix. The module emits both, so neither is written by hand.
  #
  # Three things move as a result. All are deliberate, and none change what
  # fzf actually does:
  #
  #   1. The exports land in home.sessionVariables instead of
  #      programs.zsh.sessionVariables. Both end up in ~/.zshenv: the former
  #      via the hm-session-vars.sh line at the top, the latter written inline
  #      below it. Both still run before ~/.zshrc, so fzf sees them.
  #   2. The integration is emitted at mkOrder 910 rather than sitting at the
  #      end of the 1100 block, so it now runs BEFORE the bindkeys there
  #      instead of after. Inert: fzf binds ^T, ^R and alt-c against named
  #      keymaps (emacs, viins, vicmd), and nothing in the 1100 block touches
  #      those three.
  #   3. The integration calls fzf by absolute store path instead of by name,
  #      so it no longer depends on PATH being correct at that point.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # ripgrep, not ag: the value this replaced referenced `ag`, which is not
    # installed, so fzf's Ctrl-T had been silently broken.
    #
    # The single quotes survive into ~/.zshenv as literals inside a
    # double-quoted export. fzf runs the command through a shell, which strips
    # them, so the glob reaches ripgrep intact.
    defaultCommand = "rg --files --hidden --glob '!.git'";
    fileWidgetCommand = "rg --files --hidden --glob '!.git'";

    defaultOptions = [
      "--preview-window right:50%:noborder:hidden"
      "--bind alt-p:toggle-preview"
    ];

    # Renders as `--color preview-bg:234`, appended after defaultOptions.
    # That flag used to sit between the other two. fzf does not care about
    # option order, and with no repeated flag there is nothing to override.
    colors.preview-bg = "234";
  };

  programs.zsh = {
    enable = true;

    # Write ~/.zshrc and ~/.zprofile, not ~/.config/zsh/.
    #
    # home-manager 26.05 changed this default: with `xdg.enable = true` and
    # stateVersion >= 26.05 it now uses $XDG_CONFIG_HOME/zsh and sets ZDOTDIR
    # to point there. Keeping the traditional layout matters because zsh
    # resolves .zprofile relative to ZDOTDIR too, and macOS itself writes to
    # ~/ rather than the XDG path. This is the module's own documented way
    # to keep the previous layout.
    dotDir = config.home.homeDirectory;

    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
    };
    syntaxHighlighting.enable = true;
    defaultKeymap = "viins";

    sessionVariables = {
      LANG = "en_US.UTF-8";
      SAM_CLI_TELEMETRY = "0";
      KEYTIMEOUT = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";

      # Local code root, not the Converge subdirectory. engineering_department
      # documents this convention in SETUP.md and builds paths as
      # $CONVERGE_CODE/Converge/<repo>, so pointing it one level deeper would
      # resolve to .../Converge/Converge. Claude Code expands ${CONVERGE_CODE}
      # in .mcp.json, which is how that repo locates the mcp-servers checkout.
      #
      # Belongs here rather than in ~/.secrets because it is a path, not a
      # credential, so it can live in the repo instead of an untracked file.
      # Both reach non-interactive shells now that envExtra below sources
      # ~/.secrets from ~/.zshenv.
      CONVERGE_CODE = "$HOME/Code";
      # The FZF_* variables used to live here. programs.fzf above owns them now.
    };

    # ~/.secrets is sourced here rather than from initContent because envExtra
    # writes to ~/.zshenv, which every zsh reads, while initContent writes to
    # ~/.zshrc, which only interactive ones read. MCP server definitions in
    # ~/.claude.json and .mcp.json reference these as ${VAR}, and Claude Code
    # resolves them from its own environment. A `claude` started by cron, a
    # scheduled routine, or any other non-interactive parent inherited none of
    # them from .zshrc, so those servers failed to start with no useful error.
    #
    # The tradeoff is deliberate: the keys are now in the environment of every
    # non-interactive zsh, including script and git-hook subshells, not just
    # login terminals.
    #
    # Safe in .zshenv only because ~/.secrets is exports and comments with no
    # output. Anything that prints here corrupts scp, rsync and non-interactive
    # ssh, which parse the stream. The `[ -f ]` guard keeps a machine without
    # the file working; the file is deliberately outside the dotfiles repo.
    envExtra = ''
      [ -f ~/.secrets ] && source ~/.secrets
    '';

    shellAliases = {
      heroky = "heroku";
      glog = "git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative";
      gp = "git push origin HEAD";
      gd = "git diff";
      gs = "git status";
      gac = "git add -A && git commit -m";
      gco = "git checkout";
      guncommit = "git reset HEAD~1";
      ee = "cd ~/Code/engineering_department/";
      tt = "cd ~/Code/Converge/";
      jj = "cd ~/Code/JoseCanHelp/";
      dot = "cd ~/dotfiles";
      gsa = "git submodule add";
      vs = "vagrant status";
      vu = "vagrant up";
      vh = "vagrant halt";
      vd = "vagrant destroy";
      dpostgres = "docker run --name postgres -v data:/var/lib/postgresql/data -e POSTGRES_USER=perk -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=myapp -p 5432:5432 -d postgres";
      dmysql = "docker run --name mysql -v mysql_data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=secret -p 3306:3306 -d mysql:5.7";
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
      editzshrc = "vim ~/dotfiles/nix/home/shared/shell.nix";
      mutt = "neomutt";
      dockerps = "docker ps --format \"table {{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Ports}}\"";
      dp = "dockerps";
      dockerpsa = "docker ps -a --format \"table {{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Ports}}\"";
      dpa = "dockerpsa";
      dvp = "docker volume prune";
      l = "ls -alh";
      src = "exec zsh";
      ".." = "cd ..";
      pb = "pianobar";
      jig = "./vendor/bin/jigsaw";
      to = "./bin/run";
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
      smfs = "./vendor/bin/sail artisan migrate:fresh --seed";
      # `mfs` was defined twice in the old alias file. zsh silently kept
      # the last definition; a Nix attrset would reject the duplicate, so
      # only that winning definition is carried over here.
      mfs = "sail artisan migrate:fresh";
      mfss = "sail artisan migrate:fresh --seed";
      arl = "sail artisan route:list";
      python = "python3";
    };

    # The platform files hang more content off these two anchors: darwin/extras.nix
    # adds mkOrder 501, 1100 and 1600, positioned relative to mkBefore's 500 just
    # below and mkAfter's 1500 further down. Moving either anchor has out-of-file
    # dependents to check.
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # The pre-Nix config (still on disk at ~/.zshrc.backup:158) exported
        # this to /usr/local/share, the Intel Homebrew prefix. Nothing sources
        # that file any more, but the export outlives it inside any process
        # tree started before the migration, a long-running tmux server being
        # the usual carrier, and every shell below it inherits the dead path.
        # zsh-syntax-highlighting falls back to its own store directory only
        # when this is unset, so an inherited value makes it print
        # "highlighters directory not found" and load zero highlighters.
        # Clearing it well before home-manager sources the plugin lets the
        # plugin resolve its own path. This used to sit below the ~/.secrets
        # source line, which now lives in envExtra above; the two never
        # interacted, and .zshenv runs before .zshrc either way.
        unset ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR
      '')

      (lib.mkAfter ''
        # ~/.bin, not ~/.dotfiles/bin. home-manager creates ~/.bin (home.file
        # in nix/home/darwin/default.nix and nix/home/linux/default.nix);
        # ~/.dotfiles is a hand-made symlink that exists on this machine only
        # and would be missing on a fresh clone.
        export PATH=''${PATH}:~/.bin
        export PATH=''${PATH}:~/.local/bin
        # $HOME/.yarn/bin is gone from this line on purpose. It holds a Yarn
        # 1.22 Classic shim left by a 2024 install-script run, and prepended
        # here it outranked the Corepack shim in ~/.local/bin for every repo
        # pinning a modern Yarn. Dropping the entry lets Corepack resolve
        # `yarn` per project, from the shims nix/home/darwin/default.nix
        # declares. ~/.local/bin stays appended, not prepended, so the
        # resolved ordering in docs/nix-reproducibility-review.md holds: Nix
        # still wins for anything both it and an installer provide.
        # The global-installs bin below stays. It supplies cdk,
        # create-next-app, create-playwright, create-vite and cva.
        export PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"
      '')
    ];
  };
}
