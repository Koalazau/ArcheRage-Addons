-------------- Low Mana Notice --------------
-- Notifies player when mana percentage is low
--Testing commit change--
if API_TYPE == nil then
    ADDON:ImportAPI(8)
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "Globals folder not found. Please install it at https://github.com/Schiz-n/ArcheRage-addons/tree/master/globals")
    return
end
ADDON:ImportObject(OBJECT_TYPE.TEXT_STYLE)
ADDON:ImportObject(OBJECT_TYPE.WINDOW)
ADDON:ImportObject(OBJECT_TYPE.LABEL)

ADDON:ImportAPI(API_TYPE.CHAT.id)
ADDON:ImportAPI(API_TYPE.UNIT.id)

-- Color presets (R, G, B, A)
LMN_ColorPresets = {
    red = {1, 0.2, 0.2, 1},
    blue = {0.2, 0.4, 1, 1},
    green = {0.2, 1, 0.2, 1},
    yellow = {1, 1, 0.2, 1},
    orange = {1, 0.6, 0.2, 1},
    purple = {0.8, 0.2, 0.8, 1},
    cyan = {0.2, 1, 1, 1},
    white = {1, 1, 1, 1},
    pink = {1, 0.4, 0.7, 1},
    lime = {0.5, 1, 0.2, 1}
}

-- Configuration
local CONFIG_FILE = "LowManaNotice_Config.txt"
LMN_Config = {
    enabled = true,
    manaThreshold = 30,  -- Alert when mana drops below this %
    checkInterval = 100,  -- milliseconds between checks
    cooldownTime = 1000,  -- milliseconds before allowing repeat notification
    showOnScreen = true,  -- Show text on screen
    posX = 0,  -- X position relative to center
    posY = 0,  -- Y position relative to center
    fontSize = 24,  -- Font size for warning text
    textColor = "red"  -- Color preset name
}

-- State variables
local refreshForcer = CreateEmptyWindow("manaChecker", "UIParent")
refreshForcer:Show(true)
local counter = 0
local cooldownCounter = 0
local wasLowMana = false
LMN_WarningLabel = nil
LMN_WarningWindow = nil
local playerName = nil

-- Save configuration
function LMN_SaveConfig()
    local file = io.open(CONFIG_FILE, "w")
    if not file then
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "Failed to save LowManaNotice config.")
        return
    end
    
    file:write("return {\n")
    file:write(string.format("    enabled = %s,\n", tostring(LMN_Config.enabled)))
    file:write(string.format("    manaThreshold = %d,\n", LMN_Config.manaThreshold))
    file:write(string.format("    checkInterval = %d,\n", LMN_Config.checkInterval))
    file:write(string.format("    cooldownTime = %d,\n", LMN_Config.cooldownTime))
    file:write(string.format("    showOnScreen = %s,\n", tostring(LMN_Config.showOnScreen)))
    file:write(string.format("    posX = %d,\n", LMN_Config.posX))
    file:write(string.format("    posY = %d,\n", LMN_Config.posY))
    file:write(string.format("    fontSize = %d,\n", LMN_Config.fontSize))
    file:write(string.format("    textColor = \"%s\"\n", LMN_Config.textColor or "red"))
    file:write("}\n")
    file:close()
end

-- Load configuration
local function LoadConfig()
    local file = io.open(CONFIG_FILE, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local loadedConfig = loadstring(content)()
        if loadedConfig then
            for k, v in pairs(loadedConfig) do
                LMN_Config[k] = v
            end
        end
    end
end

-- Get current mana percentage
function LMN_GetManaPercentage()
    local currentMana = tonumber(X2Unit:UnitMana("player"))
    local maxMana = tonumber(X2Unit:UnitMaxMana("player"))
    if currentMana and maxMana and maxMana > 0 then
        return (currentMana / maxMana) * 100
    end
    return 100
end

-- Helper function to update window position
function LMN_UpdateWindowPosition()
    if LMN_WarningWindow then
        LMN_WarningWindow:RemoveAllAnchors()
        LMN_WarningWindow:AddAnchor("CENTER", "UIParent", LMN_Config.posX, LMN_Config.posY)
    end
end

-- Helper function to apply color to label
function LMN_ApplyLabelColor(colorName)
    if LMN_WarningLabel then
        local color = LMN_ColorPresets[colorName] or LMN_ColorPresets.red
        LMN_WarningLabel.style:SetColor(color[1], color[2], color[3], color[4])
    end
end

-- Update function
function refreshForcer:OnUpdate(dt)
    if not LMN_Config.enabled then
        return
    end
    
    counter = counter + dt
    
    if cooldownCounter > 0 then
        cooldownCounter = cooldownCounter - dt
    end
    
    if counter > LMN_Config.checkInterval then
        local manaPercent = LMN_GetManaPercentage()
        
        if manaPercent < LMN_Config.manaThreshold then
            if not wasLowMana or cooldownCounter <= 0 then
                cooldownCounter = LMN_Config.cooldownTime
                wasLowMana = true
            end
            if LMN_Config.showOnScreen and LMN_WarningWindow then
                LMN_WarningWindow:Show(true)
                LMN_WarningLabel:SetText(string.format("MANA LOW! %.0f%%", manaPercent))
            end
        else
            wasLowMana = false
            if LMN_WarningWindow then
                LMN_WarningWindow:Show(false)
            end
        end
        
        counter = 0
    end
end

-- Command handlers table
local commandHandlers = {}

commandHandlers["on"] = function()
    LMN_Config.enabled = true
    LMN_SaveConfig()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "LowManaNotice enabled!")
