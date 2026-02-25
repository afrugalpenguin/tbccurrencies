std = "lua51"
max_line_length = false

globals = {
    "CHARACTERFRAME_SUBFRAMES",
    "CharacterFrameTab_OnClick",
}

read_globals = {
    -- WoW Frame API
    "CreateFrame", "UIParent", "CharacterFrame",
    "PanelTemplates_SetNumTabs", "PanelTemplates_SetTab",
    "ToggleCharacter", "CharacterFrame_ShowSubFrame",
    "hooksecurefunc", "GameTooltip", "SOUNDKIT",

    -- WoW APIs used by this addon
    "GetMoney", "C_CurrencyInfo", "GetItemCount",
    "GetItemInfo", "UnitFactionGroup",

    -- WoW globals
    "HIGHLIGHT_FONT_COLOR", "GRAY_FONT_COLOR",

    -- Lua globals
    "format", "floor", "mod", "tinsert",

    -- Sound
    "PlaySound",
}

ignore = {
    "211",
    "212",
    "213",
}

exclude_files = {
    ".lua",
    ".luarocks",
    "lua_modules",
}
