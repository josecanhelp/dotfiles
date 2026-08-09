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
      conda = {
        format = "[$symbol$environment](dimmed green) ";
        symbol = "🅒 ";
      };
    };
  };

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
      gs = "git status";
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
      editzshrc = "vim ~/dotfiles/nix/home/shell.nix";
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
      # `mfs` was defined twice in the old alias file. zsh silently kept
      # the last definition; a Nix attrset would reject the duplicate, so
      # only that winning definition is carried over here.
      mfs = "sail artisan migrate:fresh";
      mfss = "sail artisan migrate:fresh --seed";
      arl = "sail artisan route:list";
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
        fpath=(${config.home.homeDirectory}/.docker/completions $fpath)
      '')

      # mkOrder 1100, not a bare string. programs.starship contributes its
      # init snippet to zsh.initContent at the default priority 1000 with no
      # mkOrder of its own. A bare string here is also 1000, so the two tie
      # and the winner is decided by module-encounter order, which changes
      # if this module's position in the imports tree ever moves. 1100 puts
      # starship first deterministically, matching the pre-split output, and
      # stays below the mkAfter block's 1500.
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

      (lib.mkAfter ''
        export PATH=''${PATH}:~/.composer/vendor/bin
        # ~/.bin, not ~/.dotfiles/bin. home-manager creates ~/.bin (see
        # home.file above); ~/.dotfiles is a hand-made symlink that exists
        # on this machine only and would be missing on a fresh clone.
        export PATH=''${PATH}:~/.bin
        export PATH=''${PATH}:~/.local/bin
        export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

        # Nix must win over Homebrew. brew shellenv in ~/.zprofile prepends
        # /opt/homebrew/bin. This runs last, so it wins.
        export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
      '')
    ];
  };
}
