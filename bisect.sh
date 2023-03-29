#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"  # relative
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)" # absolutized and normalized

source "${SCRIPT_DIR}/.env"

get_package_version() {
    local PACKAGE="$1"
    case $PACKAGE in
        "gcc-libs")
            PACKAGE="gcc"
            ;;
        "libwinpthread-git")
            PACKAGE="winpthreads-git"
            ;;
    esac
    local PKGBUILD="mingw-w64-$PACKAGE/PKGBUILD"

    local PKGVER=$(grep "^pkgver=" $PKGBUILD | sed -e 's/pkgver=//g')
    local PKGREL=$(grep "^pkgrel=" $PKGBUILD | sed -e 's/pkgrel=//g')

    echo $PKGVER-$PKGREL
}

install_mingw_packages() {
    declare -a PACKAGES
    for p in $MINGW_PACKAGES; do
        VERSION=$(get_package_version $p)
        PACKAGE=$(printf "%s/mingw%s/%s-$p-%s-any.pkg.tar.zst" "$MSYS2_REPO" "$MINGW_PREFIX" "$MINGW_PACKAGE_PREFIX" "$VERSION")
        if [ -e "$PACKAGE" ]; then
            PACKAGES+=("$PACKAGE")
        else
            exit 125
        fi
    done
    pacman -U --noconfirm --nodeps --nodeps ${PACKAGES[@]}
}

build_emacs() {
    pushd "mingw-w64-emacs"
    makepkg-mingw --force --log &> /dev/null
    popd
}

test_emacs() {
    if [ -z "$1" ]; then
        EMACS_BIN=$(realpath "mingw-w64-emacs/pkg/$MINGW_PACKAGE_PREFIX-emacs$MINGW_PREFIX/bin/emacs")
    else
        EMACS_BIN="$1"
    fi
    ELISP_TEST_OUTPUT=res

    pushd "$SCRIPT_DIR"
    rm -f "$ELISP_TEST_OUTPUT"
    $EMACS_BIN --quick --batch --load test.el --funcall test-subprocesses
    RES=$(cat "$ELISP_TEST_OUTPUT")
    rm -f "$ELISP_TEST_OUTPUT"
    popd

    echo $RES
}

main() {
    install_mingw_packages
    build_emacs
    RES=$(test_emacs)
    git clean -d -f 
    exit $RES
}

main
