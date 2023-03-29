#!/usr/bin/env bash

source .env

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

rsync -rlptH --safe-links --delete-delay --delay-updates \
      --human-readable --verbose --progress \
      --filter="merge $TEMPFILE" \
      rsync://repo.msys2.org/builds/ "$MSYS2_REPO"
