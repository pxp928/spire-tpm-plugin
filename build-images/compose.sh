#!/bin/bash -e

cd $(dirname $0)

build_arg=""
positional=""
dev="false"
debug="false"
simulator="false"
script="$0"

compose() {
    compose_files=("-f" "docker-compose.yaml")
    if [ "$debug" = "true" ]; then
        export BASE_IMAGE_STAGE=debian-base
        export TAG="debug"
    fi
    if [ "$dev" = "true" ]; then
        export BASE_IMAGE_STAGE=debian-base
        export TAG="dev"
        compose_files+=("-f" "docker-compose-dev.yaml")
    fi
    if [ "$simulator" = "true" ]; then
        export BASE_IMAGE_STAGE=debian-base
        export SIMULATOR_SUFFIX="-simulator"
        export TAG="simulator"
        compose_files+=("-f" "docker-compose-simulator.yaml")
    else
        compose_files+=("-f" "docker-compose-hardware.yaml")
    fi
    COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker compose "${compose_files[@]}" "$@"
}

up() {
    # create docker network "spire-dev"
    if ! docker network inspect spire-dev >/dev/null 2>&1; then
        docker network create spire-dev
    fi

    for target_binary in tpm_attestor_server tpm_attestor_agent get_tpm_pubhash
    do
        if [[ "$(docker images -q $target_binary:simulator 2> /dev/null)" == "" ]]; then
            docker build --build-arg BINARY=$target_binary -t $target_binary:simulator ..
        fi
    done

    compose up $build_arg
}

build() {
    for target_binary in tpm_attestor_server tpm_attestor_agent get_tpm_pubhash
    do
        if [[ "$(docker images -q $target_binary:simulator 2> /dev/null)" == "" ]]; then
            docker build --build-arg BINARY=$target_binary -t $target_binary:simulator ..
        fi
    done
    compose build
}

pull() {
    compose pull
}

stop() {
    compose stop
}

destroy() {
    compose down -v
}

usage() {
cat >&2 <<-EOF
manage local spire server and agent
    usage: $script <options> <command>

where <command> is one of:
    up          - create or start stack
    build       - build stack images
    pull        - pull stack base images
    stop        - stop stack
    destroy     - destroy stack

options:
        --build     - build new container
        --debug     - use debian base instead of distroless
        --dev       - start dev server
    -h, --help      - print this message
        --simulator - use TPM simulator
EOF
}

while (( "$#" )); do
  case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    --build)
        build_arg="--build"
        shift
        ;;
    --dev)
        dev="true"
        shift
        ;;
    --debug)
        debug="true"
        shift
        ;;
    --simulator)
        simulator="true"
        shift
        ;;
    -*|--*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        usage
        exit 1
        ;;
    *) # preserve positional arguments
        positional="${postitional}${aaa:+" "}${1}"
        shift
        ;;
  esac
done

case "$positional" in
    up)
        up
        ;;
    build)
        build
        ;;
    pull)
        pull
        ;;
    stop)
        stop
        ;;
    destroy)
        destroy
        ;;
    *)
        echo "Error: Unsupported command $positional" >&2
        usage
        exit 1
        ;;
esac
