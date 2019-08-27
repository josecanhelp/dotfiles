# Path to your oh-my-zsh installation.
export ZSH=/Users/jose/.oh-my-zsh
export PATH="$PATH:$HOME/.bin"

# Directories to be prepended to $PATH
# Later directories take precendence
declare -a dirs_to_prepend
dirs_to_prepend=(
    "/usr/local/opt/php@7.3/bin"
    "/usr/local/opt/php@7.3/sbin"
    "/usr/local/bin/mysql_config"
    "/Users/jose/.composer/vendor/bin"
    "/Users/jose/.dotfiles/bin"
    "/Users/jose/.npm-packages/bin"
    "/sbin"
    "usr/sbin"
    "usr/local/sbin"
    "/bin"
    "/usr/bin"
    "/usr/local/bin"
)

PATH=""

for dir in ${(k)dirs_to_prepend[@]}
do
  if [ -d ${dir} ]; then
    # If these directories exist, then prepend them to existing PATH
    PATH="${dir}:$PATH"
  fi
done

unset dirs_to_prepend

export PATH

ZSH_THEME="agnoster"
ZSH_CUSTOM=/Users/jose/.oh-my-zsh-custom/custom


plugins=(git node npm brew history-substring-search)

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

ctags=/usr/local/bin/ctags
fpath=(/usr/local/share/zsh-completions $fpath)
