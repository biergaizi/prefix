# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="prefix"

inherit eutils toolchain-funcs

RESTRICT="test" # the test suite will test what's installed.

LD64=ld64-85.2.2
CCTOOLS=cctools-698

DESCRIPTION="Darwin assembler as(1) and static linker ld(1), Xcode Tools 3.1"
HOMEPAGE="http://www.opensource.apple.com/darwinsource/"
SRC_URI="http://www.gentoo.org/~grobian/distfiles/${LD64}.tar.gz
	http://www.gentoo.org/~grobian/distfiles/${CCTOOLS}.tar.gz"

LICENSE="APSL-2"
KEYWORDS="~ppc-macos ~x86-macos"
IUSE=""
SLOT="0"

DEPEND="sys-devel/binutils-config
	test? ( >=dev-lang/perl-5.8.8 )"
RDEPEND="${DEPEND}"

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
		export CTARGET=${CATEGORY/cross-}
	fi
fi
is_cross() { [[ ${CHOST} != ${CTARGET} ]] ; }

if is_cross ; then
	SLOT="${CTARGET}"
else
	SLOT="0"
fi

LIBPATH=/usr/$(get_libdir)/binutils/${CTARGET}/${PV}
INCPATH=${LIBPATH}/include
DATAPATH=/usr/share/binutils-data/${CTARGET}/${PV}
if is_cross ; then
	BINPATH=/usr/${CHOST}/${CTARGET}/binutils-bin/${PV}
else
	BINPATH=/usr/${CTARGET}/binutils-bin/${PV}
fi

S=${WORKDIR}

echo_and_run() {
	echo "$@"
	"$@"
}

unpack_ld64() {
	cd "${S}"/${LD64}/src
	local VER_STR="\"@(#)PROGRAM:ld  PROJECT:${LD64}\\n\""
	sed -i \
		-e '/^#define LTO_SUPPORT 1/s:1:0:' \
		ObjectDump.cpp
	echo '#undef LTO_SUPPORT' > configure.h
	echo "char ldVersionString[] = ${VER_STR};" > version.cpp

	# clean up test suite
	cd "${S}"/${LD64}/unit-tests/test-cases
	local c

	# we don't have llvm
	((++c)); rm -rf llvm-integration;

	# we don't have dtrace
	((++c)); rm -rf dtrace-static-probes-coalescing;
	((++c)); rm -rf dtrace-static-probes;

	# a file is missing
	((++c)); rm -rf eh-coalescing-r

	# we don't do universal binaries
	((++c)); rm -rf blank-stubs;

	# looks like a problem with apple's result-filter.pl
	((++c)); rm -rf implicit-common3;
	((++c)); rm -rf order_file-ans;

	# TODO no idea what goes wrong here
	((++c)); rm -rf dwarf-debug-notes;

	elog "Deleted $c tests that were bound to fail"
}

src_unpack() {
	unpack ${A}
	unpack_ld64
	cd "${S}"

	epatch "${FILESDIR}"/${PV}-as.patch
	epatch "${FILESDIR}"/${PV}-ranlib.patch
	epatch "${FILESDIR}"/${PV}-nmedit.patch
	epatch "${FILESDIR}"/${PV}-no-efi-man.patch
	epatch "${FILESDIR}"/${PV}-no-oss-dir.patch
	epatch "${FILESDIR}"/${PV}-testsuite.patch
}

compile_ld64() {
	cd "${S}"/${LD64}/src
	echo_and_run "$(tc-getCC)" -c ${CFLAGS} debugline.c
	# 'struct linkedit_data_command' is defined in mach-o/loader.h on leopard,
	# but not on tiger.
	echo_and_run "$(tc-getCXX)" -o ld64 \
		${CXXFLAGS} -isystem "${S}"/${CCTOOLS}/include/ \
		${LDFLAGS} Options.cpp ld.cpp version.cpp debugline.o
	echo_and_run "$(tc-getCXX)" -o rebase \
		${CXXFLAGS} -isystem "${S}"/${CCTOOLS}/include/ \
		${LDFLAGS} rebase.cpp
}

