base=/scratch/gopinatr
nix_pre=$(base)/nix-pre
nix_boot_usr=$(nix_pre)/usr
NIXPKGS=$(nix_pre)/nixpkgs

nix_root=$(base)/nix
nix_store=$(nix_root)/store
nix_var=$(nix_root)/var
nix_bin=$(nix_root)/var/nix/profiles/default/bin

logit= >> logs 2>&1
#@ nix=https://nixos.org/releases/nix/nix-1.10/nix-1.10.tar.xz
#@ bzip2=http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz
#@ curl=https://curl.haxx.se/download/curl-7.35.0.tar.lzma
#@ sqlite=https://www.sqlite.org/2014/sqlite-autoconf-3080300.tar.gz
#@ dbi=http://pkgs.fedoraproject.org/repo/extras/perl-DBI/DBI-1.631.tar.gz/444d3c305e86597e11092b517794a840/DBI-1.631.tar.gz
#@ dbd=http://pkgs.fedoraproject.org/repo/pkgs/perl-DBD-SQLite/DBD-SQLite-1.40.tar.gz/b9876882186499583428b14cf5c0e29c/DBD-SQLite-1.40.tar.gz
#@ wwwcurl=http://search.cpan.org/CPAN/authors/id/S/SZ/SZBALINT/WWW-Curl-4.15.tar.gz
#@ bison=http://ftp.gnu.org/gnu/bison/bison-3.0.4.tar.gz
#@ flex=http://sourceforge.mirrorservice.org/f/fl/flex/flex-2.5.36.tar.gz
#@ gcc=https://ftp.gnu.org/gnu/gcc/gcc-4.9.2/gcc-4.9.2.tar.gz
#@ coreutils=http://ftp.gnu.org/gnu/coreutils/coreutils-8.23.tar.xz

src_build=./configure --prefix=$(nix_boot_usr) && make && make install
perl_build=echo unset PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT > myconfig.sh && \
	echo perl Makefile.PL PREFIX=$(nix_boot_usr) PERLMAINCC=$(nix_boot_usr)/bin/gcc >> myconfig.sh && \
	chmod +x myconfig.sh && ./myconfig.sh && make && make install;

src=nix \
		bzip2 \
		curl \
		sqlite \
		dbi \
		dbd \
		wwwcurl \
		bison \
		flex \
		gcc \
		coreutils

.PHONY: get build nix

all: nix
	@echo done $^.

get: $(addsuffix .x,$(addprefix static/,$(src)))
	@echo done $^

extract: $(addsuffix .x/.extracted,$(addprefix build/,$(src)))
	@echo done $^

static/%.x: | static
	curl -C - -L $$(cat $(MAKEFILE_LIST) | sed -ne '/^#@ $*=/s/^[^=]*=//p') -o $@.tmp
	mv $@.tmp $@

build/%/.extracted: static/%
	mkdir -p build/$*
	case "$$(file static/$* | sed -e 's#^[^:]*: *##')" in \
		gzip*) zcat "$<";; \
		XZ*)   xzcat "$<";; \
		LZMA*) xzcat "$<";; \
		*) cat "$*";; \
		esac | (cd build/$* && tar -xpf -)
	touch $@

build/nix.x/.extracted:
	rm -rf build/nix.x && mkdir -p build/nix.x
	cd build/nix.x && git clone https://github.com/NixOS/nix nix
	touch $@

build/curl.x/.build: build/curl.x/.extracted
	(cd $(@D)/* && $(src_build) ) $(logit)
	touch $@

build/sqlite.x/.build: build/sqlite.x/.extracted
	(cd $(@D)/* && $(src_build) ) $(logit)
	touch $@

build/libxslt.x/.build: build/libxslt.x/.extracted
	(cd $(@D)/* && $(src_build) )  $(logit)
	touch $@

build/bison.x/.build: build/bison.x/.extracted
	(cd $(@D)/* && $(src_build) ) $(logit)
	touch $@

build/flex.x/.build: build/flex.x/.extracted
	(cd $(@D)/* && $(src_build) ) $(logit)
	touch $@

build/bash.x/.build: build/bash.x/.extracted
	(cd $(@D)/* && $(src_build) ) $(logit)
	touch $@

build/bzip2.x/.build: build/bzip2.x/.extracted
	(cd $(@D)/* && \
	make -f Makefile-libbz2_so && make install PREFIX=$(nix_boot_usr) && \
	cp libbz2.so.* $(nix_boot_usr)/lib; ) $(logit)
	touch $@

build/libxml2.x/.build: build/libxml2.x/.extracted
	(cd $(@D)/* && \
		./configure --prefix=$(nix_boot_usr) && make \
	cp ./libxml2-2.9.2/xmllint $(nix_boot_usr)/bin ) $(logit)
	touch $@

build/gcc.x/.build: build/gcc.x/.extracted
	(cd $(@D)/* && \
		rm -rf gcc-objs && mkdir -p gcc-objs && \
	  ./contrib/download_prerequisites; ) $(logit)
	(cd build/gcc.x/*/gcc-objs; ../configure --prefix=$(nix_boot_usr) --disable-multilib && make && make install; ) $(logit)
	touch $@

