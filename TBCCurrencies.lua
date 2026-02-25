-- TBCCurrencies: Adds a Currency tab to the Character frame
-- Shows all TBC currencies in a sectioned panel

local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local ROW_HEIGHT = 20
local HEADER_HEIGHT = 20
local ICON_SIZE = 16
local LEFT_PADDING = 16
local RIGHT_PADDING = 16
local TOP_OFFSET = -72

-- Currency data table
local CURRENCIES = {
    {
        section = "Money",
        currencies = {
            { name = "Gold", type = "money", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        },
    },
    {
        section = "PvP",
        currencies = {
            { name = "Honor Points", type = "points", id = "honor", icon = "Interface\\Icons\\PVPCurrency-Honor-Alliance" },
            { name = "Arena Points", type = "points", id = "arena", icon = "Interface\\Icons\\PVPCurrency-Conquest-Horde" },
        },
    },
    {
        section = "PvE",
        currencies = {
            { name = "Badge of Justice", type = "item", itemID = 29434 },
        },
    },
    {
        section = "Battleground Marks",
        currencies = {
            { name = "Warsong Gulch", type = "item", itemID = 20558 },
            { name = "Arathi Basin", type = "item", itemID = 20559 },
            { name = "Alterac Valley", type = "item", itemID = 20560 },
            { name = "Eye of the Storm", type = "item", itemID = 29024 },
        },
    },
    {
        section = "World PvP",
        currencies = {
            { name = "Halaa Battle Token", type = "item", itemID = 26045 },
            { name = "Halaa Research Token", type = "item", itemID = 26044 },
            { name = "Spirit Shard", type = "item", itemID = 28558 },
        },
    },
    {
        section = "Faction Tokens",
        currencies = {
            { name = "Glowcap", type = "item", itemID = 24245 },
            { name = "Mark of Honor Hold", type = "item", itemID = 24579, faction = "Alliance" },
            { name = "Mark of Thrallmar", type = "item", itemID = 24581, faction = "Horde" },
            { name = "Arcane Rune", type = "item", itemID = 29736 },
            { name = "Holy Dust", type = "item", itemID = 29735 },
            { name = "Sunmote", type = "item", itemID = 34664 },
        },
    },
}

local panel
local rows = {}
local tabID

-- Format copper amount into colored gold/silver/copper string
local function FormatMoney(copper)
    local gold = floor(copper / 10000)
    local silver = floor(mod(copper, 10000) / 100)
    local copperRem = mod(copper, 100)
    return format(
        "|cFFFFD700%d|rg |cFFC0C0C0%d|rs |cFFCC7722%d|rc",
        gold, silver, copperRem
    )
end

-- Get the icon texture for an item, falling back if not cached
local function GetItemIcon(itemID)
    local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
    return texture or FALLBACK_ICON
end

-- Try to resolve any fallback icons with real item icons
local function ResolveIcons()
    for _, row in ipairs(rows) do
        if row.currency and row.currency.type == "item" and row.currency.itemID then
            local icon = GetItemIcon(row.currency.itemID)
            if icon ~= FALLBACK_ICON then
                row.icon:SetTexture(icon)
            end
        end
    end
end

-- Create a section header with separator line
local function CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT_PADDING, yOffset)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -RIGHT_PADDING, yOffset)
    header:SetTextColor(1, 0.82, 0)
    header:SetText(text)
    header:SetJustifyH("LEFT")

    local separator = parent:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    separator:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    separator:SetHeight(1)
    separator:SetColorTexture(0.6, 0.5, 0.2, 0.5)

    return yOffset - HEADER_HEIGHT
end

-- Create a money display row
local function CreateMoneyRow(parent, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT_PADDING, yOffset)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -RIGHT_PADDING, yOffset)
    row:SetHeight(ROW_HEIGHT)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    text:SetJustifyH("LEFT")

    row.icon = icon
    row.text = text
    row.type = "money"

    return row, yOffset - ROW_HEIGHT
end

