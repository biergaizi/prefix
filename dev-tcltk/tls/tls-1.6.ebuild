# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-tcltk/tls/tls-1.6.ebuild,v 1.1 2009/04/26 16:29:27 mescalinum Exp $

inherit eutils multilib

MY_P="${PN}${PV}"
DESCRIPTION="TLS OpenSSL extension to Tcl."
HOMEPAGE="http://tls.sourceforge.net/"
SRC_URI="mirror://sourceforge/tls/${MY_P}-src.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="tk"

RESTRICT="test"

DEPEND=">=dev-lang/tcl-8.3.3
	dev-libs/openssl
	tk? ( >=dev-lang/tk-8.3.3 )"

S="${WORKDIR}/${MY_P}"

src_compile() {
	econf --with-ssl-dir="${EPREFIX}"/usr || die
	emake || die
}

src_install() {
	einstall libdir="${ED}/usr/$(get_libdir)" || die
	dodoc ChangeLog README.txt
	dohtml tls.htm

	if [[ ${CHOST} == *-darwin* ]] ; then
		# this is ugly, but fixing the makefile mess is even worse
		local loc=usr/$(get_libdir)/tls1.6/libtls1.6.dylib
		install_name_tool -id "${EPREFIX}"/${loc} "${ED}"/${loc} || die
	fi
}
