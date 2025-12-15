#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 <Nitrux Latinoamericana S.C. <hello@nxos.org>>


# -- Exit on errors.

set -e


# -- Download Source

git clone --depth 1 --branch "$VVAVE_BRANCH" https://invent.kde.org/maui/vvave.git

if ! grep -Eq 'find_package\(Qt.*REQUIRED COMPONENTS.*Qml' vvave/CMakeLists.txt; then
  sed -i '/find_package(Qt.*REQUIRED COMPONENTS/ s/Core/& Qml/' vvave/CMakeLists.txt
fi

if grep -qE '^[[:space:]]*qt_policy\(SET QTP0004 NEW\)' vvave/CMakeLists.txt; then
  sed -i '/^[[:space:]]*qt_policy(SET QTP0004 NEW)/c\
if(QT_VERSION VERSION_GREATER_EQUAL "6.8.0")\
  qt_policy(SET QTP0004 NEW)\
endif()' vvave/CMakeLists.txt
fi


# --  Compile Source

mkdir -p build && cd build

HOST_MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH)

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
	-DCMAKE_INSTALL_LIBDIR="/usr/lib/${HOST_MULTIARCH}" \
	../vvave/

make -j"$(nproc)"

make install


# -- Run checkinstall and Build Debian Package

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
	--pkgname=vvave \
	--pkgversion="$PACKAGE_VERSION" \
	--pkgarch="$(dpkg --print-architecture)" \
	--pkgrelease="1" \
	--pkglicense=LGPL-3 \
	--pkggroup=utils \
	--pkgsource=vvave \
	--pakdir=. \
	--maintainer=uri_herrera@nxos.org \
	--provides=vvave \
	--requires="kio-extras,libqt6multimedia6,libqt6multimediawidgets6,libqt6spatialaudio6,libtag2,mauikit-accounts \(\>= 4.0.3\),mauikit-audio \(\>= 4.0.3\),mauikit-filebrowsing \(\>= 4.0.3\),mauikit \(\>= 4.0.3\),qml6-module-qtcore,qml6-module-qtquick-effects" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes
