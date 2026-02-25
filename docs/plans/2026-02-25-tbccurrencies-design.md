# TBCCurrencies Design

## Overview

A WoW TBC Anniversary Classic addon that adds a "Currency" tab (5th tab) to the CharacterFrame. Displays a complete overview of the current character's currencies: Gold, Honor/Arena Points, and all TBC bag-item currencies.

## Architecture

**Single file** — `TBCCurrencies.lua` plus `TBCCurrencies.toc`. No external libraries, no saved variables, no module system.

**Tab injection** — On `PLAYER_LOGIN`:
1. Create `CharacterFrameTab5` using `CharacterFrameTabTemplate`
2. Position it to the right of Tab 4
3. Register `TBCCurrenciesPanel` in `CHARACTERFRAME_SUBFRAMES`
4. Hook `CharacterFrameTab_OnClick` to handle our tab

**Data sources:**
- Gold: `GetMoney()` (returns copper)
- Honor: `GetHonorCurrency()`
- Arena: `GetArenaCurrency()`
- Bag items: `GetItemCount(itemID)` for each known currency

**Refresh events:** `BAG_UPDATE`, `HONOR_CURRENCY_UPDATE`, `PLAYER_MONEY`, plus on panel show.

## Currency List

### Money
- Gold / Silver / Copper (from `GetMoney()`)

### PvP Points
- Honor Points (`GetHonorCurrency()`)
- Arena Points (`GetArenaCurrency()`)

### PvE
- Badge of Justice (itemID: 29434)

### Battleground Marks
- Warsong Gulch Mark of Honor (itemID: 20558)
- Arathi Basin Mark of Honor (itemID: 20559)
- Alterac Valley Mark of Honor (itemID: 20560)
- Eye of the Storm Mark of Honor (itemID: 29024)

### World PvP
- Halaa Battle Token (itemID: 26045)
- Halaa Research Token (itemID: 26044)
- Spirit Shard (itemID: 28558)

### Faction Tokens
- Glowcap (itemID: 24245)
- Mark of Honor Hold (itemID: 24579) — Alliance
- Mark of Thrallmar (itemID: 24581) — Horde
- Arcane Rune (itemID: 29736)
- Holy Dust (itemID: 29735)
- Sunmote (itemID: 34664)

## UI Layout

Panel sits inside CharacterFrame (~338x424 usable area). No scrolling needed.

```
+------------------------------------------+
| Currency                                 |
+------------------------------------------+
| MONEY                                    |
| [coin] 123g 45s 67c                     |
|                                          |
| PVP                                      |
| [icon] Honor Points .............. 1,234 |
| [icon] Arena Points ................. 89 |
|                                          |
| PVE                                      |
| [icon] Badge of Justice ............ 42  |
|                                          |
| BATTLEGROUND MARKS                       |
| [icon] Warsong Gulch ............... 20  |
| [icon] Arathi Basin ................ 15  |
| [icon] Alterac Valley .............. 12  |
| [icon] Eye of the Storm ............. 8  |
|                                          |
| WORLD PVP                               |
| [icon] Halaa Battle Token ........... 0  | (dimmed)
| [icon] Halaa Research Token ......... 0  | (dimmed)
| [icon] Spirit Shard ................. 3  |
|                                          |
| FACTION TOKENS                           |
| [icon] Glowcap ..................... 14  |
| [icon] Mark of Honor Hold .......... 0   | (dimmed, Alliance only shown for Alliance)
| [icon] Arcane Rune .................. 0  | (dimmed)
| [icon] Holy Dust .................... 0  | (dimmed)
| [icon] Sunmote ...................... 0  | (dimmed)
+------------------------------------------+
```

### Row styling
- Each row: 16x16 icon, name text (left), count (right-aligned)
- Section headers: small gold text with a subtle separator line
- Zero counts: grey/dimmed text and desaturated icon
- Non-zero counts: white text, full-color icon
- Faction-specific items (Mark of Honor Hold vs Mark of Thrallmar) filtered by player faction

## File Structure

```
TBCCurrencies.toc
TBCCurrencies.lua
CHANGELOG.md
.pkgmeta
.luacheckrc
.github/workflows/release.yml
.github/workflows/luacheck.yml
RELEASE.md
```

## Not In Scope

- Alt tracking / cross-character data
- Saved variables
- Options panel / configuration
- Session tracking (gain/loss over time)
- Tooltip details on hover (can add later)
