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

  # LZGAMES: install the libmali setup script + service (updated to support this package's
  # libmali.so.0.46.0 naming for G31 when user selects dtb for Amlogic X boxes).
  # This ensures /usr/bin/libmali-setup runs at boot and creates the /var/lib/libmali symlink
  # so GLES/ES can initialize the display (fixes black screen after dtb swap).
  mkdir -p ${INSTALL}/usr/bin ${INSTALL}/usr/lib/systemd/system
  cp -f ${PKG_DIR}/../libmali/scripts/libmali-setup ${INSTALL}/usr/bin/libmali-setup || true
  cp -f ${PKG_DIR}/../libmali/system.d/libmali-setup.service ${INSTALL}/usr/lib/systemd/system/ || true
  mkdir -p ${INSTALL}/usr/lib/systemd/system/multi-user.target.wants
  ln -sf /usr/lib/systemd/system/libmali-setup.service ${INSTALL}/usr/lib/systemd/system/multi-user.target.wants/libmali-setup.service || true
}
