# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/ant-apache-bsf/ant-apache-bsf-1.7.1-r1.ebuild,v 1.5 2009/03/20 19:41:26 josejx Exp $

EAPI=2

ANT_TASK_DEPNAME="bsf-2.3"

inherit eutils ant-tasks

KEYWORDS="~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

# ant-nodeps contains <script> task which is needed for this
# although it's not a build dep through import
DEPEND=">=dev-java/bsf-2.4.0-r1:2.3[python?,javascript?,tcl?]"
RDEPEND="${DEPEND}
	~dev-java/ant-nodeps-${PV}"

IUSE="python javascript tcl"

JAVA_PKG_FILTER_COMPILER="jikes"

src_install() {
	ant-tasks_src_install
	java-pkg_register-dependency ant-nodeps
}

pkg_postinst() {
	elog "Also, >=dev-java/bsf-2.4.0-r1 adds optional support for groovy,"
	elog "ruby and beanshell. See its postinst elog messages for instructions."
}
