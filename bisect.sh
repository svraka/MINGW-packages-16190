#!/usr/bin/env bash

MSYS2_REPO="/c/Users/SvrakaA/Downloads/msys2"
MINGW_PACKAGES="gcc gcc-libs crt-git headers-git libmangle-git tools-git winpthreads-git libwinpthread-git winstorecompat-git"
EMACS_BIN="mingw-w64-emacs/pkg/$MINGW_PACKAGE_PREFIX-emacs$MINGW_PREFIX/bin/emacs"
ELISP_TEST_LIBRARY="../MINGW-packages-16190/test.el"
ELISP_TEST_FUNCTION="test-subprocesses"
ELISP_TEST_OUTPUT="../MINGW-packages-16190/res"

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
    pushd mingw-w64-emacs
    makepkg-mingw --force --log &> /dev/null
    popd
}

test_emacs() {
    local EMACS_BIN="$1"

    rm -f "$ELISP_TEST_OUTPUT"
    $EMACS_BIN --quick --batch --load "$ELISP_TEST_LIBRARY" --funcall "$ELISP_TEST_FUNCTION"
    RES=$(cat "$ELISP_TEST_OUTPUT")
    rm -f "$ELISP_TEST_OUTPUT"
    echo $RES
}

main() {
    install_mingw_packages
    build_emacs
    RES=$(test_emacs $EMACS_BIN)
    git clean -d -f 
    exit $RES
}

main
