#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"  # relative
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)" # absolutized and normalized

source "${SCRIPT_DIR}/.env"
source "${SCRIPT_DIR}/lib.sh"

list_paths() {
    PACKAGE="$1"
    PACKAGES=$(get_recursive_package_makedeps "$PACKAGE" | sed -e "s/${MINGW_PACKAGE_PREFIX}-//g")
    read -d "\034" -r -a PACKAGES <<<"${PACKAGES}\034"
    PKGBUILDS=($(get_pkgbuild_file "$PACKAGE"))
    for p in "${PACKAGES[@]}"; do
        p=$(get_pkgbuild_file "$p")
        PKGBUILDS+=("$p")
    done

    printf '%s\n' "${PKGBUILDS[@]}" | sort | uniq
}

list_paths emacs
