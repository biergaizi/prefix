# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/ant-apache-bsf/ant-apache-bsf-1.7.1.ebuild,v 1.6 2008/12/21 13:38:28 maekke Exp $

EAPI=1

ANT_TASK_DEPNAME="bsf-2.3"

inherit eutils ant-tasks

KEYWORDS="~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

# ant-nodeps contains <script> task which is needed for this
# although it's not a build dep through import
DEPEND=">=dev-java/bsf-2.4.0-r1:2.3"
RDEPEND="${DEPEND}
	~dev-java/ant-nodeps-${PV}"

JAVA_PKG_FILTER_COMPILER="jikes"

src_install() {
	ant-tasks_src_install
	java-pkg_register-dependency ant-nodeps
}

built_with_use_warn() {
	if ! built_with_use --missing false -o dev-java/bsf ${1}; then
		elog "If you want to use ${2} in <script> tasks in build.xml files,"
		elog "dev-java/bsf must be installed with \"${3-${1}}\" USE flag"
	fi
}

pkg_postinst() {
	built_with_use_warn python Python
	built_with_use_warn javascript JavaScript
	built_with_use_warn tcl TCL
	elog "Also, >=dev-java/bsf-2.4.0-r1 adds optional support for groovy,"
	elog "ruby and beanshell. See its postinst elog messages for instructions."
}
