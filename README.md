# 🎭 Gireesam's Great Escape

> *"మై డియర్. నింపాదిగా మాట్లాడు. రేపు ఉదయం ఎనిమిది గంటలకి పూటకూళ్ళమ్మ యింటికి వస్తే అణా."*  
> — Gurajada Apparao, *Kanyasulkam* (1892)

A 2D comic street-escape platformer created with one-shot prompt engineering using **Manus 2.0**, powered by **Godot Engine 4.7** and exported to **WebAssembly (WASM) / HTML5**.

---

## 📖 Story & Premise

Step into the slippers of **Gireesam**, the iconic, smooth-talking, cigarette-puffing, English-quoting tutor from Gurajada Apparao's legendary Telugu play *Kanyasulkam*. 

Having racked up debts across town under the guise of starting a "Social Reform Fund" (and running up unpaid bills at the local boarding house / *pootakoollamma illu*), Gireesam finds himself in a desperate sprint across the streets, market stalls, and temple rooftops of 19th-century Vizianagaram. 

Avoid relentless creditors, collect Reform Fund coins, deploy distractions (hot bajjis, cigarettes, and grand reformist lectures), and navigate through three treacherous stages to reach safety!

---

## ⚡ Quick Start: Play Immediately

A complete, pre-built Web export is included in the [`web-export/`](./web-export) directory. You do **not** need Godot or Node.js installed to play locally.

### Using the Play Script (macOS / Linux)
```bash
./play.sh
```
This automatically starts a local static server and opens `http://localhost:8080` in your default browser.

### Using NPM
```bash
npm run serve
# Then visit http://localhost:8080/ in your browser
```

### Using Python directly
```bash
python3 -m http.server 8080 --directory web-export
# Then visit http://localhost:8080/ in your browser
```

> **Note:** Always use a local HTTP server instead of double-clicking `index.html` via `file://`. Browsers restrict WebAssembly (`.wasm`) and data package (`.pck`) streaming over `file://` protocols.

---

## 🎮 Controls

| Action | Keyboard | Gamepad | Mobile / Touch |
| :--- | :--- | :--- | :--- |
| **Move** | `A` / `D` or `Left` / `Right` | Left Stick / D-Pad | Virtual Joystick drag |
| **Jump / Short Hop** | `Space` or `Up` (release early to cut jump) | South Button (`A` / `✕`) | Joystick upward swipe |
| **Attack / Distraction** | `J` or `X` | West Button (`X` / `□`) | On-screen action button |
| **Pause Menu** | `Esc` | Start / Options | HUD Pause button |
| **Skip Tutorial** | `K` | Back / View | Skip button |

- **Physics & Nuances:** Includes variable jump height, coyote time, jump buffering, enemy bounce/stomping, and dynamic camera framing.
- **Attacks:** Swept collision yarn/distraction projectiles with cooldown and bounce physics.

---

## 🏙️ Stages & Content

| Stage | Name | Distance | Objective |
| :--- | :--- | :--- | :--- |
| **Stage 1** | *Sunlit Nook* | 7,800 px | Learn traversal, jump over hazards, and reach the safe house. |
| **Stage 2** | *Lofty Lounge* | 8,500 px | Collect at least 12 Reform Fund coins to open the safe house exit. |
| **Stage 3** | *Temple Rooftops* | 9,000 px | High-stakes escape across Vizianagaram rooftops dodging chasers. |

- **Reform Fund Coins (`RF`):** +100 points
- **Creditor Neutralized:** +250 points
- **Special Reward Blocks:** +50 points (releases extra coins/items)
- **Time Bonus:** +10 points per whole second remaining upon stage clear

## 📚 Story adaptations

The title screen keeps the standard escape campaign and separate **PLAY ACT I · STORY** through **PLAY ACT VII** routes. Acts II–VII are compact English-language episodes grounded in the 1909 Andhra Bharati witness. Act I remains the Bonkula Dibba / Madhuravani room vertical slice (with an optional Telugu UI pilot line). See `docs/ACT_*_ADAPTATION.md` for witness and adaptation notes.

---

## 🛠️ Project Structure

