# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

EGO_PN="github.com/docker/docker"

SRC_URI="
	https://get.docker.com/builds/Linux/x86_64/docker-${PV}-ce.tgz
	https://github.com/docker/docker/archive/v${PV}-ce.tar.gz
"

KEYWORDS="~amd64"
inherit bash-completion-r1 linux-info systemd udev user

DESCRIPTION="The core functions you need to create Docker images and run Docker containers"
HOMEPAGE="https://dockerproject.org"
LICENSE="Apache-2.0"
SLOT="0"
IUSE="apparmor aufs btrfs +device-mapper experimental hardened overlay seccomp"

DEPEND=""

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#runtime-dependencies
# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#optional-dependencies
RDEPEND="
	!app-emulation/docker
	>=net-firewall/iptables-1.4
	sys-process/procps
	>=dev-vcs/git-1.7
	>=app-arch/xz-utils-4.9
"

RESTRICT="installsources strip"

S="${WORKDIR}"

# see "contrib/check-config.sh" from upstream's sources
CONFIG_CHECK="
	~NAMESPACES ~NET_NS ~PID_NS ~IPC_NS ~UTS_NS
	~CGROUPS ~CGROUP_CPUACCT ~CGROUP_DEVICE ~CGROUP_FREEZER ~CGROUP_SCHED ~CPUSETS ~MEMCG
	~KEYS
	~VETH ~BRIDGE ~BRIDGE_NETFILTER
	~NF_NAT_IPV4 ~IP_NF_FILTER ~IP_NF_TARGET_MASQUERADE
	~NETFILTER_XT_MATCH_ADDRTYPE ~NETFILTER_XT_MATCH_CONNTRACK
	~NF_NAT ~NF_NAT_NEEDED
	~POSIX_MQUEUE

	~USER_NS
	~SECCOMP
	~CGROUP_PIDS
	~MEMCG_SWAP ~MEMCG_SWAP_ENABLED

	~BLK_CGROUP ~BLK_DEV_THROTTLING ~IOSCHED_CFQ ~CFQ_GROUP_IOSCHED
	~CGROUP_PERF
	~CGROUP_HUGETLB
	~NET_CLS_CGROUP
	~CFS_BANDWIDTH ~FAIR_GROUP_SCHED ~RT_GROUP_SCHED
	~IP_VS ~IP_VS_PROTO_TCP ~IP_VS_PROTO_UDP ~IP_VS_NFCT

	~VXLAN
	~XFRM_ALGO ~XFRM_USER
	~IPVLAN
	~MACVLAN ~DUMMY
"

ERROR_KEYS="CONFIG_KEYS: is mandatory"
ERROR_MEMCG_SWAP="CONFIG_MEMCG_SWAP: is required if you wish to limit swap usage of containers"
ERROR_RESOURCE_COUNTERS="CONFIG_RESOURCE_COUNTERS: is optional for container statistics gathering"

ERROR_BLK_CGROUP="CONFIG_BLK_CGROUP: is optional for container statistics gathering"
ERROR_IOSCHED_CFQ="CONFIG_IOSCHED_CFQ: is optional for container statistics gathering"
ERROR_CGROUP_PERF="CONFIG_CGROUP_PERF: is optional for container statistics gathering"
ERROR_CFS_BANDWIDTH="CONFIG_CFS_BANDWIDTH: is optional for container statistics gathering"
ERROR_XFRM_ALGO="CONFIG_XFRM_ALGO: is optional for secure networks"
ERROR_XFRM_USER="CONFIG_XFRM_USER: is optional for secure networks"

