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

ulimit -v unlimited

mycc="clang"
mycflags="-g -O3"

while getopts "d:hobsvcij:taemfx:" opt; do
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
			echo "-a -- enable address sanitizer"
			echo "-t -- enable thread sanitizer"
			echo "-m -- enable memory sanitizer"
			echo "-u -- enable undefined behavior sanitizer"
			echo "-e -- generate compile_commands.json with Bear"
			echo "-x -- extra arguments"
			echo "-f -- use afl-clang-fast"
			exit
			;;
		o)
			configure=1
			;;
		b)
			bootstrap=1
			;;
		s)
			scanbuild="scan-build-7"
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
			extra_configure_switches+=" --enable-undefined-sanitizer"
			;;
		e)
			bear="bear"
			;;
		f)
			mycc="afl-clang-fast"
			mycflags="-g -O2 -funroll-loops -fno-sanitize-recover=all -fsanitize-trap=all"
			extra_configure_switches+=" --enable-undefined-sanitizer"
			aflharden=1
			LLVM_CONFIG=$(which llvm-config-9)
			;;
		x)
			mycflags+=" $OPTARG"
			;;
	esac
done

echo "CFLAGS: $mycflags"
echo "LSAN_OPTIONS: $LSAN_OPTIONS"
echo "AFL_HARDEN: $aflharden"
echo "LLVM_CONFIG: $LLVM_CONFIG"
cd $dir

if [ $bootstrap -gt 0 ]; then
	./bootstrap.sh
fi

if [ $configure -gt 0 ]; then
	export CC="$mycc"
	export CFLAGS="$mycflags"
	export AFL_HARDEN=$aflharden
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
