# TBCCurrencies Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a "Currency" tab to the TBC Anniversary CharacterFrame showing gold, honor/arena points, and all TBC bag-item currencies.

**Architecture:** Single-file addon (`TBCCurrencies.lua`) that injects a 5th tab into CharacterFrame on login. Scans bags for known item IDs and queries honor/arena/gold APIs. No saved variables or external dependencies.

**Tech Stack:** Lua 5.1, WoW TBC Anniversary API (Interface 20505)

---

### Task 1: Project Scaffolding

**Files:**
- Create: `TBCCurrencies.toc`
- Create: `.pkgmeta`
- Create: `.luacheckrc`
- Create: `.github/workflows/release.yml`
- Create: `.github/workflows/luacheck.yml`
- Create: `RELEASE.md`
- Create: `CHANGELOG.md`

**Step 1: Create TOC file**

Create `TBCCurrencies.toc`:
```toc
## Interface: 20505
## Title: TBCCurrencies
## Notes: Adds a Currency tab to the Character frame showing all TBC currencies
## Author: Russel
## Version: @project-version@
## IconTexture: Interface\Icons\INV_Misc_Coin_01

TBCCurrencies.lua
```

Note: No SavedVariables line — this addon doesn't persist data. No OptionalDeps — no external libraries.

**Step 2: Create .pkgmeta**

Create `.pkgmeta`:
```yaml
package-as: TBCCurrencies

manual-changelog:
  filename: CHANGELOG.md
  markup-type: markdown

ignore:
  - images
  - README.md
  - CHANGELOG.md
  - .gitignore
  - .pkgmeta
  - .github
  - "*.svg"
  - "*.png"
  - docs
  - tests
  - .luacheckrc
```

**Step 3: Create .luacheckrc**

Create `.luacheckrc`:
```lua
std = "lua51"
max_line_length = false

globals = {
    "TBCCurrencies",
    "CHARACTERFRAME_SUBFRAMES",
}

read_globals = {
    -- WoW Frame API
    "CreateFrame", "UIParent", "CharacterFrame", "PaperDollFrame",
    "PanelTemplates_SetNumTabs", "PanelTemplates_SetTab",
    "hooksecurefunc", "GameTooltip",

    -- WoW APIs used by this addon
    "GetMoney", "GetHonorCurrency", "GetArenaCurrency", "GetItemCount",
    "GetItemInfo", "UnitFactionGroup",

    -- WoW globals
    "HIGHLIGHT_FONT_COLOR", "GRAY_FONT_COLOR",

    -- Lua globals
    "format", "floor", "mod", "tinsert",

    -- Sound
    "PlaySound",
}

ignore = {
    "211",  -- Unused local variable
    "212",  -- Unused argument
    "213",  -- Unused loop variable
}

exclude_files = {
    ".lua",
    ".luarocks",
    "lua_modules",
}
```

**Step 4: Create GitHub Actions workflows**

Create `.github/workflows/release.yml`:
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Package and Release
        uses: BigWigsMods/packager@v2
        with:
          args: -p CURSEFORGE_PROJECT_ID
        env:
          CF_API_KEY: ${{ secrets.CF_API_KEY }}
          GITHUB_OAUTH: ${{ secrets.GITHUB_TOKEN }}
```

Create `.github/workflows/luacheck.yml`:
```yaml
name: Luacheck

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  luacheck:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Lua
        uses: leafo/gh-actions-lua@v10
        with:
          luaVersion: "5.1"

      - name: Install LuaRocks
        uses: leafo/gh-actions-luarocks@v4

      - name: Install luacheck
        run: luarocks install luacheck

      - name: Run luacheck
        run: luacheck .
```

**Step 5: Create RELEASE.md and CHANGELOG.md**

Create `RELEASE.md`:
```markdown
# Release Checklist

Before each release:

- [ ] Update version in `TBCCurrencies.lua`
- [ ] Update `CHANGELOG.md`
- [ ] Commit with message: `chore(release): bump version to X.Y.Z`
- [ ] Create and push tag: `git tag vX.Y.Z && git push origin vX.Y.Z`

