#!/bin/bash
# ==============================================================================
# Eruwine Universal PortMaster Launcher Script
# Runtime: Eruwine (Box64 + Wine64 New WoW64 Architecture)
# Target OS: ROCKNIX / ARM64 Linux Handheld Devices
# ==============================================================================

# --- PortMaster Environment Initialization ---
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt" 2>/dev/null || true
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

get_controls

# --- Directory Resolution ---
# 1. Custom folder name override (Optional: specify port folder name directly)
# PORT_DIR="FARLANDODYSSEY"

PORT_NAME="${PORT_DIR:-$(basename "$0" .sh)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Search candidate locations
GAMEDIR=""
if [ -n "$PORT_DIR" ]; then
  CANDIDATES=("$PORT_DIR")
else
  # Default candidates: exact match, stripped spaces, lowercase, lowercase without spaces
  NAME_NOSPACE="${PORT_NAME// /}"
  NAME_LOWER="$(echo "$PORT_NAME" | tr '[:upper:]' '[:lower:]')"
  NAME_LOWER_NOSPACE="$(echo "$NAME_NOSPACE" | tr '[:upper:]' '[:lower:]')"
  CANDIDATES=("$PORT_NAME" "$NAME_NOSPACE" "$NAME_LOWER" "$NAME_LOWER_NOSPACE")
fi

for cand in "${CANDIDATES[@]}"; do
  if [ -n "$directory" ] && [ -d "/$directory/ports/$cand" ]; then
    GAMEDIR="/$directory/ports/$cand"
    break
  elif [ -d "$SCRIPT_DIR/$cand" ]; then
    GAMEDIR="$SCRIPT_DIR/$cand"
    break
  fi
done

if [ -z "$GAMEDIR" ] || [ ! -d "$GAMEDIR" ]; then
  GAMEDIR="$SCRIPT_DIR/$PORT_NAME"
fi

cd "$GAMEDIR"

# Logging setup: captures stdout and stderr to log.txt in real-time
exec > >(tee "$GAMEDIR/log.txt") 2>&1

# --- Load Configuration ---
CONF_FILE="$GAMEDIR/port.conf"
if [ -f "$CONF_FILE" ]; then
  echo "[INFO] Loading configuration from $CONF_FILE"
  source "$CONF_FILE"
fi

# --- Pre-flight Checks: Game Data Verification & Auto-Discovery ---
TARGET_EXE=""
if [ -n "$GAME_EXE" ] && [ -f "$GAMEDIR/game/$GAME_EXE" ]; then
  TARGET_EXE="$GAME_EXE"