-- Create a currency display row (icon + name + count)
local function CreateCurrencyRow(parent, currency, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT_PADDING, yOffset)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -RIGHT_PADDING, yOffset)
    row:SetHeight(ROW_HEIGHT)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    icon:SetSize(ICON_SIZE, ICON_SIZE)

    -- Set icon texture
    if currency.type == "item" then
        icon:SetTexture(GetItemIcon(currency.itemID))
    else
        icon:SetTexture(currency.icon or FALLBACK_ICON)
    end

    -- Dim by default
    icon:SetDesaturated(true)

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    nameText:SetTextColor(0.5, 0.5, 0.5)
    nameText:SetText(currency.name)
    nameText:SetJustifyH("LEFT")

    local countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countText:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    countText:SetTextColor(0.5, 0.5, 0.5)
    countText:SetText("0")
    countText:SetJustifyH("RIGHT")

    row.icon = icon
    row.nameText = nameText
    row.countText = countText
    row.currency = currency

    return row, yOffset - ROW_HEIGHT
end

-- Update all currency counts
local function UpdateCurrencies()
    if not panel or not panel:IsShown() then return end

    for _, row in ipairs(rows) do
        if row.type == "money" then
            row.text:SetText(FormatMoney(GetMoney()))
        elseif row.currency then
            local count = 0
            local curr = row.currency

            if curr.type == "points" and curr.id == "honor" then
                count = GetHonorCurrency()
            elseif curr.type == "points" and curr.id == "arena" then
                count = GetArenaCurrency()
            elseif curr.type == "item" and curr.itemID then
                count = GetItemCount(curr.itemID)
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

-- Create the tab on the CharacterFrame
local function CreateTab()
    local numTabs = CharacterFrame.numTabs + 1
    tabID = numTabs

    local tab = CreateFrame("Button", "CharacterFrameTab" .. numTabs, CharacterFrame, "CharacterFrameTabButtonTemplate")
    tab:SetText("Currency")
    tab:SetID(numTabs)

    local prevTab = _G["CharacterFrameTab" .. (numTabs - 1)]
    tab:SetPoint("LEFT", prevTab, "RIGHT", -16, 0)

    PanelTemplates_SetNumTabs(CharacterFrame, numTabs)

    hooksecurefunc("CharacterFrameTab_OnClick", function(self)
        if self:GetID() == tabID then
            -- Hide all other subframes
            for _, frameName in ipairs(CHARACTERFRAME_SUBFRAMES) do
                local frame = _G[frameName]
                if frame and frameName ~= "TBCCurrenciesPanel" then
                    frame:Hide()
                end
            end
            panel:Show()
            PanelTemplates_SetTab(CharacterFrame, tabID)
            PlaySound(841)
        else
            panel:Hide()
        end
    end)
end

-- Build the panel and all currency rows
local function CreatePanel()
    local playerFaction = UnitFactionGroup("player")

    panel = CreateFrame("Frame", "TBCCurrenciesPanel", CharacterFrame)
    panel:SetAllPoints()
    panel:Hide()

    -- Register in CHARACTERFRAME_SUBFRAMES
    tinsert(CHARACTERFRAME_SUBFRAMES, "TBCCurrenciesPanel")

    -- Panel title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", panel, "TOP", 0, -22)
    title:SetText("Currency")

    local yOffset = TOP_OFFSET

    for _, sectionData in ipairs(CURRENCIES) do
        -- Check if section has any visible currencies for this faction
        local hasVisible = false
        for _, curr in ipairs(sectionData.currencies) do
            if not curr.faction or curr.faction == playerFaction then
                hasVisible = true
                break
            end
        end

        if hasVisible then
            yOffset = CreateSectionHeader(panel, sectionData.section, yOffset)

            for _, curr in ipairs(sectionData.currencies) do
                if not curr.faction or curr.faction == playerFaction then
                    if curr.type == "money" then
                        local row
                        row, yOffset = CreateMoneyRow(panel, yOffset)
                        tinsert(rows, row)
                    else
                        local row
                        row, yOffset = CreateCurrencyRow(panel, curr, yOffset)
                        tinsert(rows, row)
                    end
                end
            end
        end
    end

    panel:SetScript("OnShow", function()
        ResolveIcons()
        UpdateCurrencies()
    end)
end

-- Main event handler
local addon = CreateFrame("Frame")
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