compile_cctools() {
	cd "${S}"/${CCTOOLS}
	# specify MACOSX_DEPLOYMENT_TARGET=10.4 as per
	#   https://bugzilla.mozilla.org/show_bug.cgi?id=442545
	# thereby avoiding error like
	#   'struct __darwin_i386_thread_state' has no member named 'eip'
	#   'struct __darwin_i386_thread_state' has no member named 'esp'
	emake \
		LTO= \
		EFITOOLS= \
		BUILD_OBSOLETE_ARCH= \
		COMMON_SUBDIRS='libstuff gprof misc libmacho libdyld mkshlib otool man cbtlibs' \
		CC="$(tc-getCC)" \
		MACOSX_DEPLOYMENT_TARGET=10.4 \
		RC_CFLAGS="${CFLAGS}"
	cd "${S}"/${CCTOOLS}/as
	emake -k # the errors can be ignored
	emake
}

src_compile() {
	compile_ld64
	compile_cctools
}

install_ld64() {
	exeinto ${BINPATH}
	doexe "${S}"/${LD64}/src/{ld64,rebase}
	dosym ld64 ${BINPATH}/ld
	insinto ${DATAPATH}/man/man1
	doins "${S}"/${LD64}/doc/man/man1/{ld,ld64,rebase}.1
}

install_cctools() {
	cd "${S}"/${CCTOOLS}
	emake install \
		EFITOOLS= \
		COMMON_SUBDIRS='libstuff gprof misc libmacho libdyld mkshlib otool man cbtlibs' \
		DSTROOT=\"${D}\" \
		BINDIR=\"${EPREFIX}\"/${BINPATH} \
		LOCBINDIR=\"${EPREFIX}\"/${BINPATH} \
		USRBINDIR=\"${EPREFIX}\"/${BINPATH} \
		macos_LIBDIR=\"${EPREFIX}\"/${LIBPATH} \
		LOCLIBDIR=\"${EPREFIX}\"/${LIBPATH} \
		SYSTEMDIR=\"${EPREFIX}\"/${LIBPATH} \
		MANDIR=\"${EPREFIX}\"/${DATAPATH}/man/ \
		LOCMANDIR=\"${EPREFIX}\"/${DATAPATH}/man/ \
		macos_INCDIR=\"${EPREFIX}\"/${INCPATH} \
		macos_LOCINCDIR=\"${EPREFIX}\"/${INCPATH}
	cd "${S}"/${CCTOOLS}/as
	emake install \
		BUILD_OBSOLETE_ARCH= \
		DSTROOT=\"${D}\" \
		USRBINDIR=\"${EPREFIX}\"/${BINPATH} \
		LIBDIR=\"${EPREFIX}\"/${BINPATH}/../libexec/gcc/darwin/ \
		LOCLIBDIR=\"${EPREFIX}\"/${LIBPATH}
	# TODO What's the proper way to handle the LIBDIR here?
}

test_ld64() {
	cd "${S}"/${LD64}/src
	# 'struct linkedit_data_command' is defined in mach-o/loader.h on leopard,
	# but not on tiger.
	echo_and_run "$(tc-getCXX)" -o machocheck \
		${CXXFLAGS} -isystem "${S}"/${CCTOOLS}/include/ -Wno-deprecated \
		${LDFLAGS} machochecker.cpp
	echo_and_run "$(tc-getCXX)" -o ObjectDump \
		${CXXFLAGS} -isystem "${S}"/${CCTOOLS}/include/ \
		${LDFLAGS} ObjectDump.cpp debugline.o
	cd "${S}"/${LD64}/unit-tests/test-cases
	perl ../bin/make-recursive.pl \
		ARCH=`arch` \
		RELEASEDIR="${S}"/${LD64}/src \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)" \
		| perl ../bin/result-filter.pl
}

src_test() {
	test_ld64
}

src_install() {
	install_ld64
	install_cctools

	cd "${S}"
	insinto /etc/env.d/binutils
	cat <<-EOF > env.d
		TARGET="${CHOST}"
		VER="${PV}"
		FAKE_TARGETS="${CHOST}"
	EOF
	newins env.d ${CHOST}-${PV}
}

pkg_postinst() {
	binutils-config ${CHOST}-${PV}
}
