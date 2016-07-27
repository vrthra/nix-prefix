#!/usr/bin/env bash
set -e
python=$(nix-build -A python $NIXPKGS)/bin/python
$python ./bin/check-nss.py
nixdir=$(nix-build $NIXPKGS -A glibc.out)/lib
chmod 777 $nixdir
#libnss=$(find ../nix -name libnss_sss.so.\* | grep sssd)
#echo $libnss
#cp -f $libnss $nixdir/
rm $nixdir/libnss_sss.so.*
chmod 555 $nixdir
$python ./bin/check-nss.py
