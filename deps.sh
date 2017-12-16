#!/bin/bash -e

set -euf -o pipefail

copy_dep_to_vendor() {
    local dep="deps/${1}"
    local target="vendor/${2}"
    echo -n "Copying Escape dependency '$dep' to '$target'..."
    rm -rf "$target"
    cp -r "$dep" "$target"
    rm -rf "${target}/vendor/"
    echo "OK"
}

