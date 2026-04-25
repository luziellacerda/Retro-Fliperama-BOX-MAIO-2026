# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="configtools"
PKG_VERSION="v2024.01.01"
PKG_VERSION="28ea239c53a2d5d8800c472bc2452eaa16e37af2"
PKG_LICENSE="GPL"
PKG_SITE="https://git.savannah.gnu.org/cgit/config.git"

# Usa snapshot estável real do git (não cgit)
PKG_URL="https://git.savannah.gnu.org/git/config.git/snapshot/config-${PKG_VERSION}.tar.gz"

PKG_DEPENDS_HOST=""
PKG_LONGDESC="GNU config tools used by build system"
PKG_TOOLCHAIN="manual"

# Desativa hash (ou atualiza depois de baixar real)
PKG_SHA256=""

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/configtools
  cp -r . ${TOOLCHAIN}/configtools/
}
