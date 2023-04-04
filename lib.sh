#!/usr/bin/env bash

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

get_pkgbuild_name() {
    PACKAGE="$1"
    if [[ "${MINGW_PREFIX}" =~ /clang.* ]]; then
        case $PACKAGE in
            cc|clang|clang-analyzer|clang-tools-extra|compiler-rt|gcc-compat|lld|llvm)
                PACKAGE="clang"
                ;;
            gcc-libs|libunwind)
                PACKAGE="libc++"
                ;;
        esac
    else
        case $PACKAGE in
            cc|gcc|gcc-libs|libgccjit)
                PACKAGE="gcc"
                ;;
        esac
    fi
    case $PACKAGE in
        crt)
            PACKAGE="crt-git"
            ;;
        libwinpthread-git|libwinpthread|winpthreads)
            PACKAGE="winpthreads-git"
            ;;
        libtre)
            PACKAGE="libtre-git"
            ;;
    esac
    echo "$PACKAGE"
}

resolve_provides() {
    PACKAGE="$1"
    if [[ "${p}" =~ ${MINGW_PACKAGE_PREFIX}-* ]]; then
        PACKAGE_BASE="${PACKAGE#${MINGW_PACKAGE_PREFIX}-}"
        case $PACKAGE_BASE in
            cc)
                if [[ "${MINGW_PREFIX}" =~ /clang.* ]]; then
                    PACKAGE_BASE="clang"
                else
                    PACKAGE_BASE="gcc"
                fi
                ;;
            gcc-libs)
                if [[ "${MINGW_PREFIX}" =~ /clang.* ]]; then
                    PACKAGE_BASE="libc++"
                fi
                ;;
            crt|libtre|libwinpthread|winpthreads)
                PACKAGE_BASE="${PACKAGE_BASE}-git"
                ;;
            *)
                PACKAGE_BASE=$PACKAGE_BASE
                ;;
        esac
        PACKAGE_CLEAN="${MINGW_PACKAGE_PREFIX}-${PACKAGE_BASE}"
    else
        PACKAGE_CLEAN="${PACKAGE}"
    fi

    echo "$PACKAGE_CLEAN"
}

get_pkgbuild_file() {
    PACKAGE="$1"
    PACKAGE=$(get_pkgbuild_name "$PACKAGE")
    echo "mingw-w64-$PACKAGE/PKGBUILD"
}

get_package_makedeps() {
    PKGBUILD=$(get_pkgbuild_file "$1")
    MAKEDEPS=($(source "$PKGBUILD" && MAKEDEPS=("${depends[@]}" "${makedepends[@]}") && echo "${MAKEDEPS[@]}"))

    declare -a MAKEDEPS_CLEAN
    for p in "${MAKEDEPS[@]}"; do
        p=$(resolve_provides "$p")
        # Let's not deal with MSYS packages
        if [[ "${p}" =~ ${MINGW_PACKAGE_PREFIX}-* ]]; then
            MAKEDEPS_CLEAN+=("$p")
        fi
    done

    printf '%s\n' "${MAKEDEPS_CLEAN[@]}"
}

get_recursive_package_makedeps() {
    PACKAGE="$1"
    MAKEDEPS=$(get_package_makedeps "$PACKAGE")
    declare -a ALLDEPS
    for p in ${MAKEDEPS}; do
        PACKAGE_DEPS=$(pactree -u $p)
        read -d "\034" -r -a PACKAGE_DEPS <<<"${PACKAGE_DEPS}\034"
        ALLDEPS+=("${PACKAGE_DEPS[@]}")
    done

    ALLDEPS=$(printf '%s\n' "${ALLDEPS[@]}")
    # Let's not deal with MSYS packages here either
    ALLDEPS=$(echo "$ALLDEPS" | grep "^${MINGW_PACKAGE_PREFIX}-")
    # Remove version reqs
    ALLDEPS=$(echo "$ALLDEPS" | sed -e "s/[=<>].\+//g")
    declare -a ALLDEPS_CLEAN
    for p in ${ALLDEPS}; do
        p=$(resolve_provides "${p}")
        ALLDEPS_CLEAN+=("${p}")
    done
    ALLDEPS_CLEAN=$(printf '%s\n' "${ALLDEPS_CLEAN[@]}")
    ALLDEPS_CLEAN=$(echo "${ALLDEPS_CLEAN}" | sort | uniq)
    echo "${ALLDEPS_CLEAN}"
}

get_package_version() {
    PKGBUILD=$(get_pkgbuild_file "$1")
    RES=$(source $PKGBUILD && echo ${pkgver}-${pkgrel})
    echo $RES
}

install_packages_from_current_revision() {
    PACKAGES="$1"
    declare -a PACKAGE_TARBALLS
    for p in $PACKAGES; do
        p=$(resolve_provides "$p")
        VERSION=$(get_package_version "$p")
        TARBALL=$(printf "%s/mingw%s/%s-$p-%s-any.pkg.tar" "$MSYS2_REPO" "$MINGW_PREFIX" "$MINGW_PACKAGE_PREFIX" "$VERSION")
        if [ -e "${TARBALL}.zst" ]; then
            PACKAGE_TARBALLS+=("${TARBALL}.zst")
        elif [ -e "${TARBALL}.xz" ]; then
            PACKAGE_TARBALLS+=("${TARBALL}.xz")
        else
            echo "Tarball not found: ${TARBALL}.{zst,xz}"
            exit 125
        fi
    done
    printf '%s\n' "${PACKAGE_TARBALLS[@]}" | sort | uniq | pacman -U --noconfirm --nodeps --nodeps -
}

install_current_makedeps() {
    PACKAGE="$1"
    PACKAGES=$(get_recursive_package_makedeps "$PACKAGE" | sed -e "s/${MINGW_PACKAGE_PREFIX}-//g" | tr '\n' ' ')
    install_packages_from_current_revision "$PACKAGES"
}
