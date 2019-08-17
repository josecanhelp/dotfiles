# Path to your oh-my-zsh installation.
export ZSH=/Users/jose/.oh-my-zsh
export PATH="$PATH:$HOME/.bin"
# Directories to be prepended to $PATH
declare -a dirs_to_prepend
dirs_to_prepend=(
    "/usr/local/opt/php@7.2/bin"
    "/usr/local/opt/php@7.2/sbin"
    "/usr/local/bin/mysql_config"
    "/usr/local/sbin"
    "/usr/local/bin"
    "/Users/jose/.composer/vendor/bin"
    "/Users/jose/.dotfiles/bin"
    "/Users/jose/.npm-packages/bin"
)

# Explicitly configured $PATH
PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

for dir in ${(k)dirs_to_prepend[@]}
do
  if [ -d ${dir} ]; then
    # If these directories exist, then prepend them to existing PATH
    PATH="${dir}:$PATH"
  fi
done

unset dirs_to_prepend

export PATH

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
ZSH_THEME="agnoster"
ZSH_CUSTOM=/Users/jose/.oh-my-zsh-custom/custom

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git node npm brew vi-mode)

# User configuration
COMPLETION_WAITING_DOTS="true"

# Disable auto-window renaming in tmux
DISABLE_AUTO_TITLE=true

source $ZSH/oh-my-zsh.sh

# Redefine prompt_context for hiding user@hostname
prompt_context () { }

export LANG=en_US.UTF-8

if [ -r ~/.not-public ]
then
    source ~/.not-public
fi


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

