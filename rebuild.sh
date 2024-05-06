#!/bin/sh
set -e -u -x

DOWNLOAD_NAME=3.0.0.tar.gz
DOWNLOAD_FILE="build/download/$DOWNLOAD_NAME"
DOWNLOAD_URL=https://github.com/mathjax/MathJax/archive/$DOWNLOAD_NAME
DOWNLOAD_HASH="6ead7d3367c1c3e1916a1c015d227d7a7c4a456c12841f4dec2ea1e5b22333a1"
PACKAGE_DIR=MathJax-3.0.0

download() {
    install -d build/download
    if ! test -f "$DOWNLOAD_FILE"; then
	wget -c -O "$DOWNLOAD_FILE" "$DOWNLOAD_URL"
    fi
    HASH=`sha256sum "$DOWNLOAD_FILE"`
    if ! test "$HASH" = "$DOWNLOAD_HASH  $DOWNLOAD_FILE"; then
        echo "Invalid checksum: $HASH"
	exit 1
    fi
    return 0
}

npm_install() {
    npm install --save-dev
}

unpack_patch() {
    rm -rf build/unpack
    install -d build/unpack
    (cd build/unpack && tar xz) < "$DOWNLOAD_FILE"
    cp Gruntfile.js "build/unpack/$PACKAGE_DIR"
    ln -s ../../../node_modules "build/unpack/$PACKAGE_DIR/node_modules"
    (cd "build/unpack/$PACKAGE_DIR" && \
	./node_modules/grunt-cli/bin/grunt TeX_SVG)
    rm -f "build/unpack/$PACKAGE_DIR/node_modules"
}

replace() {
    for f in LICENSE; do
	rm -rf "$f"
	mv "build/unpack/$PACKAGE_DIR/$f" "$f"
    done
    for f in extensions jax MathJax.js; do
	rm -rf "$f"
	mv "build/unpack/$PACKAGE_DIR/unpacked/$f" "$f"
    done
}

git_commit() {
    git add LICENSE extensions jax MathJax.js
    git add -u extensions jax
    git commit -m "MAINT: rebuild MathJax

    Base package: $DOWNLOAD_HASH  $DOWNLOAD_NAME"
}

download
npm_install
unpack_patch
# replace
# git_commit

echo "Rebuild successful!"