pkg_setup() {
	if kernel_is lt 3 10; then
		ewarn ""
		ewarn "Using Docker with kernels older than 3.10 is unstable and unsupported."
		ewarn " - http://docs.docker.com/engine/installation/binaries/#check-kernel-dependencies"
	fi

	# for where these kernel versions come from, see:
	# https://www.google.com/search?q=945b2b2d259d1a4364a2799e80e8ff32f8c6ee6f+site%3Akernel.org%2Fpub%2Flinux%2Fkernel+file%3AChangeLog*
	if ! {
		kernel_is ge 3 16 \
		|| { kernel_is 3 15 && kernel_is ge 3 15 5; } \
		|| { kernel_is 3 14 && kernel_is ge 3 14 12; } \
		|| { kernel_is 3 12 && kernel_is ge 3 12 25; }
	}; then
		ewarn ""
		ewarn "There is a serious Docker-related kernel panic that has been fixed in 3.16+"
		ewarn "  (and was backported to 3.15.5+, 3.14.12+, and 3.12.25+)"
		ewarn ""
		ewarn "See also https://github.com/docker/docker/issues/2960"
	fi

	if kernel_is le 3 18; then
		CONFIG_CHECK+="
			~RESOURCE_COUNTERS
		"
	fi

	if kernel_is le 3 13; then
		CONFIG_CHECK+="
			~NETPRIO_CGROUP
		"
	else
		CONFIG_CHECK+="
			~CGROUP_NET_PRIO
		"
	fi

	if kernel_is lt 4 5; then
		CONFIG_CHECK+="
			~MEMCG_KMEM
		"
		ERROR_MEMCG_KMEM="CONFIG_MEMCG_KMEM: is optional"
	fi

	if kernel_is lt 4 7; then
		CONFIG_CHECK+="
			~DEVPTS_MULTIPLE_INSTANCES
		"
	fi

	if use aufs; then
		CONFIG_CHECK+="
			~AUFS_FS
			~EXT4_FS_POSIX_ACL ~EXT4_FS_SECURITY
		"
		ERROR_AUFS_FS="CONFIG_AUFS_FS: is required to be set if and only if aufs-sources are used instead of aufs4/aufs3"
	fi

	if use btrfs; then
		CONFIG_CHECK+="
			~BTRFS_FS
			~BTRFS_FS_POSIX_ACL
		"
	fi

	if use device-mapper; then
		CONFIG_CHECK+="
			~BLK_DEV_DM ~DM_THIN_PROVISIONING ~EXT4_FS ~EXT4_FS_POSIX_ACL ~EXT4_FS_SECURITY
		"
	fi

	if use overlay; then
		CONFIG_CHECK+="
			~OVERLAY_FS ~EXT4_FS_SECURITY ~EXT4_FS_POSIX_ACL
		"
	fi

	linux-info_pkg_setup

	# create docker group for the code checking for it in /etc/group
	enewgroup docker
}

src_install() {
	cd $WORKDIR/docker

	dobin docker
	dobin dockerd
	dobin docker-proxy
	dobin docker-containerd
	dobin docker-containerd-shim
	dobin docker-runc

	cd $WORKDIR/docker-${PV}-ce

	newinitd contrib/init/openrc/docker.initd docker
	newconfd contrib/init/openrc/docker.confd docker

	systemd_dounit contrib/init/systemd/docker.{service,socket}

	udev_dorules contrib/udev/*.rules

	dodoc AUTHORS CONTRIBUTING.md CHANGELOG.md NOTICE README.md
	dodoc -r docs/*

	dobashcomp contrib/completion/bash/*

	insinto /usr/share/zsh/site-functions
	doins contrib/completion/zsh/_*

	insinto /usr/share/vim/vimfiles
	doins -r contrib/syntax/vim/ftdetect
	doins -r contrib/syntax/vim/syntax

	# note: intentionally not using "doins" so that we preserve +x bits
	dodir /usr/share/${PN}/contrib
	cp -R contrib/* "${ED}/usr/share/${PN}/contrib"
}

pkg_postinst() {
	udev_reload

	elog
	elog "To use Docker, the Docker daemon must be running as root. To automatically"
	elog "start the Docker daemon at boot, add Docker to the default runlevel:"
	elog "  rc-update add docker default"
	elog "Similarly for systemd:"
	elog "  systemctl enable docker.service"
	elog
	elog "To use Docker as a non-root user, add yourself to the 'docker' group:"
	elog "  usermod -aG docker youruser"
	elog
}
