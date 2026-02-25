-- TBCCurrencies: Adds a Currency tab to the Character frame
-- Shows all TBC currencies in a sectioned panel

local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local ROW_HEIGHT = 20
local HEADER_HEIGHT = 20
local ICON_SIZE = 16
local LEFT_PADDING = 16
local RIGHT_PADDING = 16
local TOP_OFFSET = -72

-- Currency IDs for honor/arena (used with C_CurrencyInfo)
local HONOR_CURRENCY_ID = 1901
local ARENA_CURRENCY_ID = 1900

-- Currency data table
local CURRENCIES = {
    {
        section = "Money",
        currencies = {
            { name = "Gold", type = "money", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        },
    },
    {
        section = "PvE",
        currencies = {
            { name = "Badge of Justice", type = "item", itemID = 29434 },
        },
    },
    {
        section = "PvP",
        currencies = {
            { name = "Honor Points", type = "currency", currencyID = HONOR_CURRENCY_ID },
            { name = "Arena Points", type = "currency", currencyID = ARENA_CURRENCY_ID },
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
local scrollChild
local rows = {}
local sections = {}
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

-- Try to resolve any fallback icons with real item/currency icons
local function ResolveIcons()
    for _, row in ipairs(rows) do
        if row.currency then
            if row.currency.type == "item" and row.currency.itemID then
                local icon = GetItemIcon(row.currency.itemID)
                if icon ~= FALLBACK_ICON then
                    row.icon:SetTexture(icon)
                end
            elseif row.currency.type == "currency" and row.currency.currencyID then
                local info = C_CurrencyInfo.GetCurrencyInfo(row.currency.currencyID)
                if info and info.iconFileID then
                    row.icon:SetTexture(info.iconFileID)
                end
            end
        end
    end
end

-- Reposition all visible rows after a collapse/expand
local function RelayoutPanel()
    local yOffset = 0

    for _, sec in ipairs(sections) do
        sec.headerFrame:ClearAllPoints()
        sec.headerFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        sec.headerFrame:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        yOffset = yOffset - HEADER_HEIGHT

        if not sec.collapsed then
            for _, row in ipairs(sec.rows) do
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
                row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
                row:Show()
                yOffset = yOffset - ROW_HEIGHT
            end
        else
            for _, row in ipairs(sec.rows) do
                row:Hide()
            end
        end

        yOffset = yOffset - 4
    end

    scrollChild:SetHeight(-yOffset)
end

-- Create a clickable section header with collapse/expand toggle on the right
local function CreateSectionHeader(parent, text, sectionIndex)
    local headerFrame = CreateFrame("Button", nil, parent)
    headerFrame:SetHeight(HEADER_HEIGHT)

    local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("LEFT", headerFrame, "LEFT", LEFT_PADDING, 0)
    header:SetTextColor(1, 0.82, 0)
    header:SetText(text)

    -- Arrow on the right side
    local arrow = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", headerFrame, "RIGHT", -RIGHT_PADDING, 0)
    arrow:SetTextColor(1, 0.82, 0)
    arrow:SetText("v")

    local separator = headerFrame:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    separator:SetPoint("RIGHT", headerFrame, "RIGHT", -RIGHT_PADDING, 0)
    separator:SetHeight(1)
    separator:SetColorTexture(0.6, 0.5, 0.2, 0.5)

    headerFrame:SetScript("OnClick", function()
        local sec = sections[sectionIndex]
        sec.collapsed = not sec.collapsed
        arrow:SetText(sec.collapsed and ">" or "v")
        RelayoutPanel()
    end)

    headerFrame.arrow = arrow
    return headerFrame
end

-- Create a money display row
local function CreateMoneyRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", LEFT_PADDING, 0)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    text:SetJustifyH("LEFT")

    row.icon = icon
    row.text = text
    row.type = "money"

    return row
end

-- Create a currency display row (icon + name + count)
local function CreateCurrencyRow(parent, currency)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", LEFT_PADDING, 0)
    icon:SetSize(ICON_SIZE, ICON_SIZE)

    if currency.type == "item" then
        icon:SetTexture(GetItemIcon(currency.itemID))
    elseif currency.type == "currency" then
        local info = C_CurrencyInfo.GetCurrencyInfo(currency.currencyID)
        icon:SetTexture((info and info.iconFileID) or FALLBACK_ICON)
    else
        icon:SetTexture(currency.icon or FALLBACK_ICON)
    end

    icon:SetDesaturated(true)

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    nameText:SetTextColor(0.5, 0.5, 0.5)
    nameText:SetText(currency.name)
    nameText:SetJustifyH("LEFT")

    local countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countText:SetPoint("RIGHT", row, "RIGHT", -RIGHT_PADDING, 0)
    countText:SetTextColor(0.5, 0.5, 0.5)
    countText:SetText("0")
    countText:SetJustifyH("RIGHT")

    row.icon = icon
    row.nameText = nameText
    row.countText = countText
    row.currency = currency

    return row
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

            if curr.type == "currency" and curr.currencyID then
                local info = C_CurrencyInfo.GetCurrencyInfo(curr.currencyID)
                count = (info and info.quantity) or 0
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

    -- Add our tab to CharacterFrameTab_OnClick by replacing it
    local origOnClick = CharacterFrameTab_OnClick
    CharacterFrameTab_OnClick = function(self, button)
        if self:GetName() == "CharacterFrameTab" .. tabID then
            ToggleCharacter("TBCCurrenciesPanel")
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        else
            origOnClick(self, button)
        end
    end
end

-- Build the panel and all currency rows
local function CreatePanel()
    local playerFaction = UnitFactionGroup("player")

    panel = CreateFrame("Frame", "TBCCurrenciesPanel", CharacterFrame)
    panel:SetSize(CharacterFrame:GetWidth(), CharacterFrame:GetHeight())
    panel:SetAllPoints(CharacterFrame)
    panel:SetID(tabID)
    panel:Hide()

    -- Register in CHARACTERFRAME_SUBFRAMES so Blizzard's show/hide system works
    tinsert(CHARACTERFRAME_SUBFRAMES, "TBCCurrenciesPanel")

    -- Background textures matching other CharacterFrame subframes
    local bgTL = panel:CreateTexture(nil, "BORDER")
    bgTL:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
    bgTL:SetSize(256, 256)
    bgTL:SetPoint("TOPLEFT")

    local bgTR = panel:CreateTexture(nil, "BORDER")
    bgTR:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
    bgTR:SetSize(128, 256)
    bgTR:SetPoint("TOPRIGHT")

    local bgBL = panel:CreateTexture(nil, "BORDER")
    bgBL:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft")
    bgBL:SetSize(256, 256)
    bgBL:SetPoint("BOTTOMLEFT")

    local bgBR = panel:CreateTexture(nil, "BORDER")
    bgBR:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight")
    bgBR:SetSize(128, 256)
    bgBR:SetPoint("BOTTOMRIGHT")

    -- ScrollFrame for content
    local scrollFrame = CreateFrame("ScrollFrame", "TBCCurrenciesScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, TOP_OFFSET)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -64, 84)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1) -- updated by RelayoutPanel
    scrollFrame:SetScrollChild(scrollChild)

    -- Update scrollChild width when scrollFrame resizes
    scrollFrame:SetScript("OnSizeChanged", function(self)
        scrollChild:SetWidth(self:GetWidth())
    end)

    local sectionIndex = 0

    for _, sectionData in ipairs(CURRENCIES) do
        local hasVisible = false
        for _, curr in ipairs(sectionData.currencies) do
            if not curr.faction or curr.faction == playerFaction then
                hasVisible = true
                break
            end
        end

        if hasVisible then
            sectionIndex = sectionIndex + 1
            local headerFrame = CreateSectionHeader(scrollChild, sectionData.section, sectionIndex)

            local sectionRows = {}

            for _, curr in ipairs(sectionData.currencies) do
                if not curr.faction or curr.faction == playerFaction then
                    local row
                    if curr.type == "money" then
                        row = CreateMoneyRow(scrollChild)
                    else
                        row = CreateCurrencyRow(scrollChild, curr)
                    end
                    tinsert(rows, row)
                    tinsert(sectionRows, row)
                end
            end

            tinsert(sections, {
                headerFrame = headerFrame,
                rows = sectionRows,
                collapsed = false,
            })
        end
    end

    RelayoutPanel()

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
        self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        ResolveIcons()
    else
        UpdateCurrencies()
    end
end)
