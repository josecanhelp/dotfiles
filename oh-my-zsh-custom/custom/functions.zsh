# Create a new directory and enter it
  function mkd() {
    mkdir -p "$@" && cd "$_";
  }

 function gpp() {
    git push origin HEAD

    if [ $? -eq 0 ]; then
    	openpr
    else
    	echo 'failed to push commits and open a pull request.';
    fi

 }

 function openpr() {
    github_url=`git remote -v | awk '/fetch/{print $2}' | sed -Ee 's#(git@|git://)#http://#' -e 's@com:@com/@' -e 's%\.git$%%'`;
    branch_name=`git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3`;
    pr_url=$github_url"/compare/master..."$branch_name
    open $pr_url;
 }