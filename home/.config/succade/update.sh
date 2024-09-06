#!/usr/bin/env bash

cd /tmp/
rm -rf ./succade
git clone https://github.com/domsson/succade.git

cd succade/
chmod +x ./build ./install

./build
./install
