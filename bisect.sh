#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"  # relative
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)" # absolutized and normalized

source "${SCRIPT_DIR}/.env"
source "${SCRIPT_DIR}/lib.sh"

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
    install_current_makedeps emacs
    build_emacs
    RES=$(test_emacs)
    git clean -d -f 
    exit $RES
}

main
