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

function getPhpIni() {
 php --ini | awk '/php.ini$/' | awk '{print $4}'
}

function xdebugenable() {
  sed -ie 's!^;\(zend.*xdebug\.so\)!\1!' $(php --ini | awk '/php.ini$/' | awk '{print $4}')
}

function xdebugdisable() {
  sed -ie 's!^\(zend.*xdebug\.so\)!;\1!' $(php --ini | awk '/php.ini$/' | awk '{print $4}')
}

function toggleXdebug() {
# find the line with xdebug.so
# capture it in a variable
# check if the line has a `;` prepended
# if it does, remove it, if not, add it

  xdebugline=`awk '/^;zend.*xdebug.so\"$/' $(getPhpIni)`;

  if [ -z "$xdebugline" ]
  then
        echo "not here"
  else
        sed -i '/^;zend.*xdebug.so\"$ /s/^;//' $(getPhpIni)
  fi
}

function current_branch() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo ${ref#refs/heads/}
}

function current_repository() {

  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo $(git remote -v | cut -d':' -f 2)
}
