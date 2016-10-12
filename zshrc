# Path to your oh-my-zsh installation.
export ZSH=/Users/jose/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
ZSH_THEME="agnoster"
ZSH_CUSTOM=/Users/jose/.oh-my-zsh-custom/custom

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git, tmux)

# User configuration
COMPLETION_WAITING_DOTS="true"

# Disable auto-window renaming in tmux
DISABLE_AUTO_TITLE=true

source $ZSH/oh-my-zsh.sh

# redefine prompt_context for hiding user@hostname
prompt_context () { }

export LANG=en_US.UTF-8

# Force brew's version of PHP 5.6
export PATH="$(brew --prefix homebrew/php/php56)/bin:$PATH"
export PATH="$PATH:
    /usr/local/heroku/bin:
    /usr/local/sbin:
    /usr/local/bin:
    /usr/bin:
    /bin:
    /usr/sbin:
    /sbin:
    /Users/jose/.composer/vendor/bin: 
    /Users/jose/.dotfiles/bin"

if [ -r ~/.not-public ]
then
    source ~/.not-public
fi

# added by travis gem
[ -f /Users/jose/.travis/travis.sh ] && source /Users/jose/.travis/travis.sh
