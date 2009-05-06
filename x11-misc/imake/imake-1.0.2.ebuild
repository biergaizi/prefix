# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-misc/imake/imake-1.0.2.ebuild,v 1.12 2009/05/05 17:34:08 ssuominen Exp $

# Must be before x-modular eclass is inherited
#SNAPSHOT="yes"

inherit x-modular

DESCRIPTION="C preprocessor interface to the make utility"
KEYWORDS="~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="x11-misc/xorg-cf-files
	!x11-misc/xmkmf"
DEPEND="${RDEPEND}
	x11-proto/xproto"

src_unpack() {
	unpack ${A}
	cd "${S}"
	# don't use Sun compilers on Solaris, we want GCC from prefix
	sed -i -e "1s/^.*$/#if defined(sun)\n# undef sun\n#endif/" \
		imake.c imakemdep.h
}
