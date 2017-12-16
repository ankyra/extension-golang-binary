#!/bin/bash -e

set -euf -o pipefail

ROOT_DIR_NAME=user-service
DOCKER_ROOT_REPO_PATH="/go/src/github.com/ankyra/"
DOCKER_REPO_PATH="${DOCKER_ROOT_REPO_PATH}${ROOT_DIR_NAME}"
DOCKER_VERSION=1.9.0

cleanup_docker() {
    echo -n "Removing Docker data volume..."
    docker rm -v src 1>/dev/null 2>&1 || true
    echo "OK"
}

prepare_volume() {
    echo -n "Preparing Docker data volume..."
    docker create -v ${DOCKER_ROOT_REPO_PATH} --name src golang:${DOCKER_VERSION} /bin/true 1>/dev/null 2>&1
    docker cp "$PWD" "src:${DOCKER_ROOT_REPO_PATH}/tmp" 1>/dev/null
    docker_run "${DOCKER_ROOT_REPO_PATH}" "mv tmp ${ROOT_DIR_NAME}" 1>/dev/null
    echo "OK"
}


docker_run() {
    local cwd=$1
    local cmd=$2
    echo "Running '${cmd}' in Docker directory '${cwd}':"
    docker run --rm --volumes-from src -w "$cwd" golang:${DOCKER_VERSION} bash -c "${cmd}"
}


main() {
    cleanup_docker
    prepare_volume
    docker_run "${DOCKER_REPO_PATH}" "go test -cover -v \$(/usr/local/go/bin/go list ./... | grep -v -E 'vendor' )"
}

trap cleanup_docker EXIT
main
