#!/bin/bash -e

cd $(dirname $0)

build_arg=""
positional=""
simulator="false"
script="$0"

compose() {
    compose_files=("-f" "docker-compose.yaml")
    if [ "$simulator" = "true" ]; then
        export BASE_IMAGE_STAGE=debian-base
        export TAG="simulator"
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

destroy() {
    compose down -v
}


while (( "$#" )); do
  case "$1" in
    --build)
        build_arg="--build"
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
    destroy)
        destroy
        ;;
    *)
        echo "Error: Unsupported command $positional" >&2
        usage
        exit 1
        ;;
esac
