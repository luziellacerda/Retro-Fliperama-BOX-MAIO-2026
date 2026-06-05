#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile

ROMSPPSSPPFOLDER=/storage/roms/savestates/PPSSPPSDL/PSP
PPSSPPFOLDER=/storage/.config/ppsspp/PSP/
AUTOGP=$(get_ee_setting ppssppsdl_auto_gamepad)
CHEEVOS=$(get_ee_setting global.retroachievements)


if [[ "${AUTOGP}" == "1" ]]; then
	set_ppsspp_joy.sh
fi

if [[ "${CHEEVOS}" == "1" ]]; then
	ppssppcheevos.sh
fi

# Make sure we have the correct symlinks
for dir in Cheats PPSSPP_STATE SAVEDATA TEXTURES; do
    mkdir -p "${ROMSPPSSPPFOLDER}"
    
   if [ ! -L /storage/.config/ppsspp/PSP/${dir} ]; then
		cp -rf /storage/.config/ppsspp/PSP/${dir}/. ${ROMSPPSSPPFOLDER}/${dir}/
		rm -rf /storage/.config/ppsspp/PSP/${dir}
		ln -sf ${ROMSPPSSPPFOLDER}/${dir} /storage/.config/ppsspp/PSP/${dir}
    fi
done

if [ ! -s "${ROMSPPSSPPFOLDER}/Cheats/cheat.db" ];then 
	mkdir -p "${ROMSPPSSPPFOLDER}/Cheats/"
	cp -rf /usr/config/ppsspp/PSP/SYSTEM/Cheats/. "${ROMSPPSSPPFOLDER}/Cheats/" 

	CHEAT_DB_VERSION="06d4d6148b66109005f7d51c37e8344f0bc042cc"
	curl -sLo "${ROMSPPSSPPFOLDER}/Cheats/cheat.db" -f "https://raw.githubusercontent.com/Saramagrean/CWCheat-Database-Plus-/${CHEAT_DB_VERSION}/cheat.db" || true
fi

# --- Vulkan toggle support (patch for in-system option) ---
# 1. Inside the emulator: Go to PPSSPP menu (usually Select or hotkey) > Settings > Graphics > Backend
#    You can switch 0=OpenGL / 3=Vulkan on the fly for testing during use.
#    Changes are saved to your ini and persist across launches (unless forced below).
#
# 2. From the system (for default on these devices):
#    set_ee_setting ppssppsdl.vulkan 1   (or 0 to force GLES)
#    or set global.vulkan=1 in emuelec.conf
#
# This patch makes the choice easy both inside the emu menu AND from system level.
# Requires the build with VULKAN_SUPPORT=yes + libmali-vulkan for G31 (LZTurboX3/X4).
VULKAN=$(get_ee_setting ppssppsdl.vulkan 2>/dev/null)
if [ -z "$VULKAN" ]; then
    VULKAN=$(get_ee_setting global.vulkan 2>/dev/null)
fi
mkdir -p /storage/.config/ppsspp/PSP/SYSTEM
INI="/storage/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
if [[ "${VULKAN}" == "1" ]]; then
    sed -i 's/^GraphicsBackend = [0-9]*/GraphicsBackend = 3/' "$INI" 2>/dev/null || true
    if ! grep -q "^GraphicsBackend = 3" "$INI" 2>/dev/null; then
        echo "GraphicsBackend = 3" >> "$INI"
    fi
elif [[ "${VULKAN}" == "0" ]]; then
    sed -i 's/^GraphicsBackend = [0-9]*/GraphicsBackend = 0/' "$INI" 2>/dev/null || true
    if ! grep -q "^GraphicsBackend = 0" "$INI" 2>/dev/null; then
        echo "GraphicsBackend = 0" >> "$INI"
    fi
fi
# If unset/empty: do nothing → respect whatever you last chose inside PPSSPP's own menu during use.

# Safe settings when Vulkan (GraphicsBackend=3) is active (forced from system or saved from in-emu choice).
# This helps avoid black screen + sound-only on some Amlogic X boxes / dtb combinations with the current Mali Vulkan driver,
# while still allowing full Vulkan when it works on the user's hardware.
# Low res + buffered + VSync + no auto skip are known to be more stable for presentation on these G31 devices.
# The user can still change everything inside PPSSPP Graphics menu (our LZ options are right after the standard Backend choice).
if grep -q "^GraphicsBackend = 3" "$INI" 2>/dev/null ; then
  sed -i 's/^InternalResolution = [0-9]*/InternalResolution = 1/' "$INI" 2>/dev/null || true
  sed -i 's/^RenderingMode = [0-9]*/RenderingMode = 1/' "$INI" 2>/dev/null || true
  sed -i 's/^iVSyncInterval = [0-9]*/iVSyncInterval = 1/' "$INI" 2>/dev/null || echo "iVSyncInterval = 1" >> "$INI"
  sed -i 's/^AutoFrameSkip = [0-9]*/AutoFrameSkip = 0/' "$INI" 2>/dev/null || true
  # For stronger boxes you can experiment higher res by changing inside the menu (LZTurboX3/X4 profile)
  # or uncomment below (may cause black on marginal dtb/hardware):
  # sed -i 's/^InternalResolution = [0-9]*/InternalResolution = 2/' "$INI" 2>/dev/null || true
fi

# --- LZTurbo profile (LZTurboX / LZTurboX1 / LZTurboX2 / LZTurboX3 / LZTurboX4) ---
# This is exposed in PPSSPP Graphics menu as "LZTurbo" (separate from "LZFramesControl").
# Choose the device variant inside the emulator menu during tests.
# The launcher applies corresponding ini tweaks (weaker vs stronger hardware settings).
# Can also be set from system: set_ee_setting amlogic.xseries LZTurboX3
# Default: LZTurboX3 (best for G31 on X3/X4).
PROFILE=$(get_ee_setting amlogic.xseries 2>/dev/null)
if [ -z "$PROFILE" ]; then
    PROFILE="LZTurboX3"  # sensible default for LZGAMES on these G31 devices
