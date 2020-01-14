#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
configure=0
bootstrap=0
verbose=0
clean=0
scanbuild=""
bear="bear"
install=0
jobz=4
dir="frr"
extra_configure_switches=""
aflharden=0
llvmconfig=$(which llvm-config)

ulimit -v unlimited

mycc="clang"
mycflags="-g -O0"

while getopts "d:hobyvcij:taemfx:Zrsu" opt; do
	case "$opt" in
		h)
			echo "-h -- display help"
			echo "-o -- ./configure"
			echo "-b -- ./bootstrap.sh"
			echo "-s -- use scan-build"
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
			echo "-f -- build as fuzzing targets for AFL"
			echo "-Z -- build as fuzzing targets for libFuzzer"
			echo "-r -- build with LLVM coverage instrumentation"
			echo "-s -- use static linking"
			echo "-x -- extra arguments"
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
			extra_configure_switches+=" --enable-undefined-sanitizer -fno-sanitize-recover=all"
			;;
		e)
			bear="bear"
			;;
		f)
			mycc="afl-clang-fast"
			mycflags+="-g -O2 -funroll-loops -fsanitize-trap=all"
			aflharden=1
			;;
		Z)
			mycc="clang"
			extra_configure_switches+=" --enable-libfuzzer"
			mycflags+=" -g -O2 -funroll-loops"
			;;
		r)
			echo "Building with code coverage enabled"
			mycflags++=" -g -fprofile-instr-generate -fcoverage-mapping"
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
echo "extra_configure_switches: $extra_configure_switches"
cd $dir

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
		--includedir=\${prefix}/include \
		--mandir=\${prefix}/share/man \
		--infodir=\${prefix}/share/info \
		--sysconfdir=/etc/ \
		--libexecdir=\${prefix}/lib/frr \
		--enable-exampledir=/usr/share/doc/frr/examples/ \
		--localstatedir=/var/run/frr \
		--sbindir=/usr/lib/frr \
		--sysconfdir=/etc/frr \
		--enable-ospfclient=yes \
		--enable-ospfapi=yes \
		--enable-multipath=256 \
		--enable-user=frr \
		--enable-group=frr \
		--enable-vty-group=frrvty \
		--enable-configfile-mask=0640 \
		--enable-logfile-mask=0640 \
		--enable-systemd=no \
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
		$extra_configure_switches
		#--enable-snmp=agentx \
fi

if [ $clean -gt 0 ]; then
	make clean
fi

if [ $install -gt 0 ]; then
	$scanbuild $bear make -j $jobz
	# install
	systemctl stop frr
	rm -rf /var/log/frr/*
	rm -rf /var/support/*
	rm /usr/lib/frr/*
	make install
	systemctl reset-failed frr
fi
