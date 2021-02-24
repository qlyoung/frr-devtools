#!/bin/bash
# Copyright (c) Quentin Young 2017-2020
#
# High level configuration & build script for FRR.
# Wraps common options, developer tools, config switches etc.
#
# Examples:
#
# Typical build:
#    ./install-frr.sh -boid frr
#
# ASAN build:
#    ./install-frr.sh -boiad frr
#
# ASAN, UBSAN and libFuzzer build:
#    ./install-frr.sh -boiauZd frr
#
# gcov build:
#    ./install-frr.sh -boigd frr
#
# ASAN, UBSAN, TSAN, clang coverage, statically linked AFL build:
#    ./install-frr.sh -boiautrsd frr


# Reset in case getopts has been used previously in the shell.
OPTIND=1

# Initialize our own variables:
configure=0
bootstrap=0
verbose=0
clean=0
scanbuild=""
bear=""
install=0
jobz=4
dir="frr"
extra_configure_switches=""
aflharden=0
llvmconfig=$(which llvm-config)

ulimit -v unlimited

mycc="gcc"
mycflags="-g3 -O0"

while getopts "hobyvcij:d:eatmuFZrgsx:" opt; do
	case "$opt" in
		h)
			echo "-h -- display help"
			echo "-o -- ./configure"
			echo "-b -- ./bootstrap.sh"
			echo "-y -- use scan-build"
			echo "-v -- verbose"
			echo "-c -- make clean"
			echo "-i -- clean install"
			echo "-j -- # jobs for make"
			echo "-d -- project directory"
			echo "-e -- generate compile_commands.json with Bear"
			echo "-a -- enable address sanitizer"
			echo "-t -- enable thread sanitizer"
			echo "-m -- enable memory sanitizer"
			echo "-u -- enable undefined behavior sanitizer"
			echo "-F -- build as fuzzing targets for AFL"
			echo "-Z -- build as fuzzing targets for libFuzzer"
			echo "-r -- build with LLVM coverage instrumentation"
			echo "-g -- build with gcov coverage instrumentation"
			echo "-s -- use static linking"
			echo "-x -- add to CFLAGS"
			exit
			;;
		o)
			configure=1
			;;
		b)
			bootstrap=1
			;;
		y)
			scanbuild="scan-build"
			;;
		v)
			verbose=1
			;;
		c)
			clean=1
			;;
		i)
			install=1
			;;
		j)
			jobz=$OPTARG
			;;
		d)
			dir=$OPTARG
			;;
		e)
			bear="bear"
			;;
		a)
			extra_configure_switches+=" --enable-address-sanitizer"
			;;
		t)
			extra_configure_switches+=" --enable-thread-sanitizer"
			;;
		m)
			extra_configure_switches+=" --enable-memory-sanitizer"
			;;
		u)
			mycflags+=" -fno-sanitize-recover=all -fsanitize=unsigned-integer-overflow,implicit-conversion,nullability-arg,nullability-assign,nullability-return"
			extra_configure_switches+=" --enable-undefined-sanitizer"
			;;
		F)
			mycc="afl-clang-fast"
			mycflags+=" -Wno-all -g3 -O3 -funroll-loops -fsanitize-trap=all"
			aflharden=1
			;;
		Z)
			mycc="clang"
			extra_configure_switches+=" --enable-libfuzzer"
			mycflags+=" -Wno-all -g3 -O3 -funroll-loops"
			;;
		r)
			echo "Building with ClangCoverage enabled"
			mycflags+=" -g3"
			extra_configure_switches+=" --enable-clang-coverage"
			;;
		g)
			echo "Building with gcov enabled"
			extra_configure_switches+=" --enable-gcov"
			;;
		s)
			extra_configure_switches+=" --enable-shared --enable-static --enable-static-bin"
			;;
		x)
			mycflags+=" $OPTARG"
			;;
	esac
done

echo "CFLAGS: $mycflags"
echo "CC: $mycc"
echo "AFL_HARDEN: $aflharden"
echo "LLVM_CONFIG: $llvmconfig"
echo "Extra configure options: $extra_configure_switches"
cd "$dir" || (printf "No such directory '%s'" "$dir"; exit 1)

if [ $bootstrap -gt 0 ]; then
	./bootstrap.sh
fi

if [ $configure -gt 0 ]; then
	export CC="$mycc"
	export CFLAGS="$mycflags"
	export AFL_HARDEN=$aflharden
	export LLVM_CONFIG=$llvmconfig
	$scanbuild ./configure \
		--build=x86_64-linux-gnu \
		--prefix=/usr \
		--includedir="\${prefix}/include" \
		--mandir="\${prefix}/share/man" \
		--infodir="\${prefix}/share/info" \
		--libexecdir="\${prefix}/lib/frr" \
		--enable-exampledir="\${prefix}/share/doc/frr/examples/" \
		--sbindir="\${prefix}/lib/frr" \
		--sysconfdir=/etc/ \
		--localstatedir=/var/run/frr \
		--sysconfdir=/etc/frr \
		--enable-ospfclient=yes \
		--enable-ospfapi=yes \
		--enable-multipath=256 \
		--enable-user=frr \
		--enable-group=frr \
		--enable-vty-group=frrvty \
		--enable-configfile-mask=0640 \
		--enable-logfile-mask=0640 \
		--enable-systemd=yes \
		--enable-vtysh=yes \
		--enable-pimd=yes \
		--enable-bgp-vnc=no \
		--enable-ldpd=yes \
		--enable-cumulus=yes \
		--enable-pbrd=yes \
		--enable-dev-build=yes \
		--enable-nhrpd=no \
		--enable-sharpd=yes \
		--with-pkg-extra-version="" \
		--enable-rpki=no \
		--enable-werror=yes \
		--enable-doc=yes \
		--enable-doc-html=yes \
		--enable-static=yes \
		--enable-grpc=yes \
		--enable-lttng=yes \
		$extra_configure_switches
		#--enable-snmp=agentx \
fi

if [ $clean -gt 0 ]; then
	make clean
fi

if [ $install -gt 0 ]; then
	$scanbuild $bear make V=$verbose -j "$jobz"
	# install
	systemctl stop frr
	rm -rf /var/log/frr/*
	rm -rf /var/support/*
	rm /usr/lib/frr/*
	make V=$verbose install
	systemctl reset-failed frr
fi
exit 0
