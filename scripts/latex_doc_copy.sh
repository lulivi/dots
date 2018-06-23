#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>

SOURCE_DIR="$HOME/git/latex-project-example"
TARGET_DIR="${1:-$(pwd)}"

[ ! -d $SOURCE_DIR ] && {
    echo "Error, $SOURCE_DIR is not a directory"
    exit 1
}

[ ! -d $TARGET_DIR ] && {
    echo "Error $TARGET_DIR is not a directory"
    exit 1
}

echo "Copying LaTeX project..."
echo "  from $SOURCE_DIR"
echo "  to   $TARGET_DIR"

ln -s $SOURCE_DIR/update_pdf_latex.sh $TARGET_DIR
ln -s $SOURCE_DIR/style.sty           $TARGET_DIR
cp    $SOURCE_DIR/document.tex        $TARGET_DIR
cp    $SOURCE_DIR/references.bib      $TARGET_DIR
