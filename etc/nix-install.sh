#!/bin/bash
set -e
base=$1
shift;
export nix_boot=${NIX_BOOT-$base/nix-boot/usr}
export nix_root=${NIX_ROOT-$base/nix}
export nix_bin=$nix_root/var/nix/profiles/default/bin
export RUN_EXPENSIVE_TESTS=no

export PATH=$nix_boot/bin:/usr/bin:/bin                           # wiki
export PKG_CONFIG_PATH=$nix_boot/lib/pkgconfig:$PKG_CONFIG_PATH   # wiki
export LDFLAGS="-L$nix_boot/lib -L$nix_boot/lib64 $LDFLAGS"       # wiki
export CPPFLAGS="-I$nix_boot/include $CPPFLAGS"                   # wiki
export PERL5OPT="-I$nix_boot/lib/perl"                            # wiki
#export PERL5OPT="-I$nix_boot/lib64/perl5"                        # wiki on some systems.
export NIXPKGS=$base/nix-boot/nixpkgs
unset PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT        # Perl INSTALLBASE error.

all="get prepare nixpkgs\
  gcc \
  bzip2 \
  curl \
  sqlite \
  dbi \
  dbd \
  wwwcurl \
  bison \
  flex \
  coreutils \
  nixbootstrap nix nixconfig nixprofile"

get() {
  # remove echo to download.
  echo wget -c $1
}
case $1 in
  -h) echo $all; exit 0;;
  get)
    mkdir -p src
    (cd ./static;
    files="https://nixos.org/releases/nix/nix-1.10/nix-1.10.tar.xz
           http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz
           http://curl.haxx.se/download/curl-7.35.0.tar.lzma
           https://www.sqlite.org/2014/sqlite-autoconf-3080300.tar.gz
           http://pkgs.fedoraproject.org/repo/extras/perl-DBI/DBI-1.631.tar.gz/444d3c305e86597e11092b517794a840/DBI-1.631.tar.gz
           http://pkgs.fedoraproject.org/repo/pkgs/perl-DBD-SQLite/DBD-SQLite-1.40.tar.gz/b9876882186499583428b14cf5c0e29c/DBD-SQLite-1.40.tar.gz
           http://search.cpan.org/CPAN/authors/id/S/SZ/SZBALINT/WWW-Curl-4.15.tar.gz
           http://ftp.gnu.org/gnu/bison/bison-3.0.4.tar.gz
           http://sourceforge.mirrorservice.org/f/fl/flex/flex-2.5.36.tar.gz
           https://ftp.gnu.org/gnu/gcc/gcc-4.9.2/gcc-4.9.2.tar.gz
           http://ftp.gnu.org/gnu/coreutils/coreutils-8.23.tar.xz"
      for i in $files;
      do
        y=$(echo $i | sed -e 's#.*/##g')
        get -c $i;
        case $i in
          *xz) xzcat $y;;
          *gz) zcat $y;;
          *lzma) xzcat $y;;
          *tar) cat $y;;
          *) cat $y;;
        esac | (cd ../src && tar -xvpf -)
      done )
    ;;
  -sh) (
    export LD_LIBRARY_PATH="$nix_boot/lib:$nix_boot/lib64:$LD_LIBRARY_PATH";
    $2; );
    exit 0;;
bzip2)
(cd src/bzip2-1.0.6;
  make -f Makefile-libbz2_so;
  make install PREFIX=$nix_boot;
  cp libbz2.so.1.0 libbz2.so.1.0.6 $nix_boot/lib; ) ;;

curl)
(cd src/curl-7.35.0/;
  ./configure --prefix=$nix_boot;
  make;
  make install; ) ;;

sqlite)
(cd src/sqlite-autoconf-3080300/;
  ./configure --prefix=$nix_boot;
  make;
  make install; ) ;;

libxml2)
  (cd src/libxml2-2.9.2; ./configure --prefix=$nix_boot;
  make;
  cp ./libxml2-2.9.2/xmllint $nix_boot/bin
  # make install;
  ) ;;

libxslt)
  (cd src/libxslt-1.1.28;  ./configure --prefix=$nix_boot;
  make;
  make install; ) ;;