fi
mkdir -p /storage/.config/ppsspp/PSP/SYSTEM
INI="/storage/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"

# Support choosing the LZ profile from inside the PPSSPP menu (new "Device Profile (LZTurbo)" option added to Graphics)
# It saves as LZDeviceProfile = N in the ini. Launcher reads it on next launch to apply the profile tweaks.
# This way the choice is available "dentro do menu back end" for testing during use.
INI_PROFILE=$(grep "^LZDeviceProfile = " "$INI" 2>/dev/null | head -1 | cut -d= -f2 | tr -d ' ' || echo "")
if [ -n "$INI_PROFILE" ]; then
  case "$INI_PROFILE" in
    0) INI_PROFILE_NAME="LZTurboX" ;;
    1) INI_PROFILE_NAME="LZTurboX1" ;;
    2) INI_PROFILE_NAME="LZTurboX2" ;;
    3) INI_PROFILE_NAME="LZTurboX3" ;;
    4) INI_PROFILE_NAME="LZTurboX4" ;;
    *) INI_PROFILE_NAME="" ;;
  esac
  if [ -z "$PROFILE" ]; then
    PROFILE="$INI_PROFILE_NAME"
  fi
fi

case "$PROFILE" in
  LZTurboX|LZTurboX1|LZTurboX2)
    # Weaker devices: conservative settings for stability
    sed -i 's/^InternalResolution = [0-9]*/InternalResolution = 1/' "$INI" 2>/dev/null || true
    sed -i 's/^TextureFiltering = [0-9]*/TextureFiltering = 1/' "$INI" 2>/dev/null || true
    sed -i 's/^RenderingMode = [0-9]*/RenderingMode = 1/' "$INI" 2>/dev/null || true
    sed -i 's/^FrameSkip = [0-9]*/FrameSkip = 1/' "$INI" 2>/dev/null || true
    ;;
  LZTurboX3|LZTurboX4|*)
    # Stronger LZTurboX3/X4 (A55 + G31): our tuned defaults for good balance
    sed -i 's/^InternalResolution = [0-9]*/InternalResolution = 1/' "$INI" 2>/dev/null || true
    sed -i 's/^TextureFiltering = [0-9]*/TextureFiltering = 1/' "$INI" 2>/dev/null || true
    sed -i 's/^RenderingMode = [0-9]*/RenderingMode = 1/' "$INI" 2>/dev/null || true
    # Uncomment below if you want higher res on LZTurboX3/X4 for testing (may need lower other settings)
    # sed -i 's/^InternalResolution = [0-9]*/InternalResolution = 2/' "$INI" 2>/dev/null || true
    ;;
esac

# --- LZFramesControl (FPS limit 15/30/45/60) ---
# Exposed in PPSSPP Graphics menu as separate "LZFramesControl" (as requested, two menus: LZTurbo and LZFramesControl).
# Values in menu: Unlimited, 15, 30, 45, 60
# Launcher reads the choice from ini (LZMaxFpsLimit) or system setting and forces FrameRate etc.
# Can be set from system too: set_ee_setting ppssppsdl.fpslimit 30
# Defaults based on LZTurbo profile if nothing chosen.
FPSLIMIT=$(get_ee_setting ppssppsdl.fpslimit 2>/dev/null)
if [ -z "$FPSLIMIT" ]; then
    # Check what the user chose inside the PPSSPP menu (saved in ini by our UI patch)
    INI_FPS=$(grep "^LZMaxFpsLimit = " "$INI" 2>/dev/null | head -1 | cut -d= -f2 | tr -d ' ' || echo "")
    case "$INI_FPS" in
      1) FPSLIMIT=15 ;;
      2) FPSLIMIT=30 ;;
      3) FPSLIMIT=45 ;;
      4) FPSLIMIT=60 ;;
      *) FPSLIMIT="" ;;
    esac
fi
if [ -z "$FPSLIMIT" ]; then
    # Default based on device profile for "out of box" experience on weaker/stronger devices
    case "$PROFILE" in
      LZTurboX|LZTurboX1|LZTurboX2)
        FPSLIMIT=30  # conservative for weaker hardware
        ;;
      LZTurboX3|LZTurboX4|*)
        FPSLIMIT=60  # full speed for stronger
        ;;
    esac
fi
mkdir -p /storage/.config/ppsspp/PSP/SYSTEM
INI="/storage/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
if [ "$FPSLIMIT" != "0" ]; then
    # Enforce exact FPS cap
    sed -i 's/^FrameRate = [0-9-]*/FrameRate = '"$FPSLIMIT"'/' "$INI" 2>/dev/null || echo "FrameRate = $FPSLIMIT" >> "$INI"
    sed -i 's/^AutoFrameSkip = [0-9]*/AutoFrameSkip = 0/' "$INI" 2>/dev/null || echo "AutoFrameSkip = 0" >> "$INI"
    sed -i 's/^FrameSkip = [0-9]*/FrameSkip = 0/' "$INI" 2>/dev/null || echo "FrameSkip = 0" >> "$INI"
    # Also set the second limit if used
    sed -i 's/^FrameRate2 = [0-9-]*/FrameRate2 = '"$FPSLIMIT"'/' "$INI" 2>/dev/null || true
fi
# If FPSLIMIT=0 or unset after logic, leave unlimited (user can choose in menu)

ARG=${1//[\\]/}
export SDL_AUDIODRIVER=alsa          
PPSSPPSDL --fullscreen "${ARG}"
