# KOReader Line Hints

A KOReader plugin for keyboard-style e-readers (tested on Kindle Keyboard / K3) that adds letter badges next to visible text lines. Press a single letter to jump the highlight cursor to that line, then use the D-pad to move word-by-word and line-by-line.

## Features

- **Left-margin letter badges** for the first 26 visible lines (`Q`–`M`, matching the File Manager shortcut layout).
- **`Alt + L` toggle** to show or hide the badges.
- **Single-key line jumps**: press the badge letter to move the cursor to the first word of that line.
- **Word-by-word movement**: D-pad `Left` / `Right` jumps to the previous / next word on reflowable documents.
- **Line-by-line movement**: D-pad `Up` / `Down` jumps to the previous / next visible line.
- **Vertical bar cursor** (`|`) instead of the default crosshair (`+`).
- **Reflowable documents only**: MOBI, EPUB, AZW3, etc. PDF is not supported.

## Requirements

- KOReader **v2025.04** or a compatible version (patches may need adjustment for other versions).
- A device with a physical keyboard and/or D-pad (e.g., Kindle Keyboard, Kindle 4).
- The `patch` utility available on the computer used for installation.
- Enough left margin to fit the badges. A left margin of at least **22 px** (after scaling) is recommended.

## Installation

This plugin needs two small changes to KOReader core files in addition to the plugin itself.

### Option 1: Run the install script

With the Kindle attached to a computer (or via SSH), run:

```sh
./install.sh /path/to/koreader
```

If the script can auto-detect your Kindle, you can simply run:

```sh
./install.sh
```

The script backs up the original KOReader files before patching them.

### Option 2: Apply patches manually

```sh
cd /path/to/koreader
patch -p0 < /path/to/koreader-linehints/patches/readerview.lua.patch
patch -p0 < /path/to/koreader-linehints/patches/readerhighlight.lua.patch
cp -r /path/to/koreader-linehints/linehints.koplugin plugins/
```

Or apply both patches at once:

```sh
cd /path/to/koreader
patch -p0 < /path/to/koreader-linehints/patches/all_patches.patch
cp -r /path/to/koreader-linehints/linehints.koplugin plugins/
```

## Usage

1. Open a reflowable book (MOBI/EPUB).
2. Make sure the **left margin is wide enough** for badges. You can adjust it in the bottom menu: **Typography → Page margins** or **Status bar → Alt status bar** settings.
3. Press **`Alt + L`** to show the line letter badges.
4. Press the letter shown next to the line you want (e.g., `Y`). The cursor jumps to the first word of that line.
5. Use the D-pad to move:
   - `Left` / `Right` = previous / next word
   - `Up` / `Down` = previous / next line
6. Press **`Alt + L`** again to hide the badges.

## Files modified in KOReader

| File | Change |
|------|--------|
| `frontend/apps/reader/modules/readerview.lua` | `drawHighlightIndicator()` now draws a vertical bar cursor instead of a crosshair. |
| `frontend/apps/reader/modules/readerhighlight.lua` | `onMoveHighlightIndicator()` uses semantic word/line movement for reflowable documents; helper methods `getVisibleLineBoxes()`, `snapIndicatorToBox()`, `moveIndicatorByWord()`, and `moveIndicatorByLine()` added. |

See `patches/` for the exact diffs.

## Uninstall / restore originals

The install script creates a timestamped backup directory inside your KOReader folder, for example:

```
koreader/.linehints-backups-20260928-221100/
```

Copy the backed-up files back to their original locations and delete `plugins/linehints.koplugin/` to remove the plugin.

## Notes and limitations

- Only **reflowable/CREngine documents** are supported. The plugin disables itself on PDF/DjVu.
- Badges are assigned to the first 26 visible lines only (`Q`–`M`).
- If the left margin is too narrow, badges may be clipped or not drawn. Increase the left page margin.
- The center D-pad button currently behaves like the default KOReader highlight button (select word, then show options). A single-press dictionary lookup can be added as a future improvement.

## Repository contents

```
koreader-linehints/
├── README.md
├── install.sh
├── linehints.koplugin/          # the plugin
│   ├── _meta.lua
│   └── main.lua
└── patches/                     # KOReader core modifications
    ├── all_patches.patch
    ├── readerview.lua.patch
    └── readerhighlight.lua.patch
```

No complete KOReader files are included — only the plugin and the minimal patches needed to modify a stock KOReader install.

## License

The plugin code is provided as-is for personal use. KOReader itself is licensed under the AGPLv3; the patch files describe changes to files that remain under their original license.