elif [ ${#GAME_EXES[@]} -gt 0 ]; then
  for exe in "${GAME_EXES[@]}"; do
    if [ -f "$GAMEDIR/game/$exe" ]; then
      TARGET_EXE="$exe"
      break
    fi
  done
fi

if [ -z "$TARGET_EXE" ]; then
  # Auto-search for any .exe in game/ directory
  TARGET_EXE=$(ls "$GAMEDIR/game"/*.exe 2>/dev/null | head -n 1 | xargs -n1 basename 2>/dev/null)
fi

if [ -z "$TARGET_EXE" ]; then
  echo "[ERROR] No valid game executable found in $GAMEDIR/game!"
  if [ -n "$ESUDO" ] && [ -f "$controlfolder/harfbuzz_text" ]; then
    $ESUDO "$controlfolder/harfbuzz_text" "${GAME_NAME:-Windows Game}" "Game executable not found in game directory!" 5
  fi
  exit 1
fi

# Fallback Configuration Defaults
GAME_NAME="${GAME_NAME:-${TARGET_EXE%.exe}}"
GAME_ID="${GAME_ID:-$PORT_NAME}"
WINE_RENDERER="${WINE_RENDERER:-gl}"
LOCALE="${LOCALE:-ko_KR.UTF-8}"
DLL_OVERRIDES="${DLL_OVERRIDES:-mscoree,mshtml=;quartz,devenum,wmp=builtin,native;xaudio2_7,xaudio2_0=builtin}"
GPTK_FILE="${GPTK_FILE:-keymap.gptk}"
# WINE_PREFIX_NAME is optional (for legacy global /storage/eruwine-prefixes/ compatibility)
# Default behavior is local portable wineprefix inside $GAMEDIR/wineprefix

echo "=================================================================="
echo "Starting $GAME_NAME via Eruwine Framework"
echo "Date: $(date)"
echo "GAMEDIR: $GAMEDIR"
echo "Target Executable: $TARGET_EXE"
echo "Renderer Mode: $WINE_RENDERER"
echo "Architecture: $(uname -m)"
echo "=================================================================="

# --- Process Cleanup Trap ---
cleanup() {
  echo "[INFO] Cleaning up runtime and input mapper..."
  $ESUDO killall -9 gptokeyb 2>/dev/null || true
  $ESUDO killall -9 box64 2>/dev/null || true
  $ESUDO killall -9 wine 2>/dev/null || true
  $ESUDO killall -9 wineserver 2>/dev/null || true
  systemctl restart oga_events >/dev/null 2>&1 || true
  printf "\033c" > /dev/tty1 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# --- Controller Setup (gptokeyb) ---
GPTK_PATH="$GAMEDIR/$GPTK_FILE"
if [ -f "$GPTK_PATH" ]; then
  if [ -n "$GPTOKEYB" ]; then
    echo "[INFO] Launching gptokeyb with $GPTK_PATH targeting $TARGET_EXE"
    $GPTOKEYB "$TARGET_EXE" -c "$GPTK_PATH" &
  elif command -v gptokeyb >/dev/null 2>&1; then
    echo "[INFO] Launching system gptokeyb with $GPTK_PATH targeting $TARGET_EXE"
    gptokeyb "$TARGET_EXE" -c "$GPTK_PATH" &
  fi
fi

# --- System Compatibility Patches & Mounts ---
# 1. Enforce 64-bit WoW64 mode by masking i386-unix
mkdir -p /storage/empty_dir
grep -q '/usr/lib/wine/i386-unix' /proc/mounts || mount --bind /storage/empty_dir /usr/lib/wine/i386-unix 2>/dev/null || true

# 2. Patch winewayland to prevent clipboard SIGILL crash under Box64
mkdir -p /storage/eruwine-lib
if [ ! -f /storage/eruwine-lib/winewayland.so ]; then
  sed 's/zwlr_data_control_manager_v1/xwlr_data_control_manager_v1/g' /usr/lib/wine/x86_64-unix/winewayland.so > /storage/eruwine-lib/winewayland.so
  chmod +x /storage/eruwine-lib/winewayland.so
fi
grep -q '/usr/lib/wine/x86_64-unix/winewayland.so' /proc/mounts || mount --bind /storage/eruwine-lib/winewayland.so /usr/lib/wine/x86_64-unix/winewayland.so 2>/dev/null || true

# 3. Patch win32u to prevent zombie user_lock deadlock on thread termination under Box64
if [ -f /storage/eruwine-lib/win32u.so ]; then
  grep -q '/usr/lib/wine/x86_64-unix/win32u.so' /proc/mounts || mount --bind /storage/eruwine-lib/win32u.so /usr/lib/wine/x86_64-unix/win32u.so 2>/dev/null || true
fi

# 4. Patch libxkbregistry to fix XML DTD off-by-one parser bug
if [ -f /storage/eruwine-lib/libxkbregistry.so.0 ]; then
  grep -q '/usr/lib/libxkbregistry.so.0' /proc/mounts || mount --bind /storage/eruwine-lib/libxkbregistry.so.0 /usr/lib/libxkbregistry.so.0 2>/dev/null || true
fi

# --- Environment & Library Search Paths ---
export BOX64_LOG=0
export BOX64_DYNAREC=1
export BOX64_DYNAREC_SAFEFLAGS=1
export BOX64_DYNAREC_FASTROUND=1
export BOX64_DYNAREC_FASTNAN=1
export BOX64_DYNAREC_X87DOUBLE=1
export BOX64_DYNAREC_STRONGMEM=1
export BOX64_SHOWSEGV=1

# --- GPU Driver Override (Force Panfrost Mesa on libmali systems) ---
if [ "$WINE_RENDERER" = "gl" ] || [ "$FORCE_PANFROST" = "1" ]; then
  echo "[INFO] Enforcing Panfrost (Mesa) GPU Driver & DRI Backend..."
  export MESA_LOADER_DRIVER_OVERRIDE=panfrost
  export LIBGL_DRIVERS_PATH="/usr/lib/dri"
  export GBM_BACKENDS_PATH="/usr/lib/gbm"
  export GBM_BACKEND="dri"
  export EGL_PLATFORM="wayland"
  [ -d "/usr/lib/mesa" ] && export LD_LIBRARY_PATH="/usr/lib/mesa:$LD_LIBRARY_PATH"
  [ -d "/usr/lib/panfrost" ] && export LD_LIBRARY_PATH="/usr/lib/panfrost:$LD_LIBRARY_PATH"
fi

export BOX64_LD_LIBRARY_PATH="$GAMEDIR/lib:/storage/eruwine-lib:/usr/share/box64/lib:/usr/lib/wine/x86_64-unix:$BOX64_LD_LIBRARY_PATH"
export WINEDLLPATH="$GAMEDIR/bin:/usr/lib/wine/x86_64-windows:/usr/lib/wine/i386-windows:/usr/lib/wine/x86_64-unix"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run/0-runtime-dir}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export SWAYSOCK="${SWAYSOCK:-/var/run/0-runtime-dir/sway-ipc.0.sock}"
export XKB_CONFIG_ROOT="/usr/share/X11/xkb"

# --- Wine Settings & Locale ---
# Default to local portable wineprefix inside GAMEDIR ($GAMEDIR/wineprefix).
# Can be overridden by WINEPREFIX_PATH or legacy WINE_PREFIX_NAME.
if [ -n "$WINEPREFIX_PATH" ]; then
  export WINEPREFIX="$WINEPREFIX_PATH"
elif [ -n "$WINE_PREFIX_NAME" ]; then
  export WINEPREFIX="/storage/eruwine-prefixes/$WINE_PREFIX_NAME"
else
  export WINEPREFIX="$GAMEDIR/wineprefix"
fi
export WINEARCH=win64
export WINEDEBUG="-all"
export LC_ALL="$LOCALE"
export PULSE_SERVER="unix:/var/run/0-runtime-dir/pulse/native"
export WINEDLLOVERRIDES="$DLL_OVERRIDES"

# --- Wineprefix Validation ---
if [ ! -d "$WINEPREFIX/drive_c" ]; then
  echo "[INFO] Initializing Wineprefix at $WINEPREFIX..."
  mkdir -p "$WINEPREFIX"
  wine wineboot -u || true
fi

mkdir -p "$WINEPREFIX/dosdevices"
[ ! -L "$WINEPREFIX/dosdevices/z:" ] && ln -sf / "$WINEPREFIX/dosdevices/z:"
[ ! -L "$WINEPREFIX/dosdevices/d:" ] && ln -sf "$GAMEDIR/game" "$WINEPREFIX/dosdevices/d:"

if [ -d "/usr/lib/wine/i386-windows" ] && [ -d "$WINEPREFIX/drive_c/windows/syswow64" ]; then
  if [ ! -f "$WINEPREFIX/drive_c/windows/syswow64/kernel32.dll" ]; then
    echo "[INFO] Linking i386-windows DLLs to syswow64..."
    ln -sf /usr/lib/wine/i386-windows/* "$WINEPREFIX/drive_c/windows/syswow64/" 2>/dev/null || true
  fi
fi

# Apply Direct3D & Audio configuration in registry
if [ -f "$WINEPREFIX/user.reg" ]; then
  sed -i '/\[Software\\\\Wine\\\\Direct3D\]/,/^$/d' "$WINEPREFIX/user.reg" 2>/dev/null || true
  sed -i '/\[Software\\\\Wine\\\\Drivers\]/,/^$/d' "$WINEPREFIX/user.reg" 2>/dev/null || true
  
  if [ "$WINE_RENDERER" = "gl" ]; then
    cat << 'EOF' >> "$WINEPREFIX/user.reg"

[Software\\Wine\\Direct3D] 1727880000
"CheckFloatConstants"="enabled"
"renderer"="gl"

[Software\\Wine\\Drivers] 1727880000
"Audio"="pulse"
EOF
  else
    cat << 'EOF' >> "$WINEPREFIX/user.reg"

[Software\\Wine\\Direct3D] 1727880000
"renderer"="vulkan"

[Software\\Wine\\Drivers] 1727880000
"Audio"="pulse"
EOF
  fi
fi

# DXVK / WineD3D override handling
if [ "$WINE_RENDERER" = "gl" ]; then
  if [ -f "$GAMEDIR/game/d3d9.dll" ]; then
    mv "$GAMEDIR/game/d3d9.dll" "$GAMEDIR/game/d3d9.dll.dxvk" 2>/dev/null || true
  fi
  if [ -f "/usr/lib/wine/i386-windows/d3d9.dll" ] && [ -d "$WINEPREFIX/drive_c/windows/syswow64" ]; then
    cp -f "/usr/lib/wine/i386-windows/d3d9.dll" "$WINEPREFIX/drive_c/windows/syswow64/d3d9.dll" 2>/dev/null || true
  fi
fi

# --- Sway Fullscreen & Focus Daemon (Automatic Window Resolution) ---
SWAY_TARGETS=("$TARGET_EXE" "${TARGET_EXE%.exe}" "$GAME_NAME" "${SWAY_FOCUS_TARGETS[@]}")
(
  for i in $(seq 1 60); do
    sleep 0.4
    FOCUSED=0
    for target in "${SWAY_TARGETS[@]}"; do
      if [ -n "$target" ]; then
        if swaymsg "[app_id=\"$target\"] fullscreen enable" >/dev/null 2>&1; then
          swaymsg "[app_id=\"$target\"] focus" >/dev/null 2>&1
          echo "[Sway] Focused app_id=$target at attempt $i"
          FOCUSED=1
          break
        elif swaymsg "[title=\"$target\"] fullscreen enable" >/dev/null 2>&1; then
          swaymsg "[title=\"$target\"] focus" >/dev/null 2>&1
          echo "[Sway] Focused title=$target at attempt $i"
          FOCUSED=1
          break
        fi
      fi
    done
    
    # Automatic Fallback: capture any active Wine window
    if [ $FOCUSED -eq 0 ]; then
      if swaymsg '[app_id=".*\.exe"] fullscreen enable' >/dev/null 2>&1; then
        swaymsg '[app_id=".*\.exe"] focus' >/dev/null 2>&1
        echo "[Sway] Focused generic Wine window at attempt $i"
        FOCUSED=1
      elif swaymsg '[class="Wine"] fullscreen enable' >/dev/null 2>&1; then
        swaymsg '[class="Wine"] focus' >/dev/null 2>&1
        echo "[Sway] Focused Wine class window at attempt $i"
        FOCUSED=1
      fi
    fi

    [ $FOCUSED -eq 1 ] && break
  done
) &

# --- Attach gptokeyb virtual keyboard to seat0 (otherwise it lands on the touch fallback seat and Wine gets no key events) ---
(
  for i in $(seq 1 30); do
    sleep 0.5
    if swaymsg -t get_inputs 2>/dev/null | grep -q 'Fake_Keyboard'; then
      swaymsg seat seat0 attach "4660:22136:Fake_Keyboard" >/dev/null 2>&1
      break
    fi
  done
) &

# --- Game Launch ---
echo "[INFO] Switching to game directory: $GAMEDIR/game"
cd "$GAMEDIR/game"

echo "[INFO] Executing: wine $TARGET_EXE"
wine "$TARGET_EXE"

echo "[INFO] Game process terminated normally."
exit 0
