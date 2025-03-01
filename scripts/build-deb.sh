#! /bin/bash

set -x

### Update sources

mkdir -p /etc/apt/keyrings

curl -fsSL https://packagecloud.io/nitrux/mauikit/gpgkey | gpg --dearmor -o /etc/apt/keyrings/nitrux_mauikit-archive-keyring.gpg

cat <<EOF > /etc/apt/sources.list.d/nitrux-mauikit.list
deb [signed-by=/etc/apt/keyrings/nitrux_mauikit-archive-keyring.gpg] https://packagecloud.io/nitrux/mauikit/debian/ trixie main
EOF

apt -q update

### Install Package Build Dependencies #2

apt -qq -yy install --no-install-recommends \
	mauikit-git \
	mauikit-accounts-git \
	mauikit-filebrowsing-git

### Download Source

git clone --depth 1 --branch $VVAVE_BRANCH https://invent.kde.org/maui/vvave.git

### Compile Source

mkdir -p build && cd build

cmake \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DENABLE_BSYMBOLICFUNCTIONS=OFF \
	-DQUICK_COMPILER=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_SYSCONFDIR=/etc \
	-DCMAKE_INSTALL_LOCALSTATEDIR=/var \
	-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_INSTALL_RUNSTATEDIR=/run "-GUnix Makefiles" \
	-DCMAKE_VERBOSE_MAKEFILE=ON \
	-DCMAKE_INSTALL_LIBDIR=/usr/lib/x86_64-linux-gnu ../vvave/

make -j$(nproc)

make install

### Run checkinstall and Build Debian Package

>> description-pak printf "%s\n" \
	'MauiKit Multi-platform media player.' \
	'' \
	'VVave allows you to manage and play music locally or the cloud.' \
	'' \
	'VVave works on desktops, Android and Plasma Mobile.' \
	'' \
	''

checkinstall -D -y \
	--install=no \
	--fstrans=yes \
	--pkgname=vvave-git \
	--pkgversion=$PACKAGE_VERSION \
	--pkgarch=amd64 \
	--pkgrelease="1" \
	--pkglicense=LGPL-3 \
	--pkggroup=utils \
	--pkgsource=vvave \
	--pakdir=. \
	--maintainer=uri_herrera@nxos.org \
	--provides=vvave \
	--requires="libqt6multimedia6,libqt6multimediawidgets6,libqt6spatialaudio6,libtag2,mauikit-accounts-git \(\>= 4.0.1\),mauikit-filebrowsing-git \(\>= 4.0.1\),mauikit-git \(\>= 4.0.1\),qml6-module-qtcore" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes
