# LZGAMES EmuELEC Grok Continuation Context

**CRITICAL RULES (NEVER BREAK):**
- **ONLY work inside `/home/pc/Documentos/EmuELEC`**. Do not touch any other folder on the system, ever. All paths, edits, builds, and staging must be relative to this directory.
- **Always use the exact full build prefix** for any package or image work:
  ```
  DISTRO=LZGAMES PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=aarch64 ./scripts/build <package>
  ```
  Or for full image:
  ```
  DISTRO=LZGAMES PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=aarch64 make image
  ```
  (Or `./scripts/build image` with the same prefix.)
- Prefer **targeted package builds** over full `make image` when possible. After package build, manually stage key files from `build.LZGAMES-Amlogic-ng.aarch64-4/install_pkg/<pkg>-<ver>/` into `build.LZGAMES-Amlogic-ng.aarch64-4/image/` (and `image/system/` where appropriate) for quick verification without rebuilding the entire distro image.
- Every change must support the **LZGAMES custom features** on Amlogic X-series (X/X1/X2 = weaker A53+Mali-450/G31; X3/X4 = stronger A55+G31 ~2GHz). This includes Vulkan enablement + custom "LZ" menus/profiles.
- After any version bump or source change, **always**:
  1. Clean old artifacts (`rm -rf build.LZGAMES-.../build/<pkg>-* install_pkg/<pkg>-* sources/<pkg>/<pkg>-oldver`).
  2. Run the full DISTRO build (it will likely fail on our custom patches because source changed).
  3. In the **new** `build.LZGAMES-.../build/<pkg>-newcommit/` dir, manually port our custom code (LZ menus via search_replace on UI/Config files, Vulkan conditionals, env support, etc.).
  4. Use `git diff` (if the build dir is a git tree) or manual unified diff to create/update `.patch` files in `packages/.../<pkg>/patches/`.
  5. Update launcher scripts (`scripts/<emu>.sh`) with matching get_ee_setting + case logic for profiles/FPS/Vulkan.
  6. Update `packages/sx05re/emuelec/config/emuelec/configs/emuelec.conf` with docs for new settings.
  7. Re-build + stage + verify (check strings in binary for our menu text, run the binary if possible, check image/ contents).
- Use `todo_write` for multi-step work if >3 steps. Mark items done immediately when complete.
- The goal is **in-emulator menus** (LZTurbo + LZFramesControl) for testing during use, plus launcher that respects menu choices unless system override (`amlogic.xseries`, `<emu>.vulkan`, `<emu>.fpslimit`).