## Version Tagging Rules

Follow [Semantic Versioning](https://semver.org/):

| Type | When to use | Example |
|------|-------------|---------|
| **Major** (X.0.0) | Breaking changes | 1.0.0 → 2.0.0 |
| **Minor** (X.Y.0) | New features, new currencies | 1.0.0 → 1.1.0 |
| **Patch** (X.Y.Z) | Bug fixes, layout tweaks | 1.0.1 → 1.0.2 |

## Tag Format

Always prefix with `v`: `v1.0.0`
```

Create `CHANGELOG.md`:
```markdown
**v1.0.0**

- Initial release
- Adds Currency tab to Character frame
- Tracks gold, honor, arena points, badges, BG marks, world PvP tokens, and faction tokens
```

**Step 6: Commit scaffolding**

```bash
git add TBCCurrencies.toc .pkgmeta .luacheckrc .github/ RELEASE.md CHANGELOG.md
git commit -m "chore: add project scaffolding (TOC, pkgmeta, luacheck, CI, changelog)"
```

---

### Task 2: Core Addon — Tab Injection and Empty Panel

**Files:**
- Create: `TBCCurrencies.lua`

**Step 1: Write the tab injection and panel creation code**

Create `TBCCurrencies.lua` with:
- Currency data table (all item IDs, names, icons, sections)
- `PLAYER_LOGIN` handler that creates the tab and panel
- Hook into `CharacterFrameTab_OnClick`
- Empty panel frame registered in `CHARACTERFRAME_SUBFRAMES`

```lua
local addon = CreateFrame("Frame")
local panel -- our currency panel
local tabID

-- Currency definitions: { itemID, name, icon }
-- Icons use standard inventory icon paths
local CURRENCIES = {
    {
        header = "Money",
        type = "money",
    },
    {
        header = "PvP",
        type = "points",
        currencies = {
            { id = "honor", name = "Honor Points", icon = "Interface\\Icons\\PVPCurrency-Honor-Alliance" },
            { id = "arena", name = "Arena Points", icon = "Interface\\Icons\\PVPCurrency-Conquest-Horde" },
        },
    },
    {
        header = "PvE",
        currencies = {
            { id = 29434, name = "Badge of Justice", icon = "Interface\\Icons\\INV_Jewelry_Talisman_08" },
        },
    },
    {
        header = "Battleground Marks",
        currencies = {
            { id = 20558, name = "Warsong Gulch", icon = "Interface\\Icons\\INV_Misc_Rune_07" },
            { id = 20559, name = "Arathi Basin", icon = "Interface\\Icons\\INV_Jewelry_Amulet_07" },
            { id = 20560, name = "Alterac Valley", icon = "Interface\\Icons\\INV_Jewelry_Necklace_21" },
            { id = 29024, name = "Eye of the Storm", icon = "Interface\\Icons\\INV_Jewelry_FrostNecklace" },
        },
    },
    {
        header = "World PvP",
        currencies = {
            { id = 26045, name = "Halaa Battle Token", icon = "Interface\\Icons\\Ability_Rogue_Trip" },
            { id = 26044, name = "Halaa Research Token", icon = "Interface\\Icons\\INV_Misc_Token_02" },
            { id = 28558, name = "Spirit Shard", icon = "Interface\\Icons\\INV_Jewelry_FrostNecklace" },
        },
    },
    {
        header = "Faction Tokens",
        currencies = {
            { id = 24245, name = "Glowcap", icon = "Interface\\Icons\\INV_Mushroom_02" },
            { id = 24579, name = "Mark of Honor Hold", icon = "Interface\\Icons\\INV_Misc_Token_01", faction = "Alliance" },
            { id = 24581, name = "Mark of Thrallmar", icon = "Interface\\Icons\\INV_Misc_Token_01", faction = "Horde" },
            { id = 29736, name = "Arcane Rune", icon = "Interface\\Icons\\INV_Enchant_ShardBrilliantSmall" },
            { id = 29735, name = "Holy Dust", icon = "Interface\\Icons\\INV_Enchant_DustIllusion" },
            { id = 34664, name = "Sunmote", icon = "Interface\\Icons\\INV_Misc_Gem_FlameSpessarite_02" },
        },
    },
}

local function CreateTab()
    tabID = CharacterFrame.numTabs + 1
    local tab = CreateFrame("Button", "CharacterFrameTab" .. tabID, CharacterFrame, "CharacterFrameTabButtonTemplate")
    tab:SetID(tabID)
    tab:SetText("Currency")
    tab:SetPoint("LEFT", "CharacterFrameTab" .. (tabID - 1), "RIGHT", -16, 0)
    PanelTemplates_SetNumTabs(CharacterFrame, tabID)
end

local function CreatePanel()
    panel = CreateFrame("Frame", "TBCCurrenciesPanel", CharacterFrame)
    panel:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
    panel:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", 0, 0)
    panel:Hide()

    tinsert(CHARACTERFRAME_SUBFRAMES, "TBCCurrenciesPanel")
end

-- Hook tab click
hooksecurefunc("CharacterFrameTab_OnClick", function(self)
    if self:GetID() == tabID then
        -- Show our panel, hide others
        for _, name in pairs(CHARACTERFRAME_SUBFRAMES) do
            local frame = _G[name]
            if frame then
                if name == "TBCCurrenciesPanel" then
                    frame:Show()
                else
                    frame:Hide()
                end
            end
        end
        PanelTemplates_SetTab(CharacterFrame, tabID)
        -- Update currency data
    end
end)

addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        CreateTab()
        CreatePanel()
    end
end)
```

**Important notes:**
- The tab template name may be `CharacterFrameTabButtonTemplate` or `CharacterFrameTabTemplate` — need to verify in-game. Try `CharacterFrameTabButtonTemplate` first since that's the TBC naming.
- The hook approach: we hook `CharacterFrameTab_OnClick` and manually show/hide rather than relying on `ToggleCharacter` which may not handle custom panels smoothly.

**Step 2: Run luacheck**

```bash
luacheck TBCCurrencies.lua
```

Fix any warnings.

**Step 3: Commit**

```bash
git add TBCCurrencies.lua
git commit -m "feat: add tab injection and empty currency panel"
```

---

### Task 3: Currency Panel UI — Section Headers and Currency Rows

**Files:**
- Modify: `TBCCurrencies.lua`

**Step 1: Add UI builder functions**

Add these functions to `TBCCurrencies.lua` before `CreatePanel`:

- `CreateSectionHeader(parent, text, yOffset)` — Gold-colored text with separator line
- `CreateMoneyRow(parent, yOffset)` — Gold/silver/copper display with coin icons
- `CreateCurrencyRow(parent, currency, yOffset)` — Icon + name + count row

```lua
local ROW_HEIGHT = 20
local HEADER_HEIGHT = 20
local ICON_SIZE = 16
local LEFT_PADDING = 16
local RIGHT_PADDING = 16
local TOP_OFFSET = -72  -- below the CharacterFrame title bar area

