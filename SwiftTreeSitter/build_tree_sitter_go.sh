#!/bin/sh

#  build_tree_sitter_go.sh
#  SwiftTreeSitter
#
#  Created by Matt Massicotte on 2020-06-23.
#  Copyright © 2020 Example. All rights reserved.

set -euxo pipefail

echo $PATH
export PATH="$PATH:/usr/local/bin/"

if [[ -f prebuilt/libtree_sitter_go.a ]]; then
    cp prebuilt/libtree_sitter_go.a tree-sitter-go/libtree_sitter_go.a
fi

cp SwiftTreeSitter/modifications/tree-sitter-go-module.modulemap tree-sitter-go/module.modulemap
cp SwiftTreeSitter/modifications/go.h tree-sitter-go/

if [[ $ARCHS == "arm64 x86_64" || $ARCHS == "x86_64 arm64" ]]; then
    cp SwiftTreeSitter/modifications/binding.gyp.universal tree-sitter-go/binding.gyp
else
    cp SwiftTreeSitter/modifications/binding.gyp tree-sitter-go/binding.gyp
fi

pushd tree-sitter-go

if [[ ! -f libtree_sitter_go.a ]]; then
    npm install
    ar rcs libtree_sitter_go.a build/Release/obj.target/tree_sitter_go_binding/src/*
fi

popd
