#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"  # relative
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)" # absolutized and normalized

source "${SCRIPT_DIR}/.env"

MINGW_PACKAGES="emacs ${MINGW_PACKAGES}"

generate_filter_file() {
    echo "- /distrib"
    echo "- /msys"
    for p in $MINGW_EXCLUDED_ENVIRONMENTS; do echo "- /mingw/$p"; done
    for p in $MINGW_PACKAGES; do echo "+ **/mingw*-$p-*.zst"; done
    for p in $MINGW_INCLUDED_ENVIRONMENTS; do echo "- /mingw/$p/*"; done
    echo "- *.sig"
}

TEMPFILE=$(mktemp)
generate_filter_file > "$TEMPFILE"

RSYNC_ARGS=(-rlptH --safe-links --delete-delay --delay-updates
            --human-readable --verbose --progress
            --filter="merge $TEMPFILE")
if [ "$1" == "--dry-run" ]; then
    RSYNC_ARGS+=("--dry-run")
fi

rsync "${RSYNC_ARGS[@]}" rsync://repo.msys2.org/builds/ "$MSYS2_REPO"
