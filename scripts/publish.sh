#!/bin/bash

cd "$(git rev-parse --show-toplevel)"

cp README.md contracts

cd contracts

npm publish --access public

rm README.md