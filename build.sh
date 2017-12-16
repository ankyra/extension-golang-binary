#!/bin/bash -e

set -euf -o pipefail

BINARY_NAME="${INPUT_binary_name}"
PACKAGE_NAME="${INPUT_package_name}"
DEPENDS="${INPUT_escape_go_dependencies}"
DOCKER_PACKAGE_PATH="/go/src/${PACKAGE_NAME}"
DOCKER_PACKAGE_PARENT_PATH=$(dirname "${DOCKER_PACKAGE_PATH}")
DOCKER_VERSION=1.9.0

cleanup_docker() {
    echo -n "Removing Docker data volume..."
    docker rm -v src 1>/dev/null 2>&1 || true
    echo "OK"
}

copy_dep_to_vendor() {
    local dep="deps/${1}"
    local target="vendor/${2}"
    echo -n "Copying Escape dependency '$dep' to '$target'..."
    rm -rf "$target"
    cp -r "$dep" "$target"
    rm -rf "${target}/vendor/"
    echo "OK"
}

install_escape_go_deps() {
    echo $DEPENDS | jq -r '.[]' | while read line ; do
        local arrDepends=(${line//:/ })
        copy_dep_to_vendor ${arrDepends[0]} ${arrDepends[1]}
    done
}


prepare_volume() {
    echo -n "Preparing Docker data volume..."
    docker create -v ${DOCKER_PACKAGE_PARENT_PATH} --name src golang:${DOCKER_VERSION} mkdir /code 1>/dev/null 2>&1
    docker cp "$PWD" "src:${DOCKER_PACKAGE_PARENT_PATH}/tmp" 1>/dev/null
    docker_run "${DOCKER_PACKAGE_PARENT_PATH}" "mv tmp ${DOCKER_PACKAGE_PATH}" 1>/dev/null
    echo "OK"
}

docker_run() {
    local cwd=$1
    local cmd=$2
    echo "Running '${cmd}' in Docker directory '${cwd}':"
    docker run --rm --volumes-from src -w "$cwd" golang:${DOCKER_VERSION} bash -c "${cmd}"
}

copy_binary_out_of_volume() {
    local binary_name=$1
    docker cp "src:${DOCKER_PACKAGE_PATH}/${binary_name}" "${binary_name}"
}

main() {
    install_escape_go_deps
    cleanup_docker
    prepare_volume 
    docker_run "${DOCKER_PACKAGE_PATH}" "go build -v"
    copy_binary_out_of_volume "${BINARY_NAME}"
}

trap cleanup_docker EXIT
main
