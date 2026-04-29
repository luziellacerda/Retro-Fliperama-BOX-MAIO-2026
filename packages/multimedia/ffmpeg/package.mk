PKG_NAME="ffmpeg"
PKG_VERSION="4.4.1"
PKG_LICENSE="GPL-3.0-only"
PKG_SITE="https://ffmpeg.org"
PKG_URL="http://ffmpeg.org/releases/ffmpeg-${PKG_VERSION}.tar.xz"

# 🔥 IMPORTANTE: SDL2 REMOVIDO (evita libavdevice/sdl2.c quebrado)
PKG_DEPENDS_TARGET="toolchain zlib bzip2 speex lame x264 libtheora"

PKG_LONGDESC="FFmpeg multimedia framework"
PKG_PATCH_DIRS="kodi libreelec"

# ---------------- PROJECT ----------------
case "${PROJECT}" in
  Amlogic)
    PKG_VERSION="f9638b6331277e53ecd9276db5fe6dcd91d44c57"
    PKG_URL="https://github.com/jc-kynesim/rpi-ffmpeg/archive/${PKG_VERSION}.tar.gz"
    PKG_PATCH_DIRS="libreelec"
    ;;
esac

get_graphicdrivers

# ---------------- OPTIONS ----------------
PKG_FFMPEG_HWACCEL="--enable-hwaccels"
PKG_FFMPEG_AV1="--disable-libdav1d"

PKG_FFMPEG_V4L2="--disable-v4l2_m2m"
PKG_FFMPEG_VAAPI="--disable-vaapi"
PKG_FFMPEG_VDPAU="--disable-vdpau"

if [ "${V4L2_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" libdrm"
  PKG_FFMPEG_V4L2="--enable-v4l2_m2m --enable-libdrm --disable-v4l2-request"
fi

if [ "${VAAPI_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" libva"
  PKG_FFMPEG_VAAPI="--enable-vaapi"
fi

if [ "${VDPAU_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" libvdpau"
  PKG_FFMPEG_VDPAU="--enable-vdpau"
fi

# ---------------- DEBUG ----------------
if build_with_debug; then
  PKG_FFMPEG_DEBUG="--enable-debug --disable-stripping"
else
  PKG_FFMPEG_DEBUG="--disable-debug --enable-stripping"
fi

# ---------------- NEON ----------------
if target_has_feature neon; then
  PKG_FFMPEG_FPU="--enable-neon"
else
  PKG_FFMPEG_FPU="--disable-neon"
fi

# ---------------- CONFIGURE FIX ----------------
configure_target() {

  cd ${PKG_BUILD} || exit 1

  # 🔥 IMPORTANTE: evita SDL detecção automática quebrada
  export SDL2_CONFIG="false"

  ./configure \
    --prefix=/usr \
    --cpu=${TARGET_CPU} \
    --arch=${TARGET_ARCH} \
    --enable-cross-compile \
    --cross-prefix=${TARGET_PREFIX} \
    --sysroot=${SYSROOT_PREFIX} \
    --target-os=linux \
    --cc=${CC} \
    --ar=${AR} \
    --nm=${NM} \
    --enable-gpl \
    --enable-version3 \
    --disable-doc \
    --disable-static \
    --enable-shared \
    --enable-pic \
    --disable-sdl2 \
    --disable-indev=sdl2 \
    --disable-outdev=sdl2 \
    ${PKG_FFMPEG_DEBUG} \
    --enable-avcodec \
    --enable-avformat \
    --enable-swscale \
    --enable-avfilter \
    --enable-pthreads \
    --enable-network \
    --disable-openssl \
    --disable-gnutls \
    --enable-zlib \
    --enable-libx264 \
    --enable-libmp3lame \
    --enable-libtheora \
    ${PKG_FFMPEG_V4L2} \
    ${PKG_FFMPEG_VAAPI} \
    ${PKG_FFMPEG_VDPAU} \
    ${PKG_FFMPEG_HWACCEL} \
    ${PKG_FFMPEG_FPU} \
    ${PKG_FFMPEG_AV1} \
    --enable-encoder=aac \
    --enable-encoder=ac3 \
    --enable-encoder=mjpeg \
    --enable-encoder=png \
    --enable-muxer=mp4 \
    --enable-muxer=mpegts \
    --enable-demuxers \
    --enable-parsers \
    --enable-bsfs \
    --enable-filters \
    --disable-lzma \
    --disable-frei0r \
    --disable-libvpx \
    --disable-libvorbis \
    --disable-libxvid
}

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/share/ffmpeg/examples
}
