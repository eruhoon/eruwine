# 🍷 Eruwine Universal Runtime & Port Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)]()

**Eruwine** is a universal runtime architecture and automated build environment for porting and executing 32-bit and 64-bit Windows games on **ARM64 Linux Handhelds** (ROCKNIX, KNULLI, Batocera, ArkOS, etc.) via **PortMaster**.

Powered by **Box64** CPU dynamic recompiler and **Wine64 New WoW64**, Eruwine allows running x86 Windows binaries with hardware-accelerated **Panfrost Mesa OpenGL** or **DXVK Vulkan** rendering without requiring heavy i386 multiarch system libraries.

---

## ✨ Key Features

- **⚡ Wine64 New WoW64 Architecture**: Runs 32-bit x86 Windows apps in pure 64-bit ARM host memory.
- **🎨 Dual Rendering Engines**: Switch seamlessly between hardware Panfrost Mesa OpenGL (`renderer=gl`) and DXVK Vulkan.
- **🕹️ Declarative `port.conf` System**: Configure any game title, executable name, locale, DLL overrides, and sway focus targets without modifying bash code.
- **🎮 Built-in `keymap.gptk` Input Mapping**: Pre-configured gamepad template with mouse simulation, deadzone scaling, and key remapping.
- **🪟 Sway Wayland Focus Daemon**: Automatically captures, focuses, and fullscreens game windows under Sway / Wayland.
- **📦 Single-Command Build System**: Build release templates to `dist/` with Node.js (`npm run build`).

---

## 🛠️ Development & Build Commands

This project uses **Node.js (v20+)** for building and test automation.

### 1. Run Automated Test Suite
```bash
npm test
# Or: node scripts/test.mjs
```

### 2. Build Release Distribution Package
```bash
npm run build
# Or: node scripts/build.mjs
```
Generates ready-to-copy template files in `dist/eruwine.sh` and `dist/eruwine/`.

---

## 📖 Documentation & Guides

- **[HOW_TO_USE.md](HOW_TO_USE.md)**: Quick start guide for creating game ports.

---

## 📜 License
Licensed under the [MIT License](LICENSE).
