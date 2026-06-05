# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)
# Adapted for EmuELEC LZGAMES / Amlogic-ng Vulkan on Mali Bifrost (G31/G52)

PKG_NAME="libmali-vulkan"
PKG_VERSION="r46p0-01eac1"
PKG_LICENSE="mali_driver"
PKG_ARCH="arm aarch64"
PKG_SITE="https://developer.arm.com/downloads/-/mali-drivers/user-space"
PKG_URL="https://developer.arm.com/-/media/Files/downloads/mali-drivers/user-space/odroid-n2plus/BXODROIDN2PL-${PKG_VERSION}.tar"
PKG_DEPENDS_TARGET="toolchain vulkan-loader vulkan-tools"
PKG_TOOLCHAIN="manual"
PKG_LONGDESC="Vulkan drivers (ICD + libs) for Mali Bifrost GPUs on s922x / Amlogic-ng devices to enable Vulkan in PPSSPP and other emulators."

make_target() {
  :
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/{lib,share}
  tar -xvJf ${PKG_BUILD}/mali.tar.xz -C ${INSTALL}
  mv ${INSTALL}/lib/${TARGET_ARCH}-linux-gnu/* ${INSTALL}/usr/lib
  rm -r ${INSTALL}/lib
  tar -xvJf ${PKG_BUILD}/rootfs_additions.tar.xz -C ${INSTALL}/usr/share
  mv ${INSTALL}/usr/share/etc/vulkan/* ${INSTALL}/usr/share/vulkan/
  rm -r ${INSTALL}/usr/share/etc
}
