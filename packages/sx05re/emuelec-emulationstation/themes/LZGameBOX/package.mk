# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="LZGameBOX"
PKG_VERSION="5bee6a2"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/luziellacerda/LZGameBOX"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET=""
PKG_SECTION="main"
PKG_SHORTDESC="LZGames 2026 Retro Games"
PKG_TOOLCHAIN="manual"
GET_HANDLER_SUPPORT="git"

make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/emulationstation/themes/LZGameBOX
    cp -r * ${INSTALL}/usr/config/emulationstation/themes/LZGameBOX
    rm -rf ${INSTALL}/usr/config/emulationstation/themes/LZGameBOX/screens.png
}