local rows = {}  -- track all currency rows for updates

local function CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT_PADDING, yOffset)
    header:SetTextColor(1, 0.82, 0)  -- gold
    header:SetText(text)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    line:SetPoint("RIGHT", parent, "RIGHT", -RIGHT_PADDING, 0)
    line:SetColorTexture(0.6, 0.5, 0.2, 0.5)

    return yOffset - HEADER_HEIGHT
end

local function FormatMoney(copper)
    local gold = floor(copper / 10000)
    local silver = floor(mod(copper, 10000) / 100)
    local cop = mod(copper, 100)
    return format("%d|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", gold, silver, cop)
end

local function CreateMoneyRow(parent, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT_PADDING, yOffset)
    row:SetPoint("RIGHT", parent, "RIGHT", -RIGHT_PADDING, 0)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)

    row.text = text
    row.type = "money"
    rows[#rows + 1] = row

    return yOffset - ROW_HEIGHT
end

local function CreateCurrencyRow(parent, currency, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT_PADDING, yOffset)
    row:SetPoint("RIGHT", parent, "RIGHT", -RIGHT_PADDING, 0)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    icon:SetTexture(currency.icon)
    icon:SetDesaturated(true)  -- default dimmed, updated on refresh

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    nameText:SetText(currency.name)
    nameText:SetTextColor(0.5, 0.5, 0.5)  -- default dimmed

    local countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    countText:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    countText:SetText("0")
    countText:SetTextColor(0.5, 0.5, 0.5)

    row.icon = icon
    row.nameText = nameText
    row.countText = countText
    row.currencyID = currency.id
    row.type = "currency"
    rows[#rows + 1] = row

    return yOffset - ROW_HEIGHT
end
```

**Step 2: Build the panel content in CreatePanel**

After creating the panel frame, iterate `CURRENCIES` and build rows:

```lua
local function CreatePanel()
    panel = CreateFrame("Frame", "TBCCurrenciesPanel", CharacterFrame)
    panel:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
    panel:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", 0, 0)
    panel:Hide()

    tinsert(CHARACTERFRAME_SUBFRAMES, "TBCCurrenciesPanel")

    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", panel, "TOP", 0, -22)
    title:SetText("Currency")

    local playerFaction = UnitFactionGroup("player")
    local yOffset = TOP_OFFSET

    for _, section in ipairs(CURRENCIES) do
        if section.type == "money" then
            yOffset = CreateSectionHeader(panel, section.header, yOffset)
            yOffset = CreateMoneyRow(panel, yOffset)
        else
            yOffset = CreateSectionHeader(panel, section.header, yOffset)
            for _, currency in ipairs(section.currencies) do
                -- Filter faction-specific currencies
                if not currency.faction or currency.faction == playerFaction then
                    yOffset = CreateCurrencyRow(panel, currency, yOffset)
                end
            end
        end

        yOffset = yOffset - 4  -- spacing between sections
    end
end
```

**Step 3: Run luacheck**

```bash
luacheck TBCCurrencies.lua
```

**Step 4: Commit**

```bash
git add TBCCurrencies.lua
git commit -m "feat: add currency panel UI with section headers and rows"
```

---

### Task 4: Data Refresh — Read Currency Counts and Update Display

**Files:**
- Modify: `TBCCurrencies.lua`

**Step 1: Add the UpdateCurrencies function**

```lua
local function UpdateCurrencies()
    if not panel or not panel:IsShown() then return end

    for _, row in ipairs(rows) do
        if row.type == "money" then
            row.text:SetText(FormatMoney(GetMoney()))
        elseif row.type == "currency" then
            local count = 0
            if row.currencyID == "honor" then
                count = GetHonorCurrency()
            elseif row.currencyID == "arena" then
                count = GetArenaCurrency()
            else
                count = GetItemCount(row.currencyID)
            end

            row.countText:SetText(count)

            if count > 0 then
                row.nameText:SetTextColor(1, 1, 1)
                row.countText:SetTextColor(1, 1, 1)
                row.icon:SetDesaturated(false)
            else
                row.nameText:SetTextColor(0.5, 0.5, 0.5)
                row.countText:SetTextColor(0.5, 0.5, 0.5)
                row.icon:SetDesaturated(true)
            end
        end
    end
end
```

**Step 2: Register refresh events and panel OnShow**

Update the event handler and add OnShow to the panel:

```lua
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        CreateTab()
        CreatePanel()
        self:RegisterEvent("BAG_UPDATE")
        self:RegisterEvent("PLAYER_MONEY")
        self:RegisterEvent("HONOR_CURRENCY_UPDATE")
    else
        UpdateCurrencies()
    end
end)
```

In `CreatePanel`, after creating the panel frame, add:

```lua
panel:SetScript("OnShow", UpdateCurrencies)
```

**Step 3: Run luacheck**

```bash
luacheck TBCCurrencies.lua
```

**Step 4: Commit**

```bash
git add TBCCurrencies.lua
git commit -m "feat: add currency data refresh on events and panel show"
```

---

### Task 5: Update CLAUDE.md for TBCCurrencies

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Replace the header and remove Castborn-specific content**

Replace line 1-3 with TBCCurrencies identity. Delete everything from the `ADDON-SPECIFIC SECTION` comment (line 318) onwards. Add TBCCurrencies-specific section:

```markdown
# TBCCurrencies

WoW TBC Anniversary Classic addon that adds a Currency tab to the Character frame.
```

Add at the bottom (after the General Behavior section):

```markdown
<!-- ============================================================
     ADDON-SPECIFIC SECTION
     Everything below is specific to THIS addon.
     Replace or remove when copying to a new repo.
     ============================================================ -->

## TBCCurrencies Architecture

Single-file addon. No module system, no saved variables, no external dependencies.

- **TBCCurrencies.lua** — All addon logic: tab injection, panel UI, currency data, refresh.
- **TBCCurrencies.toc** — Addon metadata.

### How It Works

1. On `PLAYER_LOGIN`, creates a new tab on `CharacterFrame` and a content panel.
2. Panel is registered in `CHARACTERFRAME_SUBFRAMES` so Blizzard's frame show/hide works.
3. `CharacterFrameTab_OnClick` is hooked to handle our tab selection.
4. Currency counts are read from `GetMoney()`, `GetHonorCurrency()`, `GetArenaCurrency()`, and `GetItemCount(itemID)`.
5. Display refreshes on `BAG_UPDATE`, `PLAYER_MONEY`, `HONOR_CURRENCY_UPDATE`, and panel show.

### Currency Data

All currency item IDs are defined in the `CURRENCIES` table at the top of `TBCCurrencies.lua`. To add a new currency, add an entry with `{ id = itemID, name = "Name", icon = "Interface\\Icons\\IconName" }` to the appropriate section.

Faction-specific currencies use `faction = "Alliance"` or `faction = "Horde"` and are filtered at panel creation time.

## TBCCurrencies File Structure

\`\`\`
TBCCurrencies.toc          # Addon metadata
TBCCurrencies.lua          # All addon logic
CHANGELOG.md               # Version history
RELEASE.md                 # Release checklist
.pkgmeta                   # BigWigs packager config
.luacheckrc                # Luacheck config
.github/workflows/         # CI workflows
\`\`\`
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for TBCCurrencies"
```

---

### Task 6: Final Luacheck Pass and Icon Verification

**Step 1: Run luacheck on entire project**

```bash
luacheck .
```

Fix any warnings.

**Step 2: Verify all icon paths are valid TBC icons**

Review each icon path in the CURRENCIES table against known TBC icon names. The icons hardcoded in the plan are best-guesses — the actual icons should be verified from item data. Use `GetItemInfo(itemID)` at runtime to get the real icon texture (10th return value). Consider replacing hardcoded icons with runtime `GetItemInfo` lookups.

**Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: luacheck fixes and icon path corrections"
```

---

## Notes for Implementation

- **Tab template name**: Try `CharacterFrameTabButtonTemplate` first. If it doesn't exist in TBC Anniversary, fall back to `CharacterFrameTabTemplate`. This must be tested in-game.
- **Icon textures**: The hardcoded icon paths are educated guesses. A better approach is to call `GetItemInfo(itemID)` at runtime and use the returned texture. This avoids wrong icon paths. For honor/arena which aren't items, keep the hardcoded paths.
- **HONOR_CURRENCY_UPDATE**: Verify this event name exists in TBC Anniversary. Alternative: `HONOR_XP_UPDATE` or `CURRENCY_DISPLAY_UPDATE`.
- **`mod()` vs `%`**: TBC Lua supports both. `mod()` is the WoW global; `%` is standard Lua. Use `%` for clarity but `mod()` is fine.
