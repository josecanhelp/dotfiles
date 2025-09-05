# Create a new directory and enter it
function mkd() {
  mkdir -p "$@" && cd "$_";
}

# Open the pull request url for your current directory's branch (base branch defaults to main)
function openpr() {
  github_url=`git remote -v | awk '/fetch/{print $2}' | sed -Ee 's#(git@|git://)#http://#' -e 's@com:@com/@' -e 's%\.git$%%' | awk '/github/'`;
  branch_name=`git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3,4`;
  pr_url=$github_url"/compare/main..."$branch_name
  open $pr_url;
}

# Run git push and then immediately open the pull request url
function gpp() {
  git push -u origin HEAD

  if [ $? -eq 0 ]; then
    openpr
  else
    echo 'failed to push commits and open a pull request.';
  fi
}

function homestead() {
    ( cd ~/Homestead && vagrant $* )
}

function fa() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

function current_branch() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo ${ref#refs/heads/}
}

function current_repository() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo $(git remote -v | cut -d':' -f 2)
}

ham() {
  open -g "hammerspoon://reloadHammerspoon"
}

timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

codeartifact() {
  export CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token --domain converge --domain-owner 420280777025 --region us-east-1 --query authorizationToken --output text)
  echo "CodeArtifact token refreshed."
}

# Function to open Bitbucket URL from local git repository
bbopen() {
    # Check if current directory is a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Error: Not a git repository"
        return 1
    fi

    # Get the remote URL (prioritize origin)
    local remote_url=$(git remote get-url origin 2>/dev/null || git remote get-url $(git remote | head -n 1) 2>/dev/null)
    
    if [ -z "$remote_url" ]; then
        echo "Error: No remote repository found"
        return 1
    fi

    # Check if it's a Bitbucket URL
    if ! echo "$remote_url" | grep -q "bitbucket"; then
        echo "Error: Remote URL does not appear to be a Bitbucket repository"
        return 1
    fi

    # Convert SSH URL to HTTPS URL if necessary
    if [[ "$remote_url" == git@* ]]; then
        # Format: git@bitbucket.org:username/repo.git
        local domain=$(echo "$remote_url" | cut -d '@' -f 2 | cut -d ':' -f 1)
        local path=$(echo "$remote_url" | cut -d ':' -f 2)
        path=${path%.git}  # Remove .git suffix if present
        remote_url="https://$domain/$path"
    elif [[ "$remote_url" == https://* ]]; then
        # Format: https://username@bitbucket.org/username/repo.git
        remote_url=${remote_url%.git}  # Remove .git suffix if present
    fi

    echo "Opening Bitbucket URL: $remote_url"
    
    # Use the full path to the open command
    /usr/bin/open "$remote_url" || {
        echo "Error: Could not open URL with /usr/bin/open"
        echo "Please open this URL manually: $remote_url"
        return 1
    }
}

yabaion() {
    brew services start yabai
    yabai -m config window_opacity on
    yabai -m config active_window_opacity 1.0
    yabai -m config normal_window_opacity 0.9
}

yabaioff() {
    yabai -m config active_window_opacity 1.0
    yabai -m config normal_window_opacity 1.0
    yabai -m config window_opacity off
    brew services stop yabai
}

_-accept-line () {
    emulate -L zsh
    local -a WORDS
    WORDS=( ${(z)BUFFER} )
    # Unfortunately ${${(z)BUFFER}[1]} works only for at least two words,
    # thus I had to use additional variable WORDS here.
    local -r FIRSTWORD=${WORDS[1]}
    local -r GREEN=$'\e[32m' RESET_COLORS=$'\e[0m'
    [[ "$(whence -w $FIRSTWORD 2>/dev/null)" == "${FIRSTWORD}: alias" ]] &&
        echo -nE $'\n'"${GREEN}Executing -> ${$(which $FIRSTWORD)//"$FIRSTWORD: aliased to "/""}${RESET_COLORS}"
    [[ "$(whence -w $FIRSTWORD 2>/dev/null)" == "${FIRSTWORD}: function" ]] &&
        echo -nE $'\n'"${GREEN}Executing -> ${$(which $FIRSTWORD)//"$FIRSTWORD () {
    "/""}${RESET_COLORS}"
    zle .accept-line
}
# zle -N accept-line _-accept-line
