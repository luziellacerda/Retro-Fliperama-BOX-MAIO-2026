#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

mkdir -p "/storage/.local/share/"

if [ ! -L "/storage/.local/share/flycast" ]; then
    mkdir -p "/storage/roms/bios/dc"
    rm -rf "/storage/.local/share/flycast"
    ln -sf "/storage/roms/bios/dc" "/storage/.local/share/flycast"
fi

AUTOGP=$(get_ee_setting flycast_auto_gamepad)
if [[ "${AUTOGP}" != "0" ]]; then
  mkdir -p "/storage/.config/flycast/mappings"
  set_flycast_joy.sh
fi

flycastcheevos.sh

# --- LZGAMES: LZTurbo + LZFramesControl (two menus inside emulator, same as PSP) ---
# Also: Vulkan renderer choice + system override supported (see below).
# The menus "LZTurbo" (Device Profile: LZTurboX..LZTurboX4) and "LZFramesControl" (FPS Limit)
# are added by 07-lz-menus.patch right after "Graphics API" in Graphics settings.
# Inside-emulator choice saved to emu.cfg as LZDeviceProfile=N / LZMaxFpsLimit=M .
# Launcher respects menu choice for testing during use (unless system override below).

# System overrides (also global.vulkan for renderer):
#   set_ee_setting amlogic.xseries LZTurboX3
#   set_ee_setting flycast.fpslimit 30
#   set_ee_setting flycast.vulkan 1
VULKAN=$(get_ee_setting flycast.vulkan 2>/dev/null)
if [ -z "$VULKAN" ]; then
    VULKAN=$(get_ee_setting global.vulkan 2>/dev/null)
fi
mkdir -p /storage/.config/flycast
CFG="/storage/.config/flycast/emu.cfg"
if [ ! -f "$CFG" ]; then
    cp /storage/roms/bios/dc/emu.cfg "$CFG" 2>/dev/null || touch "$CFG"
fi
# If unset: leave as-is (respect choice made inside Flycast's own menu during use, including Vulkan + LZ*).

PROFILE=$(get_ee_setting amlogic.xseries 2>/dev/null)
if [ -z "$PROFILE" ]; then
    PROFILE="LZTurboX3"  # default good for LZGAMES X3/X4 G31
fi
mkdir -p /storage/.config/flycast
CFG="/storage/.config/flycast/emu.cfg"
if [ ! -f "$CFG" ]; then
    cp /storage/roms/bios/dc/emu.cfg "$CFG" 2>/dev/null || touch "$CFG"
fi

# If user chose inside Flycast menu (LZTurbo), prefer it over default (but system amlogic.xseries wins if set)
INI_PROFILE=$(grep -E "(^| )LZDeviceProfile = " "$CFG" 2>/dev/null | head -1 | sed 's/.*= *//' | tr -d ' \r' || echo "")
if [ -n "$INI_PROFILE" ]; then
  case "$INI_PROFILE" in
    0) INI_PROFILE_NAME="LZTurboX" ;;
    1) INI_PROFILE_NAME="LZTurboX1" ;;
    2) INI_PROFILE_NAME="LZTurboX2" ;;
    3) INI_PROFILE_NAME="LZTurboX3" ;;
    4) INI_PROFILE_NAME="LZTurboX4" ;;
    *) INI_PROFILE_NAME="" ;;
  esac
  if [ -z "$PROFILE" ] || [ "$PROFILE" = "LZTurboX3" ]; then
    # only fall to menu choice if no explicit system profile (or still on default)
    [ -n "$INI_PROFILE_NAME" ] && PROFILE="$INI_PROFILE_NAME"
  fi
fi

