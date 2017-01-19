# Path to your oh-my-zsh installation.
export ZSH=/Users/jose/.oh-my-zsh

# Directories to be prepended to $PATH
declare -a dirs_to_prepend
dirs_to_prepend=(
    "/usr/local/bin/mysql_config"
    "/sbin"
    "/bin"
    "/usr/bin"
    "/usr/sbin"
    "/usr/local/heroku/bin"
    "/usr/local/sbin"
    "/usr/local/bin"
    "$(brew --prefix homebrew/php/php71)/bin"
    "/Users/jose/.composer/vendor/bin"
    "/Users/jose/.dotfiles/bin"
)

# Explicitly configured $PATH
PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"


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
plugins=(git tmux zsh-nvm)

# User configuration
COMPLETION_WAITING_DOTS="true"

# Disable auto-window renaming in tmux
DISABLE_AUTO_TITLE=true

# php version manager
source $(brew --prefix php-version)/php-version.sh && php-version 5

# manually installed nvm
source ~/.zsh-nvm/zsh-nvm.plugin.zsh

source $ZSH/oh-my-zsh.sh

# redefine prompt_context for hiding user@hostname
prompt_context () { }

export LANG=en_US.UTF-8

if [ -r ~/.not-public ]
then
    source ~/.not-public
fi

# added by travis gem
[ -f /Users/jose/.travis/travis.sh ] && source /Users/jose/.travis/travis.sh