build/coreutils.x/.build: build/coreutils.x/.extracted
	(cd $(@D)/* && \
		./configure --enable-install-program=hostname --prefix=$(nix_boot_usr) && make && make install; ) $(logit)
	touch $@

build/dbi.x/.build: build/dbi.x/.extracted
	(cd $(@D)/* && $(perl_build)) $(logit)
	touch $@

build/dbd.x/.build: build/dbd.x/.extracted
	(cd $(@D)/* && $(perl_build)) $(logit)
	touch $@

build/wwwcurl.x/.build: build/wwwcurl.x/.extracted
	(cd $(@D)/* && $(perl_build)) $(logit)
	touch $@

build/nix.x/.build: build/nix.x/.extracted $(addprefix build/,$(addsuffix .x/.build, $(filter-out nix,$(src))))
	(cd $(@D)/* && \
	 echo "./configure --prefix=$(nix_boot_usr) --with-store-dir=$(nix_store) --localstatedir=$(nix_var)" > myconfig.sh && \
	chmod +x ./myconfig.sh && \
	/usr/bin/perl -pi -e 's#--nonet# #g' doc/manual/local.mk && \
	unset PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT && \
	echo "GLOBAL_LDFLAGS += -lpthread" >> doc/manual/local.mk && \
	export PATH=$(nix_boot_usr)/bin:/usr/bin:/bin && \
	export PKG_CONFIG_PATH=$(nix_boot_usr)/lib/pkgconfig:$(PKG_CONFIG_PATH) && \
	export LDFLAGS="-L$(nix_boot_usr)/lib -L$(nix_boot_usr)/lib64 $(LDFLAGS)" && \
	export CPPFLAGS="-I$(nix_boot_usr)/include $(CPPFLAGS)"  &&\
	export PERL5OPT="-I$(nix_boot_usr)/lib/perl" && \
	export NIXPKGS=$(NIXPKGS) && \
		./bootstrap.sh && ./myconfig.sh && make && make install; ) $(logit)
	touch $@

build: $(addprefix build/,$(addsuffix .x/.build,$(src)))
	@echo done $@

~/.nixpkgs/config.nix:
	mkdir -p ~/.nixpkgs
	cp etc/config.nix ~/.nixpkgs

build/.nixconfig: $(addprefix build/,$(addsuffix .x/.build,$(src))) build/.nixpkgs ~/.nixpkgs/config.nix
	env LD_LIBRARY_PATH="$(nix_boot_usr)/lib:$(nix_boot_usr)/lib64" \
		$(nix_boot_usr)/bin/nix-env -iA nixUnstable -f $(NIXPKGS)
	touch $@

build/.nixpkgs: $(addprefix build/,$(addsuffix .x/.build,$(src)))
	rm -rf $(NIXPKGS)
	git clone git@github.com:NixOS/nixpkgs.git $(NIXPKGS)
	cat etc/non-nix.patch | (cd $(NIXPKGS) && patch -p1 )
	touch $@

nixconfig: build/.nixconfig
	echo done $^

~/.nix-profile:
	ln -s $(nix_root)/var/nix/profiles/default ~/.nix-profile

nixprofile:
	rm -rf ~/.nix-profile
	ln -s $(nix_root)/var/nix/profiles/default ~/.nix-profile

static: ; mkdir -p $@

finish: ; rm -rf build usr logs

clean: ; rm -rf build logs

clobber:
	rm -rf build static src $(NIXPKGS) $(nix_boot_usr) nix logs
	-chmod -R 777 $(nix_root) && rm -rf $(nix_root)

link:
	ln -s etc/Makefile.nix Makefile

nix: build/.nixpkgs build/.nixconfig
	@echo done $^

