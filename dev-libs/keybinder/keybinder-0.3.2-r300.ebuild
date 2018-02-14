# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils

MY_P=${PN}-3.0-${PV}

DESCRIPTION="A library for registering global keyboard shortcuts"
HOMEPAGE="https://github.com/engla/keybinder"
SRC_URI="https://github.com/engla/keybinder/releases/download/${PN}-3.0-v${PV}/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="3"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~x86"
IUSE="+introspection"

RDEPEND="x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXrender
	introspection? ( dev-libs/gobject-introspection )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS="AUTHORS NEWS README"

S=${WORKDIR}/${MY_P}

src_configure() {
	econf \
		$(use_enable introspection)
}

src_install() {
	default
	prune_libtool_files --all
}

pkg_preinst() {
	# remove old symlink as otherwise the files will be installed
	# in the wrong directory
	if [[ -h ${EROOT%/}/usr/share/gtk-doc/html/keybinder-3.0 ]]; then
		rm "${EROOT%/}/usr/share/gtk-doc/html/keybinder-3.0" || die
	fi
}
