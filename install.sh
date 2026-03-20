#!/bin/bash

set -e

echo "Building FSX..."

nasm -f elf64 fsx.asm -o fsx.o

ld fsx.o -o fsx

echo "Installing FSX to /usr/local/bin..."

sudo mv fsx /usr/local/bin/fsx
sudo chmod +x /usr/local/bin/fsx

echo "FSX installed successfully!"

echo "Try running:"
echo "   fsx --help"