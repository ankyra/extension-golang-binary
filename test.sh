#!/bin/bash -e

set -euf -o pipefail

PACKAGE_NAME="${INPUT_package_name}"
DOCKER_PACKAGE_PATH="/go/src/${PACKAGE_NAME}"
DOCKER_PACKAGE_PARENT_PATH=$(dirname "${DOCKER_PACKAGE_PATH}")
GOLANG_DOCKER_IMAGE=${INPUT_go_docker_image}
TEST_COMMAND=${INPUT_test_command:-"go test -cover -v \$(/usr/local/go/bin/go list ./... | grep -v -E 'vendor|deps' )"}

cleanup_docker() {
    echo -n "Removing Docker data volume..."
    docker rm -v src 1>/dev/null 2>&1 || true
    echo "OK"
}

prepare_volume() {
    echo -n "Preparing Docker data volume..."
    docker create -v ${DOCKER_PACKAGE_PARENT_PATH} --name src ${GOLANG_DOCKER_IMAGE} mkdir /code 1>/dev/null 2>&1
    docker cp "$PWD" "src:${DOCKER_PACKAGE_PARENT_PATH}/tmp" 1>/dev/null
    docker_run "${DOCKER_PACKAGE_PARENT_PATH}" "mv tmp ${DOCKER_PACKAGE_PATH}" 1>/dev/null
    echo "OK"
}

docker_run() {
    local cwd=$1
    local cmd=$2
    echo "Running '${cmd}' in Docker directory '${cwd}':"
    local dockerCmd="docker run --rm --volumes-from src -w '$cwd'"
    for var in $(env) ; do 
        if [[ $var == INPUT_* ]] || [[ $var == OUTPUT_* ]] || [[ $var == METADATA_* ]] ; then
          arrIN=(${var//=/ })
          if [ "${arrIN[1]+set}" == "set" ] ; then
              dockerCmd="$dockerCmd -e \"${var}\""
          fi
        fi
    done
    cmd=${cmd//\'/'"'"'"'"'}
    dockerCmd="$dockerCmd ${GOLANG_DOCKER_IMAGE} bash -c '$cmd'"
    eval $dockerCmd
}


main() {
    cleanup_docker
    prepare_volume
    docker_run "${DOCKER_PACKAGE_PATH}" "${TEST_COMMAND}"
}

trap cleanup_docker EXIT
main
