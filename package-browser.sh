#!/bin/bash

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR=$REPO_DIR/build
INSTALL_DIR=$BUILD_DIR/install
PKG_PATH=$BUILD_DIR/sqlite-composer-linux.tar.gz


# PACKAGE FOR LINUX

#TOP_LEVEL_NAME="sqlite-composer"
#rm -f $TOP_LEVEL_NAME
#ln -s $TOP_LEVEL_NAME $INSTALL_DIR
cd $INSTALL_DIR
rm -f $PKG_PATH
tar -czf $PKG_PATH *