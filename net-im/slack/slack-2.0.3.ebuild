EAPI=5
inherit unpacker

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="https://slack-ssb-updates.global.ssl.fastly.net/linux_releases/slack-desktop-${PV}-amd64.deb"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_install() {
    insinto /
    doins -r usr
    fperms +x /usr/lib/slack/slack
}
