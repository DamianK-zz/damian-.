#!/bin/bash

for pkg in gnupg@2.0 monkeysphere; do
    if brew list -1 | grep -q "^${pkg}\$"; then
        echo "Package '$pkg' is installed"
    else
        echo "Package '$pkg' is not installed, installing..."
        brew install $pkg
    fi
done

echo "Start Export Process"

echo "Log into Keybase..."
keybase login

echo "Exporting your PGP keys..."
keybase pgp export -o keybase.public.key
keybase pgp export -s -o keybase.private.key

echo "Importing your Keybase keys..."
gpg -q --import keybase.public.key
gpg -q --allow-secret-key-import --import keybase.private.key
gpg --list-keys | grep '^pub\s*.*\/*.\s.*' | grep -oEi '\/(.*)\s' | cut -c 2- | awk '{$1=$1};1' > hash.key

echo "Generating RSA keys..."
gpg --export-options export-reset-subkey-passwd,export-minimal,no-export-attributes --export-secret-keys --no-armor `cat hash.key` | openpgp2ssh `cat hash.key` > id_rsa
chmod 400 id_rsa
ssh-keygen -y -f id_rsa > id_rsa.pub

echo "Cleaning up..."
rm *.key

echo "Success"
