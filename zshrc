# Path to your oh-my-zsh installation.
export ZSH=/Users/jose/.oh-my-zsh

# Directories to be prepended to $PATH
declare -a dirs_to_prepend
dirs_to_prepend=(
    "/usr/local/bin/mysql_config"
    "/usr/local/heroku/bin"
    "/usr/local/sbin"
    "/usr/local/bin"
    "/Users/jose/.rvm/bin"
    "/Users/jose/.composer/vendor/bin"
    "/Users/jose/.dotfiles/bin"
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
plugins=(git tmux)

# User configuration
COMPLETION_WAITING_DOTS="true"

# Disable auto-window renaming in tmux
DISABLE_AUTO_TITLE=true

# PHP version manager
source $(brew --prefix php-version)/php-version.sh && php-version 7.1

# Manually installed nvm
source ~/.zsh-nvm/zsh-nvm.plugin.zsh

source $ZSH/oh-my-zsh.sh

# Redefine prompt_context for hiding user@hostname
prompt_context () { }

export LANG=en_US.UTF-8

if [ -r ~/.not-public ]
then
    source ~/.not-public
fi

# Added by travis gem
[ -f /Users/jose/.travis/travis.sh ] && source /Users/jose/.travis/travis.sh

code () {  
    if [[ $# = 0 ]]
    then
        open -a "Visual Studio Code" -n
    else
        [[ $1 = /* ]] && F="$1" || F="$PWD/${1#./}"
        open -a "Visual Studio Code" -n --args "$F"
    fi
}
