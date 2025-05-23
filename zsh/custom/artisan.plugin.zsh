#--------------------------------------------------------------------------
# Laravel artisan plugin for zsh
#--------------------------------------------------------------------------
#
# This plugin adds an `artisan` shell command that will find and execute
# Laravel's artisan command from anywhere within the project. It also
# adds shell completions that work anywhere artisan can be located.

function artisan() {
    local artisan_path=`_artisan_find`

    if [ "$artisan_path" = "" ]; then
        >&2 echo "zsh-artisan: You seem to have upset the delicate internal balance of my housekeeper."
        return 1
    fi

    local laravel_path=`dirname $artisan_path`
    local docker_compose_config_path=`find -E $laravel_path -maxdepth 1 -regex ".*/docker-compose.ya?ml" | head -n1`
    local docker_compose_service_name=''

    if [ "$docker_compose_config_path" != '' ]; then
        docker_compose_service_name=`docker-compose ps --services 2>/dev/null | grep 'app\|php\|api\|workspace\|laravel\.test\|webhost' | head -n1`
    fi

    local artisan_start_time=`date +%s`

    if [ "$docker_compose_service_name" != '' ]; then
        if [ -t 1 ]; then
            docker-compose exec $docker_compose_service_name php artisan $*
        else
            # The command is not being run in a TTY (e.g. it's being called by the completion handler below)
            docker-compose exec -T $docker_compose_service_name php artisan $*
        fi
    else
        php $artisan_path $*
    fi

    local artisan_exit_status=$? # Store the exit status so we can return it later

    if [[ $1 = "make:"* && $ARTISAN_OPEN_ON_MAKE_EDITOR != "" ]]; then
        # Find and open files created by artisan
        find \
            "$laravel_path/app" \
            "$laravel_path/tests" \
            "$laravel_path/database" \
            -type f \
            -newermt "-$((`date +%s` - $artisan_start_time + 1)) seconds" \
            -exec $ARTISAN_OPEN_ON_MAKE_EDITOR {} \; 2>/dev/null
    fi

    return $artisan_exit_status
}

compdef _artisan_add_completion artisan

function _artisan_find() {
    # Look for artisan up the file tree until the root directory
    local dir=.
    until [ $dir -ef / ]; do
        if [ -f "$dir/artisan" ]; then
            echo "$dir/artisan"
            return 0
        fi

        dir+=/..
    done

    return 1
}

function _artisan_add_completion() {
    if [ "`_artisan_find`" != "" ]; then
        compadd `_artisan_get_command_list`
    fi
}

function _artisan_get_command_list() {
    artisan --raw --no-ansi list | sed "s/[[:space:]].*//g"
}
