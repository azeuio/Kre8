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

man_init () {
    printf "NAME\n\tinit\nSYNOPSIS\n\t$0 init [DIRECTORY]\n\nDESCRIPTION\n\tInitialize a container in DIRECTORY(default:'.') for AstroJs dev\n"
}

init () {
    destinationFolder=${2:-'.'}
    folder_exists $destinationFolder
    exists=$?
    if [ $exists -eq 0 ]; then
        npm create astro@latest -y $destinationFolder

        # TODO: use github in the future
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

man_start () {
    printf "NAME\n\tstart\nSYNOPSIS\n\t$0 start TAG_NAME [DIRECTORY] [PORT]\n\nDESCRIPTION\n\tBuild and run the container named TAG_NAME from DIRECTORY(default:'.') and expose PORT(default:3000)\n"
}

start () {
    build $* && run $2 $4
}

man_help () {
    printf "NAME\n\thelp\nSYNOPSIS\n\t$0 help [COMMAND] [PORT]\n\nDESCRIPTION\n\tPrint help for every command of for COMMAND if it is set\n"
}


if [[ "$1" == 'init' ]]; then
    init $@
elif [[ "$1" == 'build' ]]; then
    build $@
elif [[ "$1" == 'run' ]]; then
    run $2 $3
elif [[ "$1" == 'start' ]]; then
    start $@
elif [[ "$1" == 'help' ]]; then
    if [[ "$2" == 'init' ]]; then
        man_init
    elif [[ "$2" == 'build' ]]; then
        man_build
    elif [[ "$2" == 'run' ]]; then
        man_run
    elif [[ "$2" == 'start' ]]; then
        man_start
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
        man_help
    fi
fi
