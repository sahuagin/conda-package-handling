#!/usr/bin/env bash

# Build libarchive as a static library with support for the features needed for
# conda-package-handling (bzip2, zlib, zstd).
# This is not a general purpose libarchive.
MAKE=${MAKE:-make}
autoreconf -vfi
mkdir build-${HOST} && pushd build-${HOST}
${SRC_DIR}/configure --prefix=${PREFIX}     \
                     --enable-bsdtar=static \
                     --enable-static        \
                     --with-bz2lib          \
                     --with-iconv           \
                     --with-zlib            \
                     --with-zstd            \
                     --disable-bsdcat       \
                     --disable-bsdcpio      \
                     --disable-shared       \
                     --without-cng          \
                     --without-expat        \
                     --without-lz4          \
                     --without-lzma         \
                     --without-lzo2         \
                     --without-nettle       \
                     --without-openssl      \
                     --without-xml2
${MAKE} -j${CPU_COUNT} ${VERBOSE_AT}
${MAKE} install
popd

# remove the man pages
rm -rf ${PREFIX}/share/man

# create libarchive_and_deps.a
if [[ ${HOST} =~ .*darwin.* ]]; then
    mkdir -p tmp_reform
    pushd tmp_reform
    # extract the object files into seperate directories since some of the
    # archives have members of the same name (e.g.  compress.o). See:
    # https://stackoverflow.com/a/23557928
    for name in libz libbz2 libzstd libiconv libarchive
    do
        ${AR} -x ${PREFIX}/lib/${name}.a
        mkdir -p ${name}_objs
        mv *.o ${name}_objs
    done
    ${AR} crv libarchive_and_deps.a */*.o
    ranlib libarchive_and_deps.a
    cp libarchive_and_deps.a ${PREFIX}/lib/
    popd
fi
if [[ ${HOST} =~ .*linux.* ]]; then
    pushd ${PREFIX}/lib
    ${AR} -M <<EOM
        CREATE libarchive_and_deps.a
        ADDLIB libarchive.a
        ADDLIB libbz2.a
        ADDLIB libz.a
        ADDLIB libzstd.a
        SAVE
        END
EOM
    ranlib libarchive_and_deps.a
    popd
fi
if [[ ${HOST} =~ .*freebsd.* ]]; then
    pushd ${PREFIX}/lib
    ${AR} -M <<EOM
        CREATE libarchive_and_deps.a
        ADDLIB libarchive.a
        ADDLIB /usr/lib/libbz2.a
        ADDLIB /usr/lib/libz.a
        ADDLIB /usr/local/lib/libzstd.a
        SAVE
        END
EOM
    ranlib libarchive_and_deps.a
    popd
fi
