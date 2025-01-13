alias heroky="heroku"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp="git push origin HEAD"
alias gd="git diff"
alias gac="git add -A && git commit -m"
alias gs="git status"
alias gco="git checkout"
alias gsup="git branch --set-upstream-to=origin/$(current_branch)"
alias guncommit="git reset HEAD~1"
alias art="php artisan"
alias bb="cd ~/Code/Brave/"
alias tt="cd ~/Code/Converge/"
alias jj="cd ~/Code/JoseCanHelp/"
alias ff="cd ~/Code/Fnnch/"
alias dot="cd ~/dotfiles"
alias updatedotbot="dot && git submodule update --remote dotbot"
alias gsa="git submodule add"
alias vs="vagrant status"
alias vu="vagrant up"
alias vh="vagrant halt"
alias vd="vagrant destroy"
alias cda="composer dump-autoload"
alias dpostgres="docker run --name postgres -v data:/var/lib/postgresql/data -e POSTGRES_USER=perk -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=myapp -p 5432:5432 -d postgres"
alias dmysql="docker run --name mysql -v mysql_data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=secret -p 3306:3306 -d mysql:5.7"
alias artclear="php artisan cache:clear && php artisan config:clear && php artisan view:clear && php artisan route:clear"
alias cl="clear"
alias nah="git reset --hard && git clean -df"
alias wip="git add . && git commit -m 'WIP'"
alias wipa="git add . && git commit --amend -m 'WIP'"
alias gempty="git commit --allow-empty -m 'Empty Commit'"
alias phpunit="./vendor/bin/phpunit"
alias nrs='npm run serve'
alias nrw='npm run watch'
alias nrd='npm run dev'
alias nrb='npm run build'
alias editzshrc='vim ~/.zshrc'
alias editalias='vim ~/.oh-my-zsh-custom/custom/aliases.zsh'
alias mutt="neomutt"
alias dockerps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}"'
alias dp="dockerps"
alias dockerpsa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}"'
alias dpa="dockerpsa"
alias dvp="docker volume prune"
alias l="ls -alh"
alias src="exec zsh"
alias ..="cd .."
alias zz='z -c'      # restrict matches to subdirs of $PWD
alias zi='z -i'      # cd with interactive selection
alias zf='z -I'      # use fzf to select in multiple matches
alias zb='z -b'      # quickly cd to the parent directory
alias pb='pianobar'
alias pad='php artisan dusk'
alias jig="./vendor/bin/jigsaw"
alias to="./bin/run"
alias tinkpw="php artisan tinker --execute=\"echo bcrypt('password')\" | pbcopy"
alias lll="ranger"
alias vimlog="nvim -V9myNvim.log ."
alias mfs="php artisan migrate:fresh --seed"
alias forceprune="docker volume prune --force && docker system prune --force"
alias pest="./vendor/bin/pest"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias sup="./vendor/bin/sail up -d"
alias stp="./vendor/bin/sail test -p"
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'
alias strap='[ -f strap ] && bash strap || bash ./bin/strap'
alias gdesc="git log --no-merges --pretty=format:'- %s' master.. | pbcopy"
alias gitamend="git commit --amend"
alias ghweb="gh repo view --web"
alias ghopen="gh repo view --web"
# alias npm="pnpm"
# alias python="python3"
alias ecrlogin="aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/v9v6w9r0"
alias sss="myssh"
alias aa="cd ~/Code/AWS"
alias kube="kubectl"
alias gitprune='git branch --merged | egrep -v "(^\*|master|main|dev)" | xargs git branch -d && git remote prune origin'
# alias bb="~/Code/Converge/bitbucket-cli/index.js"
alias findlargedir="find ./  -maxdepth 1 -mindepth 1  -type d  -exec du -hs {} \;| sort -rh | head -n 1"
alias codeartifact="export CODEARTIFACT_AUTH_TOKEN=`aws codeartifact get-authorization-token --domain converge --domain-owner 420280777025 --region us-east-1 --query authorizationToken --output text`"

