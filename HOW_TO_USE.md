# 📖 How to Create New Game Ports with Eruwine Framework

This guide explains how to quickly port any Windows x86/x64 game to Linux ARM64 handheld devices (ROCKNIX, KNULLI, Batocera, ArkOS) using the **Eruwine Universal Port Framework**.

---

## 🚀 Quick Start Guide

### Step 1: Build the Template Distribution
On your computer or development environment, run:
```bash
npm run build
```
This creates a fresh distribution in the `dist/` directory containing:
- `dist/eruwine.sh` (Launcher script)
- `dist/eruwine/` (Port payload directory)

---

### Step 2: Create Your Game Port Directory
Choose a short unique name for your game (e.g. `fate-stay-night` or `toheart2`).

Copy the template from `dist/` to your target ports location (e.g., `/roms/ports/`):

```bash
# Example: Porting "fate-stay-night"
cp dist/eruwine.sh /roms/ports/eruwine-fate.sh
cp -r dist/eruwine /roms/ports/eruwine-fate
```

---

### Step 3: Add Game Executable & Assets
Copy your Windows game installation files into the `game/` subdirectory:

```
/roms/ports/eruwine-fate/
├── port.conf
├── keymap.gptk
├── game/
│   ├── Fate.exe          <-- Your game executable
│   ├── data.xp3          <-- Game data archives / DLLs
│   └── plugins/
```

---

### Step 4: Configure `port.conf`
Open `/roms/ports/eruwine-fate/port.conf` in any text editor and edit the configuration fields:

```ini
# Display Name
GAME_NAME="Fate/stay night"

# Port Process ID
GAME_ID="fate"

# Executable name inside game/ folder
GAME_EXE="Fate.exe"

# Rendering Backend ("gl" for Panfrost Mesa OpenGL, "vulkan" for DXVK Vulkan)
WINE_RENDERER="gl"

# System Locale
LOCALE="ja_JP.UTF-8"

# Sway Wayland Focus Target
SWAY_FOCUS_TARGETS=("Fate.exe" "Fate/stay night")

# Wineprefix storage folder name
WINE_PREFIX_NAME="fate"
```

---

### Step 5: Customize Gamepad Controls (`keymap.gptk`)
Edit keybindings in `keymap.gptk` to match your game's controls:
```ini
back = pageup
start = esc
a = mouse_left
b = mouse_right
x = space
y = leftctrl
```

---

### Step 6: Launch & Enjoy!
Run your launcher script (`/roms/ports/eruwine-fate.sh`) from PortMaster or EmulationStation. Real-time diagnostic logs will be written to `/roms/ports/eruwine-fate/log.txt`!