end

commandHandlers["off"] = function()
    LMN_Config.enabled = false
    LMN_SaveConfig()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "LowManaNotice disabled!")
end

commandHandlers["status"] = function()
    local mana = LMN_GetManaPercentage()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("Mana: %.1f%% | Threshold: %d%% | Check: %dms | Cooldown: %ds | Screen: %s | %s", 
        mana, LMN_Config.manaThreshold, LMN_Config.checkInterval, LMN_Config.cooldownTime/1000, 
        LMN_Config.showOnScreen and "On" or "Off", LMN_Config.enabled and "Enabled" or "Disabled"))
end

commandHandlers["reset"] = function()
    LMN_Config.posX = 0
    LMN_Config.posY = 0
    LMN_Config.fontSize = 24
    LMN_Config.textColor = "red"
    LMN_SaveConfig()
    LMN_UpdateWindowPosition()
    if LMN_WarningLabel then
        LMN_WarningLabel.style:SetFontSize(24)
    end
    LMN_ApplyLabelColor("red")
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "Warning position, size and color reset!")
end

commandHandlers["move up"] = function()
    LMN_Config.posY = LMN_Config.posY - 20
    LMN_SaveConfig()
    LMN_UpdateWindowPosition()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "Warning moved up")
end

commandHandlers["move down"] = function()
    LMN_Config.posY = LMN_Config.posY + 20
    LMN_SaveConfig()
    LMN_UpdateWindowPosition()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "Warning moved down")
end

commandHandlers["move left"] = function()
    LMN_Config.posX = LMN_Config.posX - 20
    LMN_SaveConfig()
    LMN_UpdateWindowPosition()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "Warning moved left")
end

commandHandlers["move right"] = function()
    LMN_Config.posX = LMN_Config.posX + 20
    LMN_SaveConfig()
    LMN_UpdateWindowPosition()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "Warning moved right")
end

commandHandlers["size bigger"] = function()
    LMN_Config.fontSize = math.min(LMN_Config.fontSize + 2, 48)
    LMN_SaveConfig()
    if LMN_WarningLabel then
        LMN_WarningLabel.style:SetFontSize(LMN_Config.fontSize)
    end
    X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("Font size increased to %d", LMN_Config.fontSize))
end

commandHandlers["size smaller"] = function()
    LMN_Config.fontSize = math.max(LMN_Config.fontSize - 2, 10)
    LMN_SaveConfig()
    if LMN_WarningLabel then
        LMN_WarningLabel.style:SetFontSize(LMN_Config.fontSize)
    end
    X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("Font size decreased to %d", LMN_Config.fontSize))
end

commandHandlers["screen on"] = function()
    LMN_Config.showOnScreen = true
    LMN_SaveConfig()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "On-screen warning enabled!")
end

commandHandlers["screen off"] = function()
    LMN_Config.showOnScreen = false
    LMN_SaveConfig()
    if LMN_WarningWindow then
        LMN_WarningWindow:Show(false)
    end
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "On-screen warning disabled!")
end

commandHandlers["screen colorlist"] = function()
    X2Chat:DispatchChatMessage(CMF_SYSTEM, "Available colors:")
    local colorList = ""
    for name, _ in pairs(LMN_ColorPresets) do
        colorList = colorList .. name .. ", "
    end
    colorList = string.sub(colorList, 1, -3)
    X2Chat:DispatchChatMessage(CMF_SYSTEM, colorList)
end