alias runprod="/Library/Java/JavaVirtualMachines/jdk1.8.0_351.jdk/Contents/Home/bin/java -Dfile.encoding=UTF-8 -classpath /Users/jose/Code/Converge/kafka2/bin:/Users/jose/Code/Converge/kafka2/lib/javax.servlet-api-3.1.0.jar:/Users/jose/Code/Converge/kafka2/lib/activation-1.1.jar:/Users/jose/Code/Converge/kafka2/lib/classworlds-1.1-alpha-2.jar:/Users/jose/Code/Converge/kafka2/lib/commons-lang-2.6.jar:/Users/jose/Code/Converge/kafka2/lib/file-management-1.2.1.jar:/Users/jose/Code/Converge/kafka2/lib/jline-0.9.94.jar:/Users/jose/Code/Converge/kafka2/lib/junit-3.8.1.jar:/Users/jose/Code/Converge/kafka2/lib/log4j-1.2.17.jar:/Users/jose/Code/Converge/kafka2/lib/lz4-1.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/netty-3.7.0.Final.jar:/Users/jose/Code/Converge/kafka2/lib/snappy-java-1.1.2.6.jar:/Users/jose/Code/Converge/kafka2/lib/velocity-1.7.jar:/Users/jose/Code/Converge/kafka2/lib/spymemcached-2.12.1.jar:/Users/jose/Code/Converge/kafka2/lib/fastutil-7.0.13.jar:/Users/jose/Code/Converge/kafka2/lib/commons-io-2.5.jar:/Users/jose/Code/Converge/kafka2/lib/jdom-2.0.6-contrib.jar:/Users/jose/Code/Converge/kafka2/lib/jdom-2.0.6.jar:/Users/jose/Code/Converge/kafka2/lib/commons-cli-1.3.1.jar:/Users/jose/Code/Converge/kafka2/lib/commons-dbcp2-2.1.1.jar:/Users/jose/Code/Converge/kafka2/lib/commons-codec-1.10.jar:/Users/jose/Code/Converge/kafka2/lib/jsoup-1.8.2.jar:/Users/jose/Code/Converge/kafka2/lib/jchronic-0.2.6.jar:/Users/jose/Code/Converge/kafka2/lib/maxmind-db-1.2.1.jar:/Users/jose/Code/Converge/kafka2/lib/geoip2-2.7.0.jar:/Users/jose/Code/Converge/kafka2/lib/DDR-Simple-API.jar:/Users/jose/Code/Converge/kafka2/lib/deviceatlas-carrierapi-1.0.1.jar:/Users/jose/Code/Converge/kafka2/lib/deviceatlas-common-1.0.jar:/Users/jose/Code/Converge/kafka2/lib/deviceatlas-deviceapi-2.0.1.jar:/Users/jose/Code/Converge/kafka2/lib/OpenDDR-Simple-API-1.0.0.26.jar:/Users/jose/Code/Converge/kafka2/lib/jackson-core-asl-1.9.13.jar:/Users/jose/Code/Converge/kafka2/lib/jackson-jaxrs-1.9.13.jar:/Users/jose/Code/Converge/kafka2/lib/jackson-mapper-asl-1.9.13.jar:/Users/jose/Code/Converge/kafka2/lib/commons-logging-1.2.jar:/Users/jose/Code/Converge/kafka2/lib/httpcore-4.4.4.jar:/Users/jose/Code/Converge/kafka2/lib/httpclient-4.5.2.jar:/Users/jose/Code/Converge/kafka2/lib/commons-jexl-2.1.1.jar:/Users/jose/Code/Converge/kafka2/lib/activemq-all-5.14.3.jar:/Users/jose/Code/Converge/kafka2/lib/stringtree-json-2.0.9.jar:/Users/jose/Code/Converge/kafka2/lib/commons-pool2-2.4.2.jar:/Users/jose/Code/Converge/kafka2/lib/jedis-2.9.0.jar:/Users/jose/Code/Converge/kafka2/lib/commons-configuration-1.10.jar:/Users/jose/Code/Converge/kafka2/lib/ip2location.jar:/Users/jose/Code/Converge/kafka2/lib/activemq-jaas-5.14.3.jar:/Users/jose/Code/Converge/kafka2/lib/jetty-continuation-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/jetty-http-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/jetty-io-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/jetty-security-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/jetty-server-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/jetty-servlet-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/jetty-servlets-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/jetty-util-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/websocket-api-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/websocket-client-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/websocket-common-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/websocket-server-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/websocket-servlet-9.4.2.v20170220.jar:/Users/jose/Code/Converge/kafka2/lib/aircompressor-0.5.jar:/Users/jose/Code/Converge/kafka2/lib/json-smart-2.3.jar:/Users/jose/Code/Converge/kafka2/lib/commons-collections-3.2.2.jar:/Users/jose/Code/Converge/kafka2/lib/eclipse-collections-8.2.0.jar:/Users/jose/Code/Converge/kafka2/lib/eclipse-collections-api-8.2.0.jar:/Users/jose/Code/Converge/kafka2/lib/eclipse-collections-forkjoin-8.2.0.jar:/Users/jose/Code/Converge/kafka2/lib/joda-time-2.9.9.jar:/Users/jose/Code/Converge/kafka2/lib/slf4j-api-1.7.25.jar:/Users/jose/Code/Converge/kafka2/lib/slf4j-log4j12-1.7.25.jar:/Users/jose/Code/Converge/kafka2/lib/HikariCP-2.6.3.jar:/Users/jose/Code/Converge/kafka2/lib/mariadb-java-client-2.1.0.jar:/Users/jose/Code/Converge/kafka2/lib/hadoop-auth-2.8.1.jar:/Users/jose/Code/Converge/kafka2/lib/hadoop-client-2.8.1.jar:/Users/jose/Code/Converge/kafka2/lib/hadoop-hdfs-2.8.1.jar:/Users/jose/Code/Converge/kafka2/lib/hadoop-mapreduce-client-core-2.8.1.jar:/Users/jose/Code/Converge/kafka2/lib/hive-exec-2.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/hive-jdbc-2.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/hive-service-2.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/orc-core-1.4.0.jar:/Users/jose/Code/Converge/kafka2/lib/hadoop-common-2.8.1.jar:/Users/jose/Code/Converge/kafka2/lib/htrace-core4-4.2.0-incubating.jar:/Users/jose/Code/Converge/kafka2/lib/aws-java-sdk-1.11.192.jar:/Users/jose/Code/Converge/kafka2/lib/kafka-schema-registry-client-3.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/kafka-clients-0.11.0.0-cp1.jar:/Users/jose/Code/Converge/kafka2/lib/kafka-streams-0.11.0.0-cp1.jar:/Users/jose/Code/Converge/kafka2/lib/xz-1.5.jar:/Users/jose/Code/Converge/kafka2/lib/jackson-annotations-2.9.1.jar:/Users/jose/Code/Converge/kafka2/lib/jackson-core-2.9.1.jar:/Users/jose/Code/Converge/kafka2/lib/jackson-databind-2.9.1.jar:/Users/jose/Code/Converge/kafka2/lib/jackson-dataformat-cbor-2.9.1.jar:/Users/jose/Code/Converge/kafka2/lib/kafka-avro-serializer-3.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/commons-compress-1.8.1.jar:/Users/jose/Code/Converge/kafka2/lib/common-utils-3.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/paranamer-2.7.jar:/Users/jose/Code/Converge/kafka2/lib/common-config-3.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/common-metrics-3.3.0.jar:/Users/jose/Code/Converge/kafka2/lib/javax.mail.jar:/Users/jose/Code/Converge/kafka2/lib/AmazonElastiCacheClusterClient-1.2.0.jar:/Users/jose/Code/Converge/kafka2/lib/sentry-6.12.1.jar com.converge.Producer -debug"
alias kubectl="minikube kubectl --"
alias javahome="java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'"
alias setjava8="export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home"

alias smfs="./vendor/bin/sail artisan migrate:fresh --seed"
alias mfs="sail artisan migrate:fresh"
alias mfss="sail artisan migrate:fresh --seed"
alias arl="sail artisan route:list"
alias vim="nvim"
alias python="python3"
