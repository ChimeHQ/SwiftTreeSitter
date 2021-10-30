#!/bin/sh

#  build_tree_sitter.sh
#  SwiftTreeSitter
#
#  Created by Matt Massicotte on 2020-06-23.
#  Copyright © 2020 Example. All rights reserved.

set -euxo pipefail

cp SwiftTreeSitter/modifications/tree-sitter-module.modulemap tree-sitter/module.modulemap

if [ -f prebuilt/libtree-sitter.a ]; then
    cp prebuilt/libtree-sitter.a tree-sitter/libtree-sitter.a
fi

pushd tree-sitter

if [[ $ARCHS == "arm64 x86_64" || $ARCHS == "x86_64 arm64" ]]; then
    CFLAGS="-mmacosx-version-min=10.13 -arch arm64 -arch x86_64"
else
    CFLAGS="-mmacosx-version-min=10.13"
fi

if [ ! -f libtree-sitter.a ]; then
    git submodule update --init
    CFLAGS=$CFLAGS ./script/build-lib
fi

popd
