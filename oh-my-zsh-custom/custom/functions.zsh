# Create a new directory and enter it
function mkd() {
  mkdir -p "$@" && cd "$_";
}

# Open the pull request url for your current directory's branch (base branch defaults to master)
function openpr() {
  github_url=`git remote -v | awk '/fetch/{print $2}' | sed -Ee 's#(git@|git://)#http://#' -e 's@com:@com/@' -e 's%\.git$%%' | awk '/github/'`;
  branch_name=`git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3,4`;
  pr_url=$github_url"/compare/master..."$branch_name
  open $pr_url;
}

# Run git push and then immediately open the pull request url
function gpp() {
  git push origin HEAD

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