## Processor Background (Amlogic X Series for LZGAMES)
- X / X1 / X2: Weaker (A53 + older Mali-450 or early G31). Use conservative settings (lower res, more skip, lower threads).
- X3 / X4 (S905X3/SM1/SC2): Stronger (A55 + Bifrost G31 ~2GHz). Better Vulkan support, higher res possible.
- CFLAGS used across emus for compat + perf: `-mtune=cortex-a55 -march=armv8-a+crc+simd -fomit-frame-pointer -O3`.
- Full Vulkan stack exists via custom `libmali-vulkan` package + `vulkan-loader` + `vulkan-tools` + `opengl-meson` (dvalin overlay + libmali.service for g12a/sc2). `VULKAN_SUPPORT="yes"` is set in LZGAMES options + device options.
- Global setting `amlogic.xseries=LZTurboX3` (default). Launcher groups: LZTurboX/X1/X2 = conservative; LZTurboX3/X4/* = optimized.

## The "LZ" System (Core Custom Feature)
Two menus inside emulators (after "Backend"/Graphics API):
- **LZTurbo** (Device Profile): LZTurboX (0), LZTurboX1 (1), LZTurboX2 (2), LZTurboX3 (3), LZTurboX4 (4).
- **LZFramesControl** (FPS Limit): Unlimited (0), 15 (1), 30 (2), 45 (3), 60 (4).

**How it works:**
- Menus save values to emu config (ppsspp.ini, emu.cfg, etc.) as `LZDeviceProfile=N` and `LZMaxFpsLimit=M`.
- Launcher scripts (`ppsspp.sh`, `flycast.sh`, `yabasanshiro.sh`, etc.) run on every launch:
  - Read system overrides first (`get_ee_setting amlogic.xseries`, `<emu>.vulkan`, `<emu>.fpslimit`).
  - Fall back to reading the values saved by the in-emu menus.
  - Apply via sed (resolution, filtering, skip, FrameRate, vidcoretype, RESMODE, etc.).
  - Vulkan forced via `global.vulkan` / `<emu>.vulkan` (sets GraphicsBackend=3 or RendererType=4 or YAB_VIDCORE=4).
- Precedence: system setting > menu choice (for "testar durante uso" while allowing image builders to force profiles).
- Defaults: LZTurboX3 + 60 (or 30 on weak profiles).

This was implemented via source patches (PopupMultiChoice / ImGui BeginCombo / VIDCoreList) + launcher logic + emuelec.conf docs.

## Current State of Emulators (as of last session)

### 1. PPSSPPSDL (PSP Standalone) - Fully updated + custom
- Version: `392a862be20ef90b3bbad2756f50f10f7f36d57e` (recent master with smarter 2D filtering, clipping compat, CrossSIMD, software transform perf, etc.).
- Patches:
  - `06-lz-menus.patch` (core: iLZDeviceProfile/iLZMaxFpsLimit vars + ConfigSetting + PopupMultiChoice in Graphics menu right after Backend. Uses gr->T and ARRAY_SIZE).
  - `08-gles-glfeatures-fix.patch` (GLES headers for clip/cull distances on Amlogic).
  - `09-ffmpeg-avstream-fix.patch` (compat for old ffmpeg in toolchain).
  - `emuelec-paths.patch` (updated to Core/Util/PathUtil.cpp for /storage/roms/savestates/... paths).
  - `PPSSPPSDL-05-fix-fmv-stutter.patch.bak` (disabled due to overlap; if(true) force already present or not critical).
- Launcher: `packages/sx05re/emulators/PPSSPPSDL/scripts/ppsspp.sh` fully updated with PROFILE/FPS/VULKAN logic + cases for LZ profiles (InternalResolution, TextureFiltering, FrameRate, AutoFrameSkip=0, etc.).
- Config: default ppsspp.ini has GraphicsBackend=3 (Vulkan) + comments.
- Build: succeeds with full prefix. Staged to image/usr/bin/PPSSPPSDL + scripts.
- Also updated libretro? (not primary; focus was standalone like user request).

### 2. flycastsa + libretro/flycast (Dreamcast/Naomi/Atomiswave) - Fully updated + custom
- Version: `e4c96293e439a38b10cbe6f9db262500aae3c7d5` (post v2.6 master; linux-aarch64, Vulkan fixes, rend simplifications, game-specific compat, libretro fps reporting).
- Patches (in flycastsa/patches/):
  - `07-lz-menus.patch` (option.h/cpp for LZDeviceProfile/LZMaxFpsLimit + ImGui BeginCombo in settings_video.cpp right after Graphics API. Uses config:: + IM_ARRAYSIZE + ShowHelpMarker. Names exactly "LZTurbo" and "LZFramesControl").
  - Existing 03-sdl.patch still applies.
- libretro/flycast: syncs version via get_pkg_version + NEED_UNPACK from flycastsa. Has its own Vulkan conditional + aarch64 force.
- Launcher: `packages/sx05re/emulators/flycastsa/scripts/flycast.sh` updated with full LZ + Vulkan + PROFILE cases (pvr.AutoSkipFrame, ta.skip, rend.Resolution, aica.LimitFPS, rend.FixedFrequency, pvr.rend=4).
- Also handles old "RendererType" for compat.
- Build: succeeds. Staged.
- Note: libretro core menus are usually via RetroArch (not patched for in-core UI).

### 3. yabasanshiroSA_1_11 (Sega Saturn Standalone - active one) + libretro yabasanshiro
- Standalone active: `yabasanshiroSA_1_11` (PKG_VERSION=a40dace1... on pi4-update fork; retro_arena port for aarch64).
  - Has VIDCORE_VULKAN=4 defined in core (VIDVulkanCInterface.h / VIDVulkan.cpp), but retro_arena port was hardcoded to OGL only.
  - Launcher: `yabasanshiro.sh` (hardcoded -r 2 + HLEBIOS + input.cfg).
- Updates made:
  - package.mk: added VULKAN_SUPPORT conditional (depends + -DYAB_WANT_VULKAN=ON).
  - New patch `05-yabasanshiro-enable-vulkan-lzgames.patch`: adds CVIDVulkan to VIDCoreList (conditional on YAB_WANT_VULKAN), makes vidcoretype settable via `YAB_VIDCORE` env (1=OGL, 4=Vulkan). Also include for header.
  - Launcher updated: reads yabasanshiro.vulkan/global.vulkan → YAB_VIDCORE; amlogic.xseries → RESMODE (1 for weak profiles, 2 for strong); yabasanshiro.fpslimit → adjust res/skip. Passes env + -r $RESMODE.
  - emuelec.conf: added docs for the settings.
- libretro yabasanshiro: updated PKG_VERSION to recent `f448097b69a6037246a08e9dc09eabaa420d7893` (yabasanshiro branch). Added Vulkan depends.
- Build: succeeded after patches. Staged (yabasanshiro + .sh).
- Limitation: retro_arena port is GLES-heavy; Vulkan mainly enables VIDCORE 4 + nanovg Vulkan OSD. -r flag is resolution mode, not vidcore.

### 4. RetroArch (main + lib32) - Latest compatible
- Main: `packages/sx05re/libretro_base/retroarch/package.mk` updated to `5ac03f1116c7c948e485e8b72e3976b5e7d1798b` (current HEAD at time of update; includes recent translations, menu, core, perf work).
  - Patches updated/port ed: 04-enablecontent (Lakka removal in new code locations), 05-cpu-perf-label-fix (MENU_..._STR → base label to fix undeclared in Amlogic build).
  - Additional seds in pre_configure_target for CPU_PERF label + ffmpeg gles2 block (#if 0 the ms_fbo blit/invalidate) + GL defines (RG_INTEGER etc.) + hwfft wrappers.
  - Configure: `--disable-ffmpeg` for Amlogic-ng (and slang/glslang in some contexts) to avoid GLES3 enum + link errors (glBlitFramebuffer, glInvalidateFramebuffer, GL_RG_INTEGER, hwfft_* etc. not declared in toolchain GLES2 headers). Other features (slang etc.) disabled where they pulled missing 32/64 libs.
- lib32-retroarch: syncs version. Has own unpack (tar from sources) + its configure with disables + sed for label.
- Other: retroarch-assets at recent 2d24ef2 (no change needed).
- Patches applied during unpack (with offsets/fuzz handled by updates). Build succeeds for both 64-bit and lib32 (with "retroarch ok").
- Staged: retroarch + retroarch32.
- Config: emuelec.conf has global.retroarch.* mentions; no major breakage from version bump.
- Note: lib32 uses 32-bit toolchain and has extra disables to avoid glslang/SPIRV link fails.

### 5. Supporting Infrastructure (Vulkan + LZGAMES)
- Vulkan: `libmali-vulkan` package (Bifrost G31 libmali.so + mali.json ICD), conditional deps in emuelec + opengl-meson, service + overlay setup for g12a/sc2. VULKAN_SUPPORT="yes" in distributions/LZGAMES/options and device options.
- Global settings live in emuelec.conf (amlogic.xseries=LZTurboX3 default, <emu>.vulkan=0, <emu>.fpslimit=0, docs for all).
- Launchers always source /etc/profile and use get_ee_setting + sed on user config files.
- Patches dirs: flycastsa/patches/, PPSSPPSDL/patches/, yabasanshiroSA_1_11/patches/, retroarch/patches/ (Amlogic subdirs where needed).
- Always verify: strings in binary for "LZTurbo", "LZFramesControl", "YAB_VIDCORE", etc.; ls image/usr/bin/*emu*; run with full prefix.

## How to Continue (Standard Workflow for Future Updates)
1. User says "update <emu>" or "crie mesmos no <emu>" or "atualizar para ultima...".
2. cd /home/pc/Documentos/EmuELEC (always).
3. Inspect current package.mk for version + patches + launcher.
4. Use `git ls-remote https://github.com/... HEAD` (or shallow clone in /tmp) to pick "ultima versão" (prefer recent master or stable tag that has perf/compat/Vulkan mentions).
5. Bump PKG_VERSION (and PKG_GIT_CLONE_BRANCH if needed). Update lib32 if it syncs.
6. Thorough clean of old ver (build/, install_pkg/, sources/ for that ver, locks).
7. Run full `DISTRO=... ./scripts/build <pkg>` (expect patch failures on our LZ/Vulkan/custom patches).
8. In new build.LZGAMES-.../build/<pkg>-newver/:
   - Read the UI/Config/launcher source files.
   - Use search_replace (or multiple) to port our custom code (exact menu names, env vars like YAB_VIDCORE, profile cases for res/skip/fps, Vulkan conditionals).
   - For patches: edit, then `(cd $builddir && git diff file1 file2 ... > /tmp/new.patch)` or manual unified diff. Overwrite `packages/.../patches/NN-ourfeature.patch`.
9. Update the `<pkg>/scripts/<launcher>.sh` with the full LZ/Vulkan/profile/FPS block (copy pattern from ppsspp.sh or flycast.sh as template; adapt keys like -r, vidcoretype, RendererType, etc.).
10. Update emuelec.conf with docs + default settings.
11. (Optional but recommended) Update other related (libretro version of same emu, assets if changed).
12. Re-run the full DISTRO build command.
13. Stage: cp from install_pkg/.../usr/bin/* and /usr/config/... into image/usr/bin + image/usr/config (and image/system if needed).
14. Verify: strings binary | grep LZ or our custom text; ls image/...; check that patches/ now has updated files; optionally test syntax (bash -n launcher).
15. If lib32 involved (like retroarch), build it separately and stage retroarch32.
16. If full image needed: run the make image command (can be long; use background + monitor if in tool env).
17. Document in this file or a new section.
18. Use todo_write if the update has 4+ distinct steps.

## Key Files to Always Touch on Emulator Updates
- packages/sx05re/emulators/<pkg>/package.mk (version, VULKAN_SUPPORT if, depends, cmake opts, pre_*/post_* for seds).
- packages/sx05re/emulators/<pkg>/patches/*.patch (our custom LZ + compat; keep numbering sensible, update existing when source changes).
- packages/sx05re/emulators/<pkg>/scripts/<launcher>.sh (the heart of LZGAMES behavior).
- packages/sx05re/emuelec/config/emuelec/configs/emuelec.conf (docs + defaults).
- For libretro variants: packages/sx05re/libretro/<pkg>/package.mk (often syncs version + adds vulkan dep).
- For lib32: packages/lib32/emuelec/.../lib32-<pkg>/package.mk (unpack tar + own configure + seds).
- build.LZGAMES-.../image/ (for staging verification; never commit these).

## Open / Next Possible Work (as of last session)
- Full `make image` with all updated emus + RetroArch to produce final LZGAMES distro image.
- Test on real hardware (X3/X4 preferred) the Vulkan + LZ profiles + FPS for Saturn/PSP/DC.
- If user requests: similar treatment for other emus (mupen, dolphin, etc.) or more Saturn (beetle-saturn libretro update + its own launcher logic).
- If RetroArch update introduced menu/config breakage, additional seds or patches in post_unpack.
- Keep 05-fmv-stutter.bak or revive if needed for PSP.
- Monitor for new "malformed patch" or "implicit GL" when bumping RA/cores in future (use seds in package.mk as fallback when patch formatting is fragile).
- The 1_5 Saturn package is legacy—ignore unless user specifically asks.

## Example "crie mesmos no <emu>" or "atualizar" Command Sequence (from history)
```bash
cd /home/pc/Documentos/EmuELEC
# inspect
cat packages/sx05re/emulators/<pkg>/package.mk
# bump version (after ls-remote)
# clean
rm -rf build.LZGAMES-Amlogic-ng.aarch64-4/build/<pkg>-* ... sources/.../<pkg>-old
# build (will show patch fails)
DISTRO=LZGAMES ... ./scripts/build <pkg>
# port in new build dir (use read_file + search_replace)
# generate patches
# update launcher + conf
# re-build + stage
DISTRO=... ./scripts/build <pkg>
# verify
strings build.LZGAMES-.../install_pkg/<pkg>-*/usr/bin/<bin> | grep -E 'LZTurbo|VIDCORE'
ls build.LZGAMES-.../image/usr/bin/<bin>*
```

This file should be read at the start of any new session involving LZGAMES/EmuELEC updates. Append new sections for future work (e.g., "## Session YYYY-MM-DD: <what was done>").

Last updated: around the RetroArch + Saturn + general continuation work (Vulkan + LZ everywhere, patch porting discipline, full DISTRO commands, staging).

Grok: when continuing, start by reading this file with read_file, then use list_dir / grep / read_file to refresh specific packages, then ask the user for the exact next emulator or action if ambiguous. Always prefix builds and stay in the EmuELEC dir.