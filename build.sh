#!/bin/bash -e

set -euf -o pipefail

BINARY_NAME="${INPUT_binary_name}"
PACKAGE_NAME="${INPUT_package_name}"
COPY_FILES="${INPUT_copy_files_after_build}"
BUILD_COMMAND="${INPUT_build_command}"
DEPENDS=${INPUT_escape_go_dependencies}
VENDOR=${INPUT_go_vendor_path}

DOCKER_PACKAGE_PATH="/go/src/${PACKAGE_NAME}"
DOCKER_PACKAGE_PARENT_PATH=$(dirname "${DOCKER_PACKAGE_PATH}")
GOLANG_DOCKER_IMAGE=${INPUT_go_docker_image}

cleanup_docker() {
    echo -n "Removing Docker data volume..."
    docker rm -v src 1>/dev/null 2>&1 || true
    echo "OK"
}

copy_dep_to_vendor() {
    local dep="deps/${1}"
    local target="${VENDOR}/${2}"
    echo -n "Copying Escape dependency '$dep' to '$target'..."
    rm -rf "$target"
    cp -r "$dep" "$target"
    rm -rf "${target}/vendor/"
    echo "OK"
    echo -n "Deleting binaries bigger than 1M from ${target}..."
    find "${target}" -type f -executable -size +1M -delete
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
    docker create -v ${DOCKER_PACKAGE_PARENT_PATH} --name src ${GOLANG_DOCKER_IMAGE}  mkdir /code 1>/dev/null 2>&1
    docker cp "$(realpath $PWD)" "src:${DOCKER_PACKAGE_PARENT_PATH}/tmp" 1>/dev/null
    docker_run "${DOCKER_PACKAGE_PARENT_PATH}" "mv tmp ${DOCKER_PACKAGE_PATH}" 1>/dev/null
    echo "OK"
}

docker_run() {
    local cwd=$1
    local cmd=$2
    echo "Running '${cmd}' in Docker directory '${cwd}' (image ${GOLANG_DOCKER_IMAGE}):"
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

copy_binary_out_of_volume() {
    local binary_name=$1
    if [ "$binary_name" = "" ] ; then
        return
    fi
    docker cp "src:${DOCKER_PACKAGE_PATH}/${binary_name}" "${binary_name}"
}

copy_files_out_of_volume() {
    echo $COPY_FILES | jq -r '.[]' | while read line ; do
        local arrDepends=(${line//:/ })
        docker cp "src:${DOCKER_PACKAGE_PATH}/${arrDepends[0]}" "${arrDepends[1]}"
    done
}

main() {
    install_escape_go_deps
    if [ "${BINARY_NAME}" = "" ] && [ "${BUILD_COMMAND}" = "" ] ; then
        echo "No binary name specified. Skipping build."
        exit 0
    fi
    cleanup_docker
    prepare_volume 
    docker_run "${DOCKER_PACKAGE_PATH}" "${BUILD_COMMAND:-"go build -v"}"
    copy_binary_out_of_volume "${BINARY_NAME}"
    copy_files_out_of_volume
}

trap cleanup_docker EXIT
main