-- Chat commands
local function HandleChatCommand(msg)
    local cmd = string.lower(msg)
    
    if commandHandlers[cmd] then
        commandHandlers[cmd]()
        return
    end
    
    if cmd:match("^percent ") then
        local percent = tonumber(cmd:match("^percent (%d+)"))
        if percent and percent >= 1 and percent <= 99 then
            LMN_Config.manaThreshold = percent
            LMN_SaveConfig()
            X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("Mana threshold set to %d%%", percent))
        else
            X2Chat:DispatchChatMessage(CMF_SYSTEM, "Usage: !lmn percent 1-99 (mana percentage to trigger alert)")
        end
    elseif cmd:match("^interval ") then
        local interval = tonumber(cmd:match("^interval (%d+)"))
        if interval and interval >= 100 and interval <= 10000 then
            LMN_Config.checkInterval = interval
            LMN_SaveConfig()
            X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("Check interval set to %dms", interval))
        else
            X2Chat:DispatchChatMessage(CMF_SYSTEM, "Usage: !lmn interval 100-10000 (milliseconds between checks)")
        end
    elseif cmd:match("^cooldown ") then
        local cooldown = tonumber(cmd:match("^cooldown (%d+)"))
        if cooldown and cooldown >= 1 and cooldown <= 300 then
            LMN_Config.cooldownTime = cooldown * 1000
            LMN_SaveConfig()
            X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("Cooldown set to %d seconds", cooldown))
        else
            X2Chat:DispatchChatMessage(CMF_SYSTEM, "Usage: !lmn cooldown 1-300 (seconds before repeat notification)")
        end
    elseif cmd:match("^screen color ") then
        local colorName = cmd:match("^screen color (%w+)")
        if colorName and LMN_ColorPresets[colorName] then
            LMN_Config.textColor = colorName
            LMN_SaveConfig()
            LMN_ApplyLabelColor(colorName)
            X2Chat:DispatchChatMessage(CMF_SYSTEM, string.format("Warning color set to %s", colorName))
        else
            X2Chat:DispatchChatMessage(CMF_SYSTEM, "Invalid color. Use !lmn screen colorlist to see available colors")
        end
    else
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "LowManaNotice commands:")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn on/off - Enable/disable addon")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn status - Show current settings")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn percent 1-99 - Set mana threshold percentage")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn interval 100-10000 - Set check interval in milliseconds")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn cooldown 1-300 - Set cooldown in seconds")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn move up/down/left/right - Move warning")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn size bigger/smaller - Resize warning text")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn screen on/off/color [name]/colorlist - Screen options")
        X2Chat:DispatchChatMessage(CMF_SYSTEM, "  !lmn reset - Reset position, size and color")
    end
end

-- Create on-screen warning display
local function CreateWarningDisplay()
    LMN_WarningWindow = CreateEmptyWindow("manaWarningWindow", "UIParent")
    LMN_WarningWindow:SetExtent(200, 50)
    LMN_WarningWindow:AddAnchor("CENTER", "UIParent", LMN_Config.posX, LMN_Config.posY)
    LMN_WarningWindow:EnableDrag(true)
    LMN_WarningWindow:Show(false)
    
    LMN_WarningLabel = LMN_WarningWindow:CreateChildWidget("label", "manaWarningLabel", 0, false)
    LMN_WarningLabel:SetExtent(200, 50)
    LMN_WarningLabel:AddAnchor("CENTER", LMN_WarningWindow, 0, 0)
    LMN_WarningLabel:SetText("MANA LOW!")
    LMN_WarningLabel.style:SetFontSize(LMN_Config.fontSize or 24)
    LMN_WarningLabel.style:SetAlign(ALIGN_CENTER)
    local color = LMN_ColorPresets[LMN_Config.textColor] or LMN_ColorPresets.red
    LMN_WarningLabel.style:SetColor(color[1], color[2], color[3], color[4])
    LMN_WarningLabel.style:SetShadow(true)
    
    function LMN_WarningWindow:OnDragStart()
        self:StartMoving()
        self.moving = true
    end
    LMN_WarningWindow:SetHandler("OnDragStart", LMN_WarningWindow.OnDragStart)
    
    function LMN_WarningWindow:OnDragStop()
        self:StopMovingOrSizing()
        self.moving = false
        local _, _, _, offsetX, offsetY = LMN_WarningWindow:GetAnchor()
        LMN_Config.posX = offsetX
        LMN_Config.posY = offsetY
        LMN_SaveConfig()
    end
    LMN_WarningWindow:SetHandler("OnDragStop", LMN_WarningWindow.OnDragStop)
end

-- Initialize
local function LoadConfig()
    local file = io.open(CONFIG_FILE, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local loadedConfig = loadstring(content)()
        if loadedConfig then
            for k, v in pairs(loadedConfig) do
                LMN_Config[k] = v
            end
        end
    end
end

LoadConfig()
CreateWarningDisplay()
playerName = X2Unit:UnitName("player")

-- Chat event listener
local chatEventListenerEvents = {
    CHAT_MESSAGE = function(channel, relation, name, message, info)
        if name == playerName then
            if string.find(message, "^!lmn ") then
                local cmd = string.gsub(message, "^!lmn ", "")
                HandleChatCommand(cmd)
            elseif message == "!lmn" then
                HandleChatCommand("")
            end
        end
    end
}

-- Event handlers
for event, handler in pairs(chatEventListenerEvents) do
    UIParent:SetEventHandler(event, handler)
end

refreshForcer:SetHandler("OnUpdate", refreshForcer.OnUpdate)

X2Chat:DispatchChatMessage(CMF_SYSTEM, "LowManaNotice loaded! Type !lmn for commands.")
