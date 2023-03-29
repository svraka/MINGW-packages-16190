#!/usr/bin/env bash

MSYS2_REPO="/c/Users/SvrakaA/Downloads/msys2"
MINGW_PACKAGES="emacs gcc gcc-libs crt-git headers-git libmangle-git tools-git winpthreads-git libwinpthread-git winstorecompat-git"
MINGW_EXCLUDED_DIRS="i686 x86_64 mingw32 mingw64 clang32 clang64 clangarm64 sources"
MINGW_INCLUDED_DIRS="ucrt64"

generate_filter_file() {
    echo "- /distrib"
    echo "- /msys"
    for p in $MINGW_EXCLUDED_DIRS; do echo "- /mingw/$p"; done
    for p in $MINGW_PACKAGES; do echo "+ **/mingw*-$p-*.zst"; done
    for p in $MINGW_INCLUDED_DIRS; do echo "- /mingw/$p/*"; done
    echo "- *.sig"
}

TEMPFILE=$(mktemp)
generate_filter_file > "$TEMPFILE"

rsync -rlptH --safe-links --delete-delay --delay-updates \
      --human-readable --verbose --progress \
      --filter="merge $TEMPFILE" \
      rsync://repo.msys2.org/builds/ "$MSYS2_REPO"
