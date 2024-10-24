container_name=k8autotest

folder_exists () {
    if ! [ -d $1 ]; then
        return 1
    elif ! [ -z "$( ls -A $1 )" ]; then
        return 2
    else
        return 0
    fi
}

program_name=$0

man_init () {
    printf "NAME\n\
    \tinit\n\
    SYNOPSIS\n\
    \t$program_name init URL [DIRECTORY]\n\
    \n\
    DESCRIPTION\n\
    \tInitialize a container in DIRECTORY(default:'.') for an AstroJs app\n\
    The app is expected to be published at URL"
    /
}

init () {
    if [ -z $1 ]; then
        man_init >&2
        return 1
    fi
    destinationFolder=${2:-'.'}
    folder_exists $destinationFolder
    exists=$?
    if [ $exists -eq 0 ]; then
        url=$1
        npm create astro@latest $destinationFolder -- --template minimal --no-install --git --typescript strict --skip-houston

        if [ $? -ne 0 ]; then
            return $?
        fi
        cd "$destinationFolder"
        # TODO: See why astro build does not work with the commands given by astro
        # insert a Dockerfile
        curl -s https://raw.githubusercontent.com/azeuio/Kre8/refs/heads/main/templates/Dockerfile > "./Dockerfile"
        # edit package.json so the project can be executed
        # grep -l "\"start\": \"astro dev\"" ./package.json | xargs sed -i 's/\"start\": \"astro dev\"/\"start\": \"astro dev --host\"/g'
        curl -s https://raw.githubusercontent.com/azeuio/Kre8/refs/heads/main/templates/tsconfig.json > "./tsconfig.json"
        npm i @astrojs/node
        curl -s https://raw.githubusercontent.com/azeuio/Kre8/refs/heads/main/templates/astro.config.mjs > "./astro.config.mjs"
        grep "site:"  ./astro.config.mjs  -l | xargs sed -Ei "s/site: .*,/site: 'https:\/\/www.website.com',/g"
    elif [ $exists -eq 1 ]; then
        echo "Folder '$destinationFolder' does not exist"
    elif [ $exists -eq 2 ]; then
        echo "Folder '$destinationFolder' is not empty"
    fi
}

man_build () {
    printf "NAME\n\tbuild\nSYNOPSIS\n\t$0 build TAG_NAME [DIRECTORY]\n\nDESCRIPTION\n\tbuild the dockerfile in DIRECTORY(default:'.')\n"
}

build () {
    if [ -z $2 ]; then
        man_build >&2
        return 1
    fi
    docker build -t $2 ${3:-'.'}
}

man_run () {
    printf "NAME\n\trun\nSYNOPSIS\n\t$0 run CONTAINER_NAME [PORT]\n\nDESCRIPTION\n\tRuns the CONTAINER_NAME and expose PORT(default:3000)\n"
}

run () {
    if [ -z $1 ]; then
        man_run >&2
        return 1
    fi
    container_name=$1
    port=${2:-'3000'}
    docker run -dp $port:4321 $container_name
}

man_stop () {
    printf "NAME\n\tstop\nSYNOPSIS\n\t$0 stop CONTAINER_TAG\n\nDESCRIPTION\n\tStops the tagged container\n"
}

stop () {
    if [ -z $1 ]; then
        man_stop >&2
        return 1
    fi
    id_to_kill=$(docker ps | grep -w $1 | head -n 1 | awk '{print $1}')
    if [ -z $id_to_kill ]; then
        echo "Could not find the specified container ('$1')" >&2
        return 1
    fi
    docker kill $id_to_kill
}

man_start () {
    printf "NAME\n\tstart\nSYNOPSIS\n\t$0 start TAG_NAME [DIRECTORY] [PORT]\n\nDESCRIPTION\n\tBuild and run the container named TAG_NAME from DIRECTORY(default:'.') and expose PORT(default:3000)\n"
}

start () {
    container_tag=$2
    remove $container_tag
    build $* && run $container_tag $4
}

man_restart () {
    printf "NAME\n \
    \trestart\n \
    SYNOPSIS\n \
    \t$0 restart CONTAINER_TAG\n \
    \nDESCRIPTION\n \
    \tIf the container does not exist, starts a new one\n \
    \tOtherwise, if the it exists and is running, stops it then run it again\n \
    \tOtherwise, if the it exists and is stopped, run it again\n" \
    /
}

restart () {
    if [ -z $1 ]; then
        man_restart >&2
        return 1
    fi
    id_to_restart=$(docker ps -a | grep -w $1 | head -n 1 | grep -oE '^[^ ]+')
    docker restart $id_to_restart
}


man_remove () {
    printf "NAME\n \
    \trm\n \
    SYNOPSIS\n \
    \t$0 rm CONTAINER_TAG\n \
    \nDESCRIPTION\n \
    \tRemoves CONTAINER\n" \
    /
}

remove () {
    if [ -z $1 ]; then
        man_remove >&2
        return 1
    fi
    id_to_rm=$(docker ps -a | grep -w $1 | head -n 1 | grep -oE '^[^ ]+')
    docker stop $id_to_rm
    docker rm $id_to_rm
}


man_list () {
    printf "NAME\n \
    \tls\n \
    SYNOPSIS\n \
    \t$0 ls\n \
    \nDESCRIPTION\n \
    \tLists all containers\n" \
    /
}

list () {
    docker ps -a
}

man_help () {
    printf "NAME\n\thelp\nSYNOPSIS\n\t$0 help [COMMAND] [PORT]\n\nDESCRIPTION\n\tPrint help for every command of for COMMAND if it is set\n"
}


if [[ "$1" == 'init' ]]; then
    init $2 $3
elif [[ "$1" == 'build' ]]; then
    build $@
elif [[ "$1" == 'run' ]]; then
    run $2 $3
elif [[ "$1" == 'start' ]]; then
    start $@
elif [[ "$1" == 'stop' ]]; then
    stop $2
elif [[ "$1" == 'restart' ]]; then
    restart $2
elif [[ "$1" == 'rm' ]]; then
    remove $2
elif [[ "$1" == 'ls' ]]; then
    list $2
elif [[ "$1" == 'help' ]]; then
    if [[ "$2" == 'init' ]]; then
        man_init
    elif [[ "$2" == 'build' ]]; then
        man_build
    elif [[ "$2" == 'run' ]]; then
        man_run
    elif [[ "$2" == 'start' ]]; then
        man_start
    elif [[ "$2" == 'stop' ]]; then
        man_stop
    elif [[ "$2" == 'restart' ]]; then
        man_restart
    elif [[ "$2" == 'rm' ]]; then
        man_remove
    elif [[ "$2" == 'ls' ]]; then
        man_list
    elif [[ "$2" == 'help' ]]; then
        man_help
    else
        echo ==========
        man_init
        echo ==========
        man_build
        echo ==========
        man_run
        echo ==========
        man_start
        echo ==========
        man_stop
        echo ==========
        man_restart
        echo ==========
        man_remove
        echo ==========
        man_list
        echo ==========
        man_help
    fi
fi