```
gireesam/
├── web-export/              # Pre-compiled, ready-to-host HTML5/WASM game
│   ├── index.html           # Game launcher with CJK/English loader
│   ├── index.wasm           # Compiled Godot 4.7 WebAssembly engine
│   ├── index.pck            # Packaged game data, scenes, and assets
│   └── index.js             # Web engine glue script
│
├── project.godot            # Godot 4.7 Engine project definition
├── export_presets.cfg       # Godot Web export presets
├── package.json             # NPM scripts for serving and testing
├── play.sh                  # One-click local launcher
│
├── assets/                  # Raw and imported media
│   ├── gireesam/            # Custom Gireesam player and Creditor sprites
│   ├── audio/               # Background satire loops, chase music & Kanyasulkam voice excerpt
│   ├── share/               # Favicon and OpenGraph preview cards
│   └── template/            # Shared platformer UI, fonts, and base SFX
│
├── scenes/                  # Godot Packed Scenes (.tscn)
│   ├── title_screen.tscn    # Title menu, settings, tutorial, and profile
│   └── game.tscn            # Authoritative gameplay run & HUD
│
├── scripts/                 # GDScript gameplay logic
│   ├── player.gd            # Player movement, jumps, combat, and input state
│   ├── entities.gd          # Reform Fund coins, Creditors, Distractions, Reward blocks
│   ├── stage_catalog.gd     # Stage loading, geometry validation, and routing
│   ├── game_audio.gd        # Central music & SFX bus routing
│   ├── touch_input.gd       # Touch joystick and virtual buttons
│   ├── save_store.gd        # Local offline save persistence (`user://save.json`)
│   └── cloud_profile.gd     # Cloud profile synchronization adapter
│
├── data/                    # Level layouts & geometry
│   └── stages/              # JSON definitions for all courses
│
├── autoload/                # Global singletons (I18n, Font themes)
├── localization/            # English (`en.json`) and Chinese (`zh-CN.json`) copy
├── source-references/       # Literary archive references from Kanyasulkam play text
│
├── server/                  # Optional cloud-save & account backend
│   ├── index.mjs            # Express + tRPC entrypoint
│   ├── db.mjs               # Drizzle ORM schema & MySQL repository
│   └── Dockerfile           # Production container for cloud API
│
├── test/                    # Regression & unit tests (Godot & Node)
├── tools/                   # CJK font pipeline & asset build utilities
└── docs/                    # Architecture, design direction, and archive
    ├── design-direction.md  # Aesthetic & UX design guidelines
    ├── cloud-save-plan.md   # Cloud profile & backend data model
    ├── provenance/          # Asset licensing & template provenance records
    └── archive/             # Historical generation tickets & export notes
```

---

## 💻 Opening & Developing in Godot

1. Download and install **[Godot Engine 4.7](https://godotengine.org/)** (Standard 64-bit).
2. Launch Godot, click **Import**, and select the [`project.godot`](./project.godot) file at the root of this folder.
3. Click **Import & Edit**.
4. Press `F5` to play directly inside the editor!

---

## 🌐 Deploying to the Web

To host the game online on **GitHub Pages**, **Netlify**, or **Cloudflare Pages**:
1. Point your deployment root to the [`web-export/`](./web-export) folder.
2. The directory must serve `index.html`, `index.js`, `index.wasm`, and `index.pck`.
3. Set the following HTTP headers if your host supports them (for high-performance WebAssembly streaming):
   ```http
   Cross-Origin-Opener-Policy: same-origin
   Cross-Origin-Embedder-Policy: require-corp
   ```

---

## ☁️ Optional Cloud Save Backend

The game is 100% playable offline with progress saved to `user://save.json`.

An optional cross-device account backend is included in [`server/`](./server):
- **Stack:** Node.js 22+, Express 4, tRPC 11, Drizzle ORM, MySQL 8
- **Run migrations:** `npm --prefix server run db:migrate`
- **Start server:** `npm --prefix server start`

---

## 📜 Credits & Provenance

- **Literary Source:** Inspired by Gurajada Apparao's public-domain Telugu drama *Kanyasulkam* (1892).
- **Archival Audio Excerpt:** [Internet Archive — Kanyasulkam](https://archive.org/details/kanyasulkam_gurajada_apparao)
- **Built with:** [Manus 2.0](https://manus.im) in a single-shot generation session.
- **Engine:** [Godot Engine](https://godotengine.org) (MIT License).
- **Fonts:** *Baloo 2* (OFL), *Nunito* (OFL), *Noto Sans SC* (OFL).
