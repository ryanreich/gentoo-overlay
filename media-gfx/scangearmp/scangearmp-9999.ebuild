# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI="5"

inherit eutils flag-o-matic autotools multilib

DESCRIPTION="Canon InkJet Scanner Driver and ScanGear MP for Linux (PIXMA MG5300 series)."
HOMEPAGE="http://support-th.canon-asia.com/contents/TH/EN/0100588802.html"
SRC_URI="http://gdlp01.c-wss.com/gds/1/0100003931/01/scangearmp-source-1.80-1.tar.gz"
LICENSE="GPL-2 scangearmp"

SLOT=0
KEYWORDS="~x86 ~amd64"
USE="+mg5300"

DEPEND="
	net-print/cnijfilter
	dev-libs/libusb-compat
	>=media-libs/libpng-1.2.8
	>=media-gfx/gimp-2.6.8
	>=x11-libs/gtk+-2.6
	>=media-gfx/sane-backends-1.0.19-r2"

# Printer model
PRINTER_USE="mg5300"
PRINTER_ID="389"

_prefix="/usr"
_bindir="${_prefix}/bin"
_libdir="/usr/lib64"
_gimpdir="${_libdir}/gimp/2.0/plug-ins"
_udevdir="/lib/udev/rules.d"

S="${WORKDIR}/scangearmp-source-1.80-1"

###
#   Standard Ebuild-functions
###

pkg_setup() {
	[[ -z "$LINGUAS" ]] && LINGUAS="en"
}

src_prepare(){
	epatch "${FILESDIR}/compile-fixes.patch"
	pushd scangearmp
	eautoreconf
	popd
}

src_configure(){
	pushd scangearmp
	econf LDFLAGS="-L${PWD}/../com/libs_bin64 -lm"
	popd
}

src_compile() {
	pushd scangearmp
	emake
	popd
}

src_install() {
	pushd scangearmp
	dodir "${EPREFIX}${_bindir}"
	emake DESTDIR=${D} install
	rm -f ${D}${_libdir}/*.{,1}a || die
	popd

	# no doexe due to symlinks
	dodir "${EPREFIX}${_libdir}"
	cp -a {${PRINTER_ID},com}/libs_bin64/* "${D}${_libdir}" || die

	exeinto ${_libdir}/bjlib
	doexe com/ini/canon_mfp_net.ini ${PRINTER_ID}/*.{tbl,DAT}

	exeinto ${_udevdir}
	doexe scangearmp/etc/*.rules

	# make symbolic link for gimp-plug-in
	if [ -d "${_gimpdir}" ]; then
		dodir ${_gimpdir}
		dosym ${_bindir}/scangearmp ${_gimpdir}/scangearmp
	fi
}

pkg_postinst() {
	if [ -x /sbin/udevadm ]; then
		einfo ""
		einfo "Reloading usb rules..."
		/sbin/udevadm control --reload-rules 2> /dev/null
		/sbin/udevadm trigger --action=add --subsystem-match=usb 2>/dev/null
	else
		einfo ""
		einfo "Please, reload usb rules manually."
	fi

	einfo ""
	einfo "If you experience any problems, please visit:"
	einfo " http://forums.gentoo.org/viewtopic-p-3217721.html"
	einfo ""
}
