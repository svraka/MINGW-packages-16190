pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

get_pkgbuild_name() {
    PACKAGE="$1"
    case $PACKAGE in
        crt)
            PACKAGE="crt-git"
            ;;
        gcc-libs|libgccjit|cc)
            PACKAGE="gcc"
            ;;
        libwinpthread-git|libwinpthread|winpthreads)
            PACKAGE="winpthreads-git"
            ;;
        libtre)
            PACKAGE="libtre-git"
            ;;
        *)
            PACKAGE=$PACKAGE
            ;;
    esac
    echo "$PACKAGE"
}

translate_provides() {
    PACKAGE="$1"
    case $PACKAGE in
        cc)
            PACKAGE="gcc"
            ;;
        crt|libtre|libwinpthread|winpthreads)
            PACKAGE="${PACKAGE}-git"
            ;;
        *)
            PACKAGE=$PACKAGE
            ;;
    esac
    echo "$PACKAGE"
}

get_pkgbuild_file() {
    PACKAGE="$1"
    PACKAGE=$(get_pkgbuild_name "$PACKAGE")
    echo "mingw-w64-$PACKAGE/PKGBUILD"
}

get_package_makedeps() {
    PKGBUILD=$(get_pkgbuild_file "$1")
    MAKEDEPS=$(source "$PKGBUILD" && MAKEDEPS=("${depends[@]}" "${makedepends[@]}") && echo "${MAKEDEPS[@]}" | tr ' ' '\n')
    # Let's not deal with MSYS packages
    MAKEDEPS=$(echo "${MAKEDEPS}" | grep "^${MINGW_PACKAGE_PREFIX}-")
    echo "${MAKEDEPS}"
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
    ALLDEPS=$(echo "${ALLDEPS}" | sort | uniq)
    echo "${ALLDEPS}"
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
        p=$(translate_provides "$p")
        VERSION=$(get_package_version "$p")
        TARBALL=$(printf "%s/mingw%s/%s-$p-%s-any.pkg.tar.zst" "$MSYS2_REPO" "$MINGW_PREFIX" "$MINGW_PACKAGE_PREFIX" "$VERSION")
        if [ -e "$TARBALL" ]; then
            PACKAGE_TARBALLS+=("$TARBALL")
        else
            echo "Tarball not found: $TARBALL"
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