gcc)
  (cd src/gcc-4.9.2; ./contrib/download_prerequisites; )
  rm -rf src/gcc-objs;
  mkdir -p src/gcc-objs
  (cd src/gcc-objs; ./../gcc-4.9.2/configure --prefix=$nix_boot --disable-multilib;
  make;
  make install; ) ;;

bison)
  (cd src/bison-3.0*; ./configure --prefix=$nix_boot;
  make;
  make install; ) ;;

flex)
  (cd src/flex-2.5.*;  ./configure --prefix=$nix_boot;
  make;
  make install; );;

coreutils)
  (cd src/coreutils-8.23;  ./configure --enable-install-program=hostname --prefix=$nix_boot;
  make;
  make install; );;

bash)
  (cd src/bash-4.3;  ./configure --prefix=$nix_boot;
  make;
  make install; );;

dbi)
(cd src/DBI-1.631/;
  echo perl Makefile.PL PREFIX=$nix_boot PERLMAINCC=$nix_boot/bin/gcc > myconfig.sh;
  chmod +x myconfig.sh;
  ./myconfig.sh;
  make;
  make install; ) ;;

dbd)
(cd src/DBD-SQLite-1.40/;
  echo perl Makefile.PL PREFIX=$nix_boot PERLMAINCC=$nix_boot/bin/gcc > myconfig.sh;
  chmod +x myconfig.sh;
  ./myconfig.sh;
  make;
  make install; ) ;;

wwwcurl)
(cd src/WWW-Curl-4.15;
  echo perl Makefile.PL PREFIX=$nix_boot PERLMAINCC=$nix_boot/bin/gcc > myconfig.sh;
  chmod +x myconfig.sh;
  ./myconfig.sh;
  make;
  make install; ) ;;

prepare)
  rm -rf nix
  rm -rf $NIXPKGS
  rm -rf ~/.nix-profile
  git clone https://github.com/NixOS/nix nix
  ;;

nixpkgs)
  git clone git@github.com:NixOS/nixpkgs.git $NIXPKGS
  (cd $NIXPKGS && cat ~/.home/non-nix.patch | patch -p1 )
  ;;

nixbootstrap)
(cd nix;
  ./bootstrap.sh ) ;;

nix)
(cd nix;
  echo "./configure --prefix=$nix_boot \
                    --with-store-dir=$nix_root/store \
                    --localstatedir=$nix_root/var" > myconfig.sh;
  chmod +x ./myconfig.sh
  ./myconfig.sh
  # --with-coreutils-bin=$nix_boot/usr/bin;
  /usr/bin/perl -pi -e 's#--nonet# #g' doc/manual/local.mk;
  echo "GLOBAL_LDFLAGS += -lpthread" >> doc/manual/local.mk;
  make;
  make install; ) ;;

nixconfig)
  (
  export LD_LIBRARY_PATH="$nix_boot/lib:$nix_boot/lib64:$LD_LIBRARY_PATH";
  echo $LD_LIBRARY_PATH;
  # nix-channel --add http://nixos.org/channels/nixpkgs-unstable && \
  # nix-channel --update &&
  # nix-env -i nix
  # $nix_boot/bin/nix-env -i nix-1.12pre4523_3b81b26 -f $NIXPKGS
  $nix_boot/bin/nix-env -iA nixUnstable -f $NIXPKGS
  )
  echo recheck
  $nix_root/var/nix/profiles/default/bin/nix-env -iA nixUnstable
 ;;

nixprofile)
  ln -s $nix_root/var/nix/profiles/default $HOME/.nix-profile
  ;;

all) echo all
     for i in $all;
     do
       env nix_boot=$nix_boot nix_root=$nix_root ./$0 $base $i ;
     done ;;

*) echo $0 '<install-base>' all
   echo $all;
   echo nix_root=$nix_root
   echo nix_boot=$nix_boot
   echo PATH=$PATH
   echo PKG_CONFIG_PATH=$PKG_CONFIG_PATH
   echo LDFLAGS=$LDFLAGS
   echo CPPFLAGS=$CPPFLAGS
   echo PERL5OPT=$PERL5OPT
   echo NIXPKGS=$NIXPKGS ;;
esac
