# Path to your oh-my-zsh installation.
export ZSH=/Users/jose/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"
ZSH_CUSTOM=~/.oh-my-zsh-custom/custom

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

# User configuration
COMPLETION_WAITING_DOTS="true"

export PATH="/usr/local/heroku/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/jose/.composer/vendor/bin:/opt/puppetlabs/bin:/Users/jose/.dotfiles/bin"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"
#
alias sshve="ssh root@ve.josecanhelp.com"
alias vssh="cd ~/vagrant-homehero-web; vagrant ssh"
alias heroky="heroku"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp="git push origin HEAD"
alias gd="git diff"
alias gac="git add -A && git commit -m"
alias gs="git status"
alias partink="php artisan tinker"

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

# redefine prompt_context for hiding user@hostname
prompt_context () { }
export PATH="/usr/local/sbin:$PATH"

# Disable auto-window renaming in tmux
DISABLE_AUTO_TITLE=true

#PHP 5.6
export PATH="$(brew --prefix homebrew/php/php56)/bin:$PATH"
