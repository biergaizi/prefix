# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-themes/gtk-engines/gtk-engines-2.14.0.ebuild,v 1.1 2008/03/17 01:37:30 leio Exp $

EAPI="prefix"

inherit gnome2 autotools

DESCRIPTION="GTK+2 standard engines and themes"
HOMEPAGE="http://www.gtk.org/"

LICENSE="GPL-2 LGPL-2.1"
SLOT="2"
KEYWORDS="~x86-freebsd ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="accessibility static"

RDEPEND=">=x11-libs/gtk+-2.12
	!<=x11-themes/gnome-themes-2.8.2"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.31
	>=dev-util/pkgconfig-0.9"

DOCS="AUTHORS ChangeLog NEWS README"

pkg_setup() {
	G2CONF="$(use_enable static) --enable-animation"
	use accessibility || G2CONF="${G2CONF} --disable-hc"
}

src_unpack() {
	gnome2_src_unpack
	eautoreconf # need new libtool for interix
}
