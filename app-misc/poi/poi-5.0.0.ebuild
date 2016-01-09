# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="Scalable KanColle browser and tool"
HOMEPAGE="https://github.com/poooi/poi"

MY_PV="${PV/_p/.}"
MY_PV="${MY_PV/_/-}"

SRC_URI="https://github.com/poooi/poi/releases/download/v${MY_PV}/poi-v${PV/_*}-linux-x64.7z -> ${P}.7z"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="app-arch/p7zip"
RDEPEND=""
S="${WORKDIR}/poi-v${PV/_*}-linux-x64"

src_unpack() {
	local icon="https://github.com/poooi/poi/raw/v${MY_PV}/assets/icons/poi.png"
	unpack ${A}
	wget ${icon} -P ${S} || die
}

src_install() {
	insinto /usr/share/poi
	doins -r .
	fperms +x /usr/share/poi/poi

	insinto /usr/share/applications
	doins ${FILESDIR}/poi.desktop

	insinto /usr/share/pixmaps
	doins poi.png
}
