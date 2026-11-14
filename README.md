# 🎯 Arrow Puzzle Pro

<p align="center">
  <img src="android/app/src/main/res/app_icon_512.png" width="140" alt="Arrow Puzzle Pro Logo" style="border-radius: 28px;" />
</p>

<p align="center">
  <b>A Mind-Bending Tap-Away Logic & Spatial Puzzle Game Built with Flutter.</b><br>
  <i>Featuring Dynamic Board Shapes, Cosmic Warp Portals, Procedural Level Generation, and Juicy Haptic Feedback.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-4CAF50" />
  <img src="https://img.shields.io/badge/Author-Shahrukh%20Ahmad%20(@srkamd)-38BDF8?logo=github" />
  <img src="https://img.shields.io/badge/License-MIT-amber" />
</p>

---

## 🌟 Overview

Inspired by the classic arrow puzzle genre, **Arrow Puzzle Pro** elevates the experience beyond flat, generic grids. It brings **dynamic non-square arenas**, **teleporting warp portals**, **combo streak audio progression**, **cloud account sync**, and **100% copyright-free procedural audio synthesis**.

---

## 🚀 Key Features

### 1. 🧠 100% Solvable Reverse Generation Engine
- Unlike random placements that create unsolvable deadlocks, our engine employs **reverse trajectory simulation** from clean solved states.
- Every generated puzzle is mathematically guaranteed to have at least one valid topological clearance path.

### 2. 🌀 Cosmic Warp Portals (Wormholes)
- Introduces paired **Blue (🌀) and Orange (🪐)** Warp Portals.
- Arrows entering Portal A instantly emerge out of Portal B along their heading vector, creating multi-dimensional puzzle logic.

### 3. 🗺️ Non-Square Arena Shapes
- **⏹️ Classic Square Grid** (Dense inner puzzles)
- **✝️ Cross Maze** (Corner cut-outs with central junction)
- **💎 Diamond Arena** (Rhombus shape with diagonal escape routes)
- **🍩 Hollow Donut** (Center core void where arrows cannot pass)

### 4. 🎨 4 Atmospheric Visual Worlds
- **World 1 (Lvl 1–8): Cyber Nebula** — Deep obsidian and galaxy starfields.
- **World 2 (Lvl 9–16): Amber Forge** — Charcoal and glowing molten embers.
- **World 3 (Lvl 17–24): Arctic Glacier** — Frozen navy with cyan crystal shimmer.
- **World 4 (Lvl 25–30+): Emerald Matrix** — High-tech jade green digital pathways.

### 5. 🎵 Copyright-Free Procedural Audio & Combo Streaks
- **100% Royalty-Free & Safe:** Built using an in-memory math-synthesizer generating clean 16-bit PCM WAV waves.
- **Dynamic Combo Pitch:** Success chimes scale musically (*Do, Re, Mi, Fa, Sol, La, Si*) on consecutive correct taps.
- **Distinct Collision Sound:** Heavy elastic thud with impact recoil for blocked paths.

### 6. 👤 Player Profile & Cloud Record
- Sign in with **Google Account** or **Email** to back up your progress.
- Tracks **Total Levels Cleared**, **Stars Collected (up to 90 ⭐)**, and **Coins Balance**.
- Global Tier progression: *Novice ➔ Strategist ➔ Master*.

### 7. 🛠️ In-Game Boosters
- 🔨 **Smash Hammer:** Instantly blasts any blocking arrow or rock obstacle.
- 🔄 **Rotate Tool:** Turns any arrow 90° clockwise to forge new escape corridors.
- 💡 **Topological Hint:** Scans the board state and pulses the next free arrow.
- ↩️ **Undo:** Reverts steps safely.

---

## 📁 Architecture & Code Structure

```
arrow_puzzle_flutter/
├── pubspec.yaml                     # Dependencies & metadata
├── android/                         # Native Android project configuration
│   └── app/src/main/res/            # Custom app icon mipmaps & launcher configs
└── lib/
    ├── main.dart                    # Application bootstrap & portrait lock
    ├── models/
    │   └── arrow_model.dart         # GridTile, ArrowDirection, MapShape models
    ├── engine/
    │   └── game_engine.dart         # Raycaster, Reverse Generator, Portal Warping
    ├── services/
    │   ├── sound_service.dart       # Procedural WAV Synthesizer (Zero Copyright)
    │   ├── auth_service.dart        # User profile & Google/Email Auth state
    │   └── storage_service.dart     # SharedPreferences persistence
    ├── widgets/
    │   └── arrow_tile.dart          # Rocket zoom, Elastic shake & Portal shaders
    └── screens/
        ├── home_screen.dart         # Main menu, World status, Quick profile
        ├── level_select_screen.dart # 30-level interactive map
        ├── game_screen.dart         # Arena HUD, Boosters tray, Floating combo
        ├── profile_screen.dart      # Cloud profile & Achievement stats
        └── developer_screen.dart    # Creator bio (@srkamd) & featured projects
```

---

## 🛠️ How to Run Locally

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- Connected Android Device or Emulator

### Steps
```bash
# 1. Clone the repository
git clone https://github.com/srkamd/arrow-puzzle-pro.git
cd arrow-puzzle-pro

# 2. Fetch packages
flutter pub get

# 3. Run on connected device or Chrome
flutter run

# 4. Build Test APK
flutter build apk --debug
```

The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 📱 Google Play Store Release (Signing Safe)

To generate a signed bundle for the Google Play Console:

1. Create a `key.properties` file in `android/` (this file and keystores are strictly **git-ignored**):
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=<your-key-alias>
   storeFile=<path-to-your-keystore-file>
   ```

2. Build the production App Bundle:
   ```bash
   flutter build appbundle --release
   ```

3. Upload the resulting `.aab` file from `build/app/outputs/bundle/release/` directly to your Google Play Console!

---

## 👨‍💻 Creator & Author

**Shahrukh Ahmad**
- 🐙 GitHub: [@srkamd](https://github.com/srkamd)
- 💼 Projects: [FB4K-StreamEngine](https://github.com/srkamd/FB4K-StreamEngine) • [MyLogoQR](https://github.com/srkamd/mylogoqr)
- 📬 Contact: Available via GitHub profile

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
Feel free to fork, customize, and build your own spatial logic games!
