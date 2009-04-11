# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lisp/sbcl/sbcl-1.0.15.ebuild,v 1.3 2008/11/16 16:31:39 flameeyes Exp $

inherit eutils flag-o-matic

#same order as http://www.sbcl.org/platform-table.html
BV_X86=1.0.12
BV_AMD64=1.0.12
BV_PPC=1.0
BV_SPARC=0.9.17
BV_ALPHA=0.9.12
BV_MIPS=1.0.12
BV_MIPSEL=1.0.12

BV_PPC_MACOS=0.9.15
BV_X86_MACOS=0.9.16
BV_X86_SOLARIS=0.9.14


DESCRIPTION="Steel Bank Common Lisp (SBCL) is an implementation of ANSI Common Lisp."
HOMEPAGE="http://sbcl.sourceforge.net/"
SRC_URI="mirror://sourceforge/sbcl/${P}-source.tar.bz2
	x86? ( mirror://sourceforge/sbcl/${PN}-${BV_X86}-x86-linux-binary.tar.bz2 )
	amd64? ( mirror://sourceforge/sbcl/${PN}-${BV_AMD64}-x86-64-linux-binary.tar.bz2 )
	ppc? ( mirror://sourceforge/sbcl/${PN}-${BV_PPC}-powerpc-linux-binary.tar.bz2 )
	sparc? ( mirror://sourceforge/sbcl/${PN}-${BV_SPARC}-sparc-linux-binary.tar.bz2 )
	alpha? ( mirror://sourceforge/sbcl/${PN}-${BV_ALPHA}-alpha-linux-binary.tar.bz2 )
	mips? ( !cobalt? ( mirror://sourceforge/sbcl/${PN}-${BV_MIPS}-mips-linux-binary.tar.bz2 ) )
	mips? ( cobalt? ( mirror://sourceforge/sbcl/${PN}-${BV_MIPSEL}-mipsel-linux-binary.tar.bz2 ) )
	ppc-macos? ( mirror://sourceforge/sbcl/${PN}-${BV_PPC_MACOS}-powerpc-darwin-binary.tar.bz2 )
	x86-macos? ( mirror://sourceforge/sbcl/${PN}-${BV_X86_MACOS}-x86-darwin-binary.tar.bz2 )
	x86-solaris? ( mirror://sourceforge/sbcl/${PN}-${BV_X86_SOLARIS}-x86-solaris-binary.tar.gz )"

# SRC_URI is part of the metadata cache; it's evaluated contents must be independent of the system that creates the metadata cache.
# ILLEGAL: mips? ( mirror://sourceforge/sbcl/${PN}-${BV_MIPS}-$([[$(tc-endian) = big]] && echo mips || echo mipsel)-linux-binary.tar.bz2 )

LICENSE="MIT"
SLOT="0"

KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"

IUSE="ldb source threads unicode doc cobalt"

DEPEND="doc? ( sys-apps/texinfo media-gfx/graphviz )"

PDEPEND="dev-lisp/gentoo-init"

PROVIDE="virtual/commonlisp"

pkg_setup() {
	if has_version sys-devel/gcc && built_with_use sys-devel/gcc hardened && gcc-config -c | grep -qv vanilla; then
		eerror "So-called \"hardened\" compiler features are incompatible with SBCL. You"
		eerror "must use gcc-config to select a profile with non-hardened features"
		eerror "(the \"vanilla\" profile) and \"source /etc/profile\" before continuing."
		die
	fi
	if use !prefix && (use x86 || use amd64) && has_version "<sys-libs/glibc-2.6" \
		&& ! built_with_use sys-libs/glibc nptl; then
		eerror "Building SBCL without NPTL support on at least x86 and amd64"
		eerror "architectures is not a supported configuration in Gentoo.  Please"
		eerror "refer to Bug #119016 for more information."
		die
	fi
}

CONFIG="${S}/customize-target-features.lisp"
ENVD="${T}/50sbcl"

usep() {
	use ${1} && echo "true" || echo "false"
}

sbcl_feature() {
	echo "$( [[ $1 == "true" ]] && echo "(enable $2)" || echo "(disable $2)")" >> "${CONFIG}"
#	if [[ $1 == "true" ]];  then echo "(enable $2)"  >> "${CONFIG}"; fi
#	if [[ $1 == "false" ]]; then echo "(disable $2)" >> "${CONFIG}"; fi
}

sbcl_apply_features() {
	cat > "${CONFIG}" <<'EOF'
(lambda (list)
  (flet ((enable  (x) (pushnew x list))
		 (disable (x) (setf list (remove x list))))
EOF
	if use x86 || use amd64; then
		sbcl_feature "$(usep threads)" ":sb-thread"
	fi
	sbcl_feature "$(usep ldb)" ":sb-ldb"
	sbcl_feature "false" ":sb-test"
	sbcl_feature "$(usep unicode)" ":sb-unicode"
	cat >> "${CONFIG}" <<'EOF'
	)
  list)
EOF
	cat "${CONFIG}"
}

src_unpack() {
	unpack ${A}
	mv sbcl-*-* sbcl-binary
	cd "${S}"

	epatch "${FILESDIR}"/${PN}-1.0.6-solaris.patch
	epatch "${FILESDIR}"/${PN}-version-asm.patch #216871
#	epatch "${FILESDIR}/disable-tests-gentoo-${PV}.patch"
	use source && sed 's%"$(build_root)%$(module).lisp "$(build_root)%' -i contrib/vanilla-module.mk

	sed "s,/lib,/$(get_libdir),g" -i "${S}/install.sh"
	sed  "s,/usr/local/lib,${EPREFIX}/usr/$(get_libdir),g" -i "${S}/src/runtime/runtime.c" # #define SBCL_HOME ...
	sed  "s,/etc/sbclrc,${EPREFIX}/etc/sbclrc,g" -i "${S}/src/code/toplevel.lisp" # change location of /etc/sbclrc ...

	# customizing SBCL version as per
	# http://sbcl.cvs.sourceforge.net/sbcl/sbcl/doc/PACKAGING-SBCL.txt?view=markup
	echo -e ";;; Auto-generated by Gentoo\n\"${PVR}-gentoo\"" > "${S}/version.lisp-expr"

	# applying customizations
	sbcl_apply_features

	find "${S}" -type f -name .cvsignore -print0 | xargs -0 rm -f
	find "${S}" -depth -type d -name CVS -or -name .git -print0 | xargs -0 rm -rf
	find "${S}" -type f -name \*.c -print0 | xargs -0 chmod 644
}

src_compile() {
	local bindir="${WORKDIR}"/sbcl-binary

	[[ $(ld --version 2>&1 | head -n1) == *GNU* ]] && \
	append-ldflags -Wl,--no-as-needed # see Bug #132992

	# clear the environment to get rid of non-ASCII strings, see bug 174702
	# set HOME for paludis
	env - HOME="${T}" \
		PATH="${bindir}/src/runtime:${PATH}" SBCL_HOME="${bindir}/output" GNUMAKE=make ./make.sh \
		"sbcl --sysinit /dev/null --userinit /dev/null	--disable-debugger --core ${bindir}/output/sbcl.core" \
		|| die "make failed"

	# need to set HOME because libpango(used by graphviz) complains about it
	if use doc; then
		env - HOME="${T}" make -C doc/manual info html || die "Cannot build manual"
		env - HOME="${T}" make -C doc/internals html || die "Cannot build internal docs"
	fi
}

src_test() {
#	FILES="exhaust.impure.lisp"
	cd tests
	sh run-tests.sh
#	sh run-tests.sh ${FILES}
#	sh run-tests.sh --break-on-failure ${FILES}
}

src_install() {
	# install system-wide initfile
	dodir /etc/
	cat > "${ED}"/etc/sbclrc <<EOF
;;; The following is required if you want source location functions to
;;; work in SLIME, for example.

(setf (logical-pathname-translations "SYS")
	'(("SYS:SRC;**;*.*.*" #p"${EPREFIX}/usr/$(get_libdir)/sbcl/src/**/*.*")
	  ("SYS:CONTRIB;**;*.*.*" #p"${EPREFIX}/usr/$(get_libdir)/sbcl/**/*.*")))

;;; Setup ASDF
(load "${EPREFIX}/etc/gentoo-init.lisp")
EOF

	# Install documentation
	dodir /usr/share/man
	dodir /usr/share/doc/${PF}
	unset SBCL_HOME
	INSTALL_ROOT="${ED}"/usr DOC_DIR="${ED}"/usr/share/doc/${PF} sh install.sh || die "install.sh failed"

	doman doc/sbcl-asdf-install.1

	dodoc BUGS CREDITS INSTALL NEWS OPTIMIZATIONS PRINCIPLES README STYLE SUPPORT TLA TODO

	if use doc; then
		dohtml doc/html/*
		doinfo "${S}"/doc/manual/*.info*
		dohtml -r "${S}"/doc/internals/sbcl-internals
	fi

	# install the SBCL source
	if use source; then
		cp -pPR "${S}"/src "${ED}/usr/$(get_libdir)"/sbcl
		find "${ED}/usr/$(get_libdir)/sbcl/src" -type f -name '*.fasl' -print0 | xargs -0 rm -f
	fi

	# necessary for running newly-saved images
	echo "SBCL_HOME=${EPREFIX}/usr/$(get_libdir)/${PN}" > "${ENVD}"
	echo "SBCL_SOURCE_ROOT=${EPREFIX}/usr/$(get_libdir)/${PN}/src" >> "${ENVD}"
	doenvd "${ENVD}"

#	impl-save-timestamp-hack sbcl
}

pkg_postinst() {
	sleep 1
	find "${EPREFIX}"/usr/$(get_libdir)/sbcl/ -type f -name '*.fasl' -exec touch -m {} ';'
#	standard-impl-postinst sbcl
}

# pkg_postrm() {
# 	standard-impl-postrm sbcl /usr/bin/sbcl
# }
