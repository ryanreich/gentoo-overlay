# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=5

inherit eutils autotools flag-o-matic multilib

DESCRIPTION="Canon InkJet Printer Driver for Linux (PIXMA MG5300 series)."
HOMEPAGE="http://support-sg.canon-asia.com/contents/SG/EN/0100392802.html"
SRC_URI="http://gdlp01.c-wss.com/gds/8/0100003928/01/cnijfilter-source-3.60-1.tar.gz"

PRINTER_USE=mg5300
PRINTER_ID=389

LICENSE="GPL-2 cnijfilter"
KEYWORDS="~amd64"
SLOT=${PRINTER_USE}

RDEPEND="
	>=media-libs/libpng-1.0.9
	>=media-libs/tiff-3.4
	>=net-print/cups-1.4
	>=dev-libs/libxml2-2.7.3-r2
	>=x11-libs/gtk+-2.6:2
"
DEPEND="${DEPEND}
	sys-devel/gettext
"

S="${WORKDIR}/cnijfilter-source-3.60-1"
SRC_DIRS=("ppd" "cnijfilter" "printui" "lgmon" "cngpijmon")

pkg_setup() {
	[[ -z ${LINGUAS} ]] && LINGUAS="en"
}

src_prepare() {
	# missing macros directory make aclocal fail
	mkdir printui/m4 || die

	epatch "${FILESDIR}/compile-fixes.patch"
	for d in ${SRC_DIRS[@]}; do
		echo ">>> Working in: ${d}"
		pushd ${d} >/dev/null
		eautoreconf
		popd >/dev/null
	done
}

src_configure() {
	local d
	for d in ${SRC_DIRS[@]}; do
		echo ">>> Working in: ${d}"
		pushd ${d} >/dev/null
		econf --prefix="${EPREFIX}/usr" \
			  --program-suffix="${PRINTER_USE}" \
			  --datadir="${EPREFIX}/usr/share" \
			  --enable-progpath="${EPREFIX}/usr/bin" \
			  --enable-libpath="${EPREFIX}/usr/lib64/bjlib" \
			  --enable-binpath="${EPREFIX}/usr/bin"
		popd > /dev/null
	done
}

src_compile() {
	for d in ${SRC_DIRS[@]}; do
		echo ">>> Working in: ${d}"
		pushd ${d} >/dev/null
		emake
		popd > /dev/null
	done
}

src_install() {
	for d in ${SRC_DIRS[@]}; do
		echo ">>> Working in: ${d}"
		pushd ${d} >/dev/null
		emake DESTDIR=${D} install
		popd > /dev/null
	done

	local _libdir="${EPREFIX}/usr/lib64"
	dodir ${_libdir}
	# no doexe due to symlinks
	cp -a {${PRINTER_ID},com}/libs_bin64/* "${D}/${_libdir}" || die

	exeinto ${_libdir}/cnijlib
	doexe ${PRINTER_ID}/database/* com/ini/cnnet.ini
	# create symlink for the cnijlib to bjlib as some formats need it
	dosym ${_libdir}/cnijlib ${_libdir}/bjlib

	insinto ${EPREFIX}/usr/share/cups/model
	doins ppd/canon${PRINTER_USE}.ppd
}

pkg_postinst() {
	einfo ""
	einfo "For installing a printer:"
	einfo " * Restart CUPS: /etc/init.d/cupsd restart"
	einfo " * Go to http://127.0.0.1:631/"
	einfo "   -> Printers -> Add Printer"
	einfo ""
	einfo "If you experience any problems, please visit:"
	einfo " http://forums.gentoo.org/viewtopic-p-3217721.html"
	einfo ""
}
