#!/bin/bash -e

cd $(dirname $0)

compose() {
    compose_files=("-f" "docker-compose.yaml")
    COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker compose "${compose_files[@]}" up
}

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

compose up --build
