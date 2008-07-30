# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/man-pages/man-pages-3.01.ebuild,v 1.2 2008/07/29 12:57:33 flameeyes Exp $

EAPI="prefix"

DESCRIPTION="A somewhat comprehensive collection of Linux man pages"
HOMEPAGE="http://www.win.tue.nl/~aeb/linux/man/"
SRC_URI="mirror://kernel/linux/docs/manpages/Archive/${P}.tar.bz2"

LICENSE="freedist"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux"
IUSE="nls linguas_cs linguas_da linguas_de linguas_es linguas_fr linguas_it
	linguas_ja linguas_nl linguas_pl linguas_ro linguas_ru linguas_zh_CN"
RESTRICT="binchecks"

RDEPEND="virtual/man"
PDEPEND="nls? (
	linguas_cs? ( app-i18n/man-pages-cs )
	linguas_da? ( app-i18n/man-pages-da )
	linguas_de? ( app-i18n/man-pages-de )
	linguas_es? ( app-i18n/man-pages-es )
	linguas_fr? ( app-i18n/man-pages-fr )
	linguas_it? ( app-i18n/man-pages-it )
	linguas_ja? ( app-i18n/man-pages-ja )
	linguas_nl? ( app-i18n/man-pages-nl )
	linguas_pl? ( app-i18n/man-pages-pl )
	linguas_ro? ( app-i18n/man-pages-ro )
	linguas_ru? ( app-i18n/man-pages-ru )
	linguas_zh_CN? ( app-i18n/man-pages-zh_CN )
	)
	sys-apps/man-pages-posix"

src_compile() { :; }

src_install() {
	emake install prefix="${EPREFIX}/usr" DESTDIR="${D}" || die
	dodoc man-pages-*.Announce README Changes*
}

pkg_postinst() {
	einfo "If you don't have a makewhatis cronjob, then you"
	einfo "should update the whatis database yourself:"
	einfo " # makewhatis -u"
}
