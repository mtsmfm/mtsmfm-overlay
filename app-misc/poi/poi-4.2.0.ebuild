# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="Scalable KanColle browser and tool"
HOMEPAGE="https://github.com/poooi/poi"
SRC_URI="https://github.com/poooi/poi/releases/download/v${PV}/poi-v${PV}-linux-x64.7z"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="app-arch/p7zip"
RDEPEND=""
S="${WORKDIR}/poi-v${PV}-linux-x64"

src_install() {
	insinto /usr/share/poi
	doins -r .
	fperms +x /usr/share/poi/poi

	insinto /usr/share/applications
	doins ${FILESDIR}/poi.desktop

	insinto /usr/share/pixmaps
	newins resources/app/assets/icons/icon.png poi.png
}
