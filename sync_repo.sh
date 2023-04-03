#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"  # relative
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)" # absolutized and normalized

source "${SCRIPT_DIR}/.env"
source "${SCRIPT_DIR}/lib.sh"

MINGW_PACKAGES=$(get_recursive_package_makedeps emacs)

generate_filter_file() {
    echo "- /distrib"
    echo "- /msys"
    echo "- *.sig"
    for p in $MINGW_PACKAGES; do echo "+ /mingw${MINGW_PREFIX}/${p}-*.tar.*"; done
    echo "+ */"
    echo "- *"
}

TEMPFILE=$(mktemp)
generate_filter_file > "$TEMPFILE"

RSYNC_ARGS=(-rlptH --safe-links --delay-updates
            --human-readable --verbose --progress
            --filter="merge $TEMPFILE")
if [ "$1" == "--dry-run" ]; then
    RSYNC_ARGS+=("--dry-run")
fi

rsync "${RSYNC_ARGS[@]}" rsync://repo.msys2.org/builds/ "$MSYS2_REPO"
