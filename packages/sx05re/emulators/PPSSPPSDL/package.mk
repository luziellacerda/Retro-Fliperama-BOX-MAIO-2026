# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="PPSSPPSDL"
PKG_VERSION="392a862be20ef90b3bbad2756f50f10f7f36d57e"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/hrydgard/ppsspp"
PKG_URL="https://github.com/hrydgard/ppsspp.git"
PKG_DEPENDS_TARGET="toolchain ffmpeg libzip libpng SDL2 zlib zip"
if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" vulkan-loader"
fi
PKG_SHORTDESC="PPSSPPDL"
PKG_LONGDESC="PPSSPP Standalone"
GET_HANDLER_SUPPORT="git"
PKG_BUILD_FLAGS="-lto"


PKG_CMAKE_OPTS_TARGET+="-DUSE_SYSTEM_FFMPEG=ON \
                        -DUSING_FBDEV=ON \
                        -DUSING_EGL=OFF \
                        -DUSING_GLES2=ON \
                        -DUSE_DISCORD=OFF"
if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN=ON -DUSING_X11_VULKAN=OFF"
fi

if [ ${ARCH} == "aarch64" ]; then
PKG_CMAKE_OPTS_TARGET+=" -DARM64=ON"
# Optimized for Amlogic X3/X4 (A55 + G31) and compatible with X/X2 (A53)
# See pre_configure_target() below for the actual CFLAGS/CXXFLAGS append
# Force Vulkan + no X11 for our LZGAMES/Amlogic-ng target (X3/X4 G31) even if the VULKAN_SUPPORT if didn't trigger in this parse context
PKG_CMAKE_OPTS_TARGET+=" -DUSE_VULKAN=ON -DUSING_X11_VULKAN=OFF"
else
PKG_CMAKE_OPTS_TARGET+=" -DARMV7=ON"
fi


pre_configure_target() {
if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
	sed -i "s|include_directories(/usr/include/drm)|include_directories(${SYSROOT_PREFIX}/usr/include/drm)|" ${PKG_BUILD}/CMakeLists.txt
fi

# Amlogic X3/X4 (A55 + G31) optimizations (and compatible with older X/X2 A53 devices)
# Appended to the environment so cmake picks them up cleanly (no quoting issues in PKG_CMAKE_OPTS_TARGET)
if [ ${ARCH} == "aarch64" ]; then
  CFLAGS+=" -O3 -march=armv8-a+crc+simd -mtune=cortex-a55 -fomit-frame-pointer"
  CXXFLAGS+=" -O3 -march=armv8-a+crc+simd -mtune=cortex-a55 -fomit-frame-pointer"
fi
}

pre_make_target() {
  # fix cross compiling
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}


makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/*.sh ${INSTALL}/usr/bin
    cp `find . -name "PPSSPPSDL" | xargs echo` ${INSTALL}/usr/bin/PPSSPPSDL
    ln -sf /storage/.config/ppsspp/assets ${INSTALL}/usr/bin/assets
    mkdir -p ${INSTALL}/usr/config/ppsspp/
    cp -r `find . -name "assets" | xargs echo` ${INSTALL}/usr/config/ppsspp/
    
    cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/ppsspp/
    
    rm ${INSTALL}/usr/config/ppsspp/assets/gamecontrollerdb.txt
    ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt ${INSTALL}/usr/config/ppsspp/assets/gamecontrollerdb.txt
    
# redirect some of PSP folders to /storage/roms to keep all the saves and custom files
   mkdir -p "${INSTALL}/usr/config/ppsspp/PSP"    
   
for dir in Cheats PPSSPP_STATE SAVEDATA TEXTURES; do
		ln -sf "/storage/roms/savestates/PPSSPPSDL/PSP/${dir}" "${INSTALL}/usr/config/ppsspp/PSP/${dir}"
done
} 
