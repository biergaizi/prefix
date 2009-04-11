# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/most/most-5.0.0a.ebuild,v 1.10 2008/09/25 11:58:05 aballier Exp $

DESCRIPTION="a paging program that displays, one windowful at a time, the contents of a file."
HOMEPAGE="ftp://space.mit.edu/pub/davis/most"
SRC_URI="ftp://space.mit.edu/pub/davis/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE=""

RDEPEND=">=sys-libs/slang-2.1.3"
DEPEND="${RDEPEND}"

src_unpack() {
	unpack ${A}
	sed -i -e 's:$(INSTALL) -s:$(INSTALL):' "${S}"/src/Makefile.in
}

src_compile() {
	unset ARCH
	econf
	emake || die "emake failed."
}

src_install() {
	emake DESTDIR="${D}" DOC_DIR="${EPREFIX}/usr/share/doc/${PF}" \
		install || die "emake install failed."
	prepalldocs
}
