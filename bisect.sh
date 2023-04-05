#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"  # relative
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)" # absolutized and normalized

source "${SCRIPT_DIR}/.env"
source "${SCRIPT_DIR}/lib.sh"

build_emacs() {
    echo "Compiling Emacs..." >&2
    pushd "mingw-w64-emacs"
    makepkg-mingw --force --log &> /dev/null
    popd
}

test_emacs() {
    if [ -z "$1" ]; then
        EMACS_BIN=$(realpath --canonicalize-missing --quiet "mingw-w64-emacs/pkg/$MINGW_PACKAGE_PREFIX-emacs$MINGW_PREFIX/bin/emacs")
    else
        EMACS_BIN="$1"
    fi
    if [ ! -e "$EMACS_BIN" ]; then
        echo "$EMACS_BIN does not exist" >&2
        return 127
    fi
    ELISP_TEST_OUTPUT=res

    echo "Testing Emacs..." >&2
    pushd "$SCRIPT_DIR"
    rm -f "$ELISP_TEST_OUTPUT"
    $EMACS_BIN --quick --batch --load test.el --funcall test-subprocesses
    RES=$(cat "$ELISP_TEST_OUTPUT")
    rm -f "$ELISP_TEST_OUTPUT"
    popd

    return $RES
}

main() {
    install_current_makedeps emacs
    build_emacs
    RES=$(test_emacs; echo "$?")
    echo "Test result: ${RES}" >&2
    git clean -d -f
    return $RES
}

main
