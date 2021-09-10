# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# ========================= COLORS ========================= #

# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

RED='\033[31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No color

# ========================= HELPERS ========================= #

alias cls="tput reset" # Clears the terminal
alias el="echo -e ''" # Empty line

out() {
    printf "${!2}${1}${NC}"
}

permissions() {
	sudo chmod -R 644 $1
	sudo chown $(id -u):$(id -g) $1
}

folder() {
	sudo chmod -R 755 $1
}

# ========================= PHPSTORM ========================= #

alias p="phpstorm"

# ========================= PHPUNIT ========================= #

alias pu="cls && phpunit"
alias pf="cls && phpunit --filter"

# ========================= DOCKER ========================= #

alias d="docker"
alias dc="docker-compose"
alias dcu="docker-compose up"
alias dcub="docker-compose up --build"
alias dps="docker ps"
alias ds="docker stop $(docker ps -qa)"

dbash() {
    out "\nThrowing " YELLOW
    out "[.bashrc]"
    out " into each and every container...\n" YELLOW

    containers="$(docker ps -q -f name=php | tr '\n' ' ')"
    for container in $containers
    do
        out "$container" RED
        docker cp ~/.bashrc_docker $container:/root/.bashrc
        out "\r$container"
        out " Done!\n" GREEN
    done
}

dx() {
	cls
    out "Filtering: "

	if [[ $1 == 'all' ]] ; then
	    out "all\n" GREEN
        getContainer
    elif [[ $1 == '' ]]; then
        out "php-fpm\n" GREEN
        getContainer name=php-fpm
        d cp ~/.bashrc_docker_container $container:~/.bashrc
    else
        out "$1\n" GREEN
        getContainer name=$1
    fi

    cls
	d exec -it $container bash
}

dxa() {
    cls
    out "Filtering: "
    out "all\n" GREEN
    getContainer
    cls
    d exec -it $container bash
}

containerExists() {
    if [[ $(docker ps -a -q --filter "id=$1") == $1* ]] ; then
        return 0
    else
        return 1
    fi
}
getContainer() {
    gc_errors=0

    if [[ $1 != '' ]] ; then
        dps --filter $1
    else
        dps
    fi

    while true
    do
        out "\nChoose a container: " YELLOW
        read -r container
        containerExists $container

        if [[ $? -eq 0 ]] ; then
            if [[ gc_errors -gt 0 ]] ; then
                out "Finally, you got the right one :) " GREEN
            else
                out "Success! " GREEN
            fi
            out "Chosen [$container] container.\n" GREEN
            break
        fi

        out "Container [$container] doesn't exist!\n" RED
        out "Please try again and be attentive.\n"
        (( gc_errors += 1 ))
    done
}

extract() {
    e_errors=0

    cls
    getContainer
    out "\n"

    from=$1
    to=$2

    while true
    do
        # paths are not present and no errors
        if [[ (( -z ${!1+x} || -z ${!2+x} )) && e_errors -eq 0 ]] ; then
            # if "FROM" is absent
            if [[ (( -z ${!1+x} ))  ]] ; then
                out "Take from the container ${NC}[/src/vendor]${YELLOW}: " YELLOW
                read -r from
            fi

            # if "TO" is absent
            if [[ (( -z ${!2+x} )) ]] ; then
                out "Where to put: " YELLOW
                read -r to
            fi
            out "\n"
        fi

        # is there the given path inside of the container?
        if docker exec $container test -d "$from" ; then
            out "Extracting [$from]...\n" YELLOW
            break
        fi

        out "Nothing found at [$from] inside of [$container].\n" RED
        out "Please enter other path: " YELLOW
        read -r from
        out "\n"
        (( e_errors += 1 ))
    done

    d cp $container:$from $to
    out "Extracted!\n" GREEN
}
vendor() {
    cls
    out "Filtering: "
    out "php-fpm\n" GREEN
	getContainer name=php-fpm
	out "Extracting vendor...\n" YELLOW
	d cp $container:./src/vendor ./
	out "Extracted!\n" GREEN
}

tail () {
    cls
    out "Filtering: "
    out "$1" GREEN
    if [[ $1 == '' ]]; then
        out "all" GREEN
    fi
    out "\n"
    getContainer "name=$1"
    docker logs -f --tail 100 "$container"
}