case "$PROFILE" in
  LZTurboX|LZTurboX1|LZTurboX2)
    # Weaker Amlogic (X/X1/X2 A53 + older Mali): conservative for stability on low power
    sed -i 's/pvr.AutoSkipFrame = [0-9]*/pvr.AutoSkipFrame = 2/' "$CFG" 2>/dev/null || echo "pvr.AutoSkipFrame = 2" >> "$CFG"
    sed -i 's/ta.skip = [0-9]*/ta.skip = 1/' "$CFG" 2>/dev/null || echo "ta.skip = 1" >> "$CFG"
    sed -i 's/rend.Resolution = [0-9]*/rend.Resolution = 480/' "$CFG" 2>/dev/null || echo "rend.Resolution = 480" >> "$CFG"
    sed -i 's/rend.ThreadedRendering = .*/rend.ThreadedRendering = no/' "$CFG" 2>/dev/null || true
    ;;
  LZTurboX3|LZTurboX4|*)
    # Stronger (X3/X4 A55 + G31): balanced, Vulkan shines here
    sed -i 's/pvr.AutoSkipFrame = [0-9]*/pvr.AutoSkipFrame = 1/' "$CFG" 2>/dev/null || echo "pvr.AutoSkipFrame = 1" >> "$CFG"
    sed -i 's/ta.skip = [0-9]*/ta.skip = 0/' "$CFG" 2>/dev/null || echo "ta.skip = 0" >> "$CFG"
    sed -i 's/rend.Resolution = [0-9]*/rend.Resolution = 480/' "$CFG" 2>/dev/null || echo "rend.Resolution = 480" >> "$CFG"
    # Can try higher res on X4 if wanted: uncomment next for testing
    # sed -i 's/rend.Resolution = [0-9]*/rend.Resolution = 960/' "$CFG" 2>/dev/null || true
    sed -i 's/rend.ThreadedRendering = .*/rend.ThreadedRendering = yes/' "$CFG" 2>/dev/null || true
    ;;
esac

# --- LZFramesControl (exact FPS 15/30/45/60) ---
# Reads from menu (LZMaxFpsLimit in emu.cfg) or system flycast.fpslimit
# 0 or unset = unlimited (or profile default)
FPSLIMIT=$(get_ee_setting flycast.fpslimit 2>/dev/null)
if [ -z "$FPSLIMIT" ]; then
    INI_FPS=$(grep -E "(^| )LZMaxFpsLimit = " "$CFG" 2>/dev/null | head -1 | sed 's/.*= *//' | tr -d ' \r' || echo "")
    case "$INI_FPS" in
      1) FPSLIMIT=15 ;;
      2) FPSLIMIT=30 ;;
      3) FPSLIMIT=45 ;;
      4) FPSLIMIT=60 ;;
      *) FPSLIMIT="" ;;
    esac
fi
if [ -z "$FPSLIMIT" ]; then
    # sensible default from profile
    case "$PROFILE" in
      LZTurboX|LZTurboX1|LZTurboX2)
        FPSLIMIT=30
        ;;
      LZTurboX3|LZTurboX4|*)
        FPSLIMIT=60
        ;;
    esac
fi
if [ "$FPSLIMIT" != "0" ] && [ -n "$FPSLIMIT" ]; then
    # Enforce cap: disable autoskip, enable audio limit, set fixed freq if honored by core
    sed -i 's/pvr.AutoSkipFrame = [0-9]*/pvr.AutoSkipFrame = 0/' "$CFG" 2>/dev/null || echo "pvr.AutoSkipFrame = 0" >> "$CFG"
    sed -i 's/ta.skip = [0-9]*/ta.skip = 0/' "$CFG" 2>/dev/null || echo "ta.skip = 0" >> "$CFG"
    sed -i 's/aica.LimitFPS = .*/aica.LimitFPS = yes/' "$CFG" 2>/dev/null || echo "aica.LimitFPS = yes" >> "$CFG"
    # rend.FixedFrequency may be read by timing code even if not a registered Option
    if grep -q "rend.FixedFrequency" "$CFG" 2>/dev/null; then
        sed -i 's/rend.FixedFrequency = [0-9]*/rend.FixedFrequency = '"$FPSLIMIT"'/' "$CFG"
    else
        echo "rend.FixedFrequency = $FPSLIMIT" >> "$CFG"
    fi
    # Also set LimitFPS runtime hint if present as top level
    sed -i 's/^LimitFPS = .*/LimitFPS = yes/' "$CFG" 2>/dev/null || true
fi
# FPS=0/unset: leave as unlimited (user chose Unlimited in LZFramesControl menu)

# Also ensure Vulkan renderer if system wants (in addition to menu choice inside)
# Note: actual key saved by flycast is pvr.rend (4=Vulkan), we set both for compat
if [[ "${VULKAN}" == "1" ]]; then
    if grep -q "pvr.rend" "$CFG" 2>/dev/null; then
        sed -i 's/pvr.rend = [0-9]*/pvr.rend = 4/' "$CFG"
    else
        echo "pvr.rend = 4" >> "$CFG"
    fi
    # keep the old key too
    if grep -q "RendererType" "$CFG" 2>/dev/null; then
        sed -i 's/RendererType = [0-9]*/RendererType = 4/' "$CFG"
    else
        echo "RendererType = 4" >> "$CFG"
    fi
fi

flycast "${1}"
