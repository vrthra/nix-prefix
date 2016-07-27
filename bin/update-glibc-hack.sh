#!/usr/bin/env bash
python=$(nix-build -A python $NIXPKGS)/bin/python
$python ./bin/check-nss.py
set -e
(cd nixpkgs/
git reset --hard remotes/origin/master
git fetch origin pull/14697/head:sssd
git cherry-pick \
  1f4f0e71f39ab2e10602c2e70e45065b8475f8de \
  3b1e666a3fc3d30404f095e4c0764b305a9fe2bd \
  d57d7ba9e7084328be3392464efbaaf8b66c1f7f \
  6379645543d9aed4eb696efc276691f17ac18f11 \
  3453451f39849e9cfb0f210848b5119bc9f93d0a \
  2c0351afea2eb0016de7358975740b23fdc6701c
)
nix-env -i sssd -f $NIXPKGS

nixdir=$(nix-build $NIXPKGS -A glibc.out)/lib
chmod 777 $nixdir
libnss=$(find ../nix -name libnss_sss.so.\* | grep sssd)
echo $libnss
cp -f $libnss $nixdir/
chmod 555 $nixdir
$python ./bin/check-nss.py
