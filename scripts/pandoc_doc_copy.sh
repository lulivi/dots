#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>

SOURCE_DIR="$HOME/git/markdown-pandoc-example"
TARGET_DIR="${1:-$(pwd)}"

[ ! -d $git_dir ] && {
    echo "Error, $git_dir is not a directory"
    exit 1
}

[ ! -d $TARGET_DIR ] && {
    echo "Error $TARGET_DIR is not a directory"
    exit 1
}

echo "Copying pandoc project..."
echo "  from $SOURCE_DIR"
echo "  to   $TARGET_DIR"

cp $SOURCE_DIR/document.doc.md $TARGET_DIR
cp $SOURCE_DIR/titlepage.tex   $TARGET_DIR
cp $SOURCE_DIR/references.bib  $TARGET_DIR
cp -r $SOURCE_DIR/img          $TARGET_DIR
ln -s $SOURCE_DIR/automake.sh  $TARGET_DIR
ln -s $SOURCE_DIR/ieee.csl     $TARGET_DIR
ln -s $SOURCE_DIR/Makefile     $TARGET_DIR
ln -s $SOURCE_DIR/template.tex $TARGET_DIR
