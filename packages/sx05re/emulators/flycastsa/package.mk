# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="flycastsa"
PKG_VERSION="e4c96293e439a38b10cbe6f9db262500aae3c7d5"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES} alsa SDL2 libzip zip"
if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" vulkan-loader"
fi
PKG_LONGDESC="Flycast is a multiplatform Sega Dreamcast, Naomi and Atomiswave emulator"
PKG_TOOLCHAIN="cmake"
PKG_GIT_CLONE_BRANCH="master"


if [ "${ARCH}" == "arm" ]; then
	PKG_PATCH_DIRS="arm"
fi

pre_configure_target() {
export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds"
PKG_CMAKE_OPTS_TARGET+="-DUSE_GLES=ON -DUSE_HOST_SDL=ON"
if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN=OFF"
fi
# For LZGAMES / Amlogic-ng (X3/X4 G31) force Vulkan + no X11 WSI (robust like PPSSPP)
if [ ${ARCH} == "aarch64" ]; then
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN=ON -DUSE_X11=OFF"
fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/.${TARGET_NAME}/flycast ${INSTALL}/usr/bin/flycast
  cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

	chmod +x ${INSTALL}/usr/bin/flycast.sh
	chmod +x ${INSTALL}/usr/bin/set_flycast_joy.sh
}
