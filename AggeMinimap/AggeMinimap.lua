local addonName = ...
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"
local events = CreateFrame("Frame")
local border
local hookedCluster
local hookedHeader
local hookedMap
local headerUnderneath = false
local settingsWindow
local announced = false
local function GetNumberSetting(key, default, minimum, maximum)
    local value = type(AggeMinimapDB) == "table" and AggeMinimapDB[key]
    if type(value) ~= "number" or value ~= value then
        return default
    end
    return math.max(minimum, math.min(maximum, math.floor(value + 0.5)))
end

local function GetMapSize()
    return GetNumberSetting("size", 198, 160, 360)
end

local function GetSpacing()
    return GetNumberSetting("spacing", 2, 0, 40)
end

local sunCorners = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
local zoomSides = {"LEFT", "RIGHT", "TOP", "BOTTOM"}
local function GetPositionSetting(key, choices, default)
    local value = type(AggeMinimapDB) == "table" and AggeMinimapDB[key]
    for _, choice in ipairs(choices) do
        if value == choice then
            return value
        end
    end
    return default
end

local function ApplyLayout()
    if InCombatLockdown() then
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    local cluster = MinimapCluster
    local container = cluster and cluster.MinimapContainer
    local map = Minimap
    if not container or not map or not cluster.SetFixedSize then
        return
    end

    local spacing = GetSpacing()
    local scale = container:GetScale()
    local width = GetMapSize()
    local height = width
    if not scale or scale <= 0 or width <= 0 or height <= 0 then
        return
    end
    -- The stock container includes room for circular art outside the map.
    -- Fit it to the actual square, then size the Edit Mode frame explicitly.
    map:SetSize(width, height)
    container:SetSize(width, height)
    local header = cluster.ZoneTextButton
    local desiredHeaderScale = cluster.scaleMinimapHeader and math.max(scale, 1) or 1
    local rowScale = math.min(desiredHeaderScale, width * scale / 198)
    local rowHeight = 23 * rowScale
    local frameWidth = width * scale + 2 * spacing
    local frameHeight = height * scale + rowHeight + 3 * spacing
    cluster:SetFixedSize(frameWidth, frameHeight)
    cluster:SetSize(frameWidth, frameHeight)
    cluster:SetHitRectInsets(0, 0, 0, 0)

    container:ClearAllPoints()
    container:SetPoint("TOP", cluster, "TOP", 0,
        -(spacing + (headerUnderneath and 0 or rowHeight + spacing)) / scale)

    -- Keep the native zoom buttons and their hover area on the selected edge.
    local zoomSide = GetPositionSetting("zoomSide", zoomSides, "LEFT")
    local vertical = zoomSide == "LEFT" or zoomSide == "RIGHT"
    local inset = (zoomSide == "RIGHT" or zoomSide == "TOP") and -12 or 12
    local zoomX, zoomY = vertical and inset or 0, vertical and 0 or inset
    if map.ZoomIn then
        map.ZoomIn:ClearAllPoints()
        map.ZoomIn:SetPoint("CENTER", map, zoomSide, zoomX + (vertical and 0 or -10), zoomY + (vertical and 10 or 0))
    end
    if map.ZoomOut then
        map.ZoomOut:ClearAllPoints()
        map.ZoomOut:SetPoint("CENTER", map, zoomSide, zoomX + (vertical and 0 or 10), zoomY + (vertical and -10 or 0))
    end
    if map.ZoomHitArea then
        map.ZoomHitArea:ClearAllPoints()
        map.ZoomHitArea:SetSize(vertical and 40 or 48, vertical and 48 or 40)
        map.ZoomHitArea:SetPoint("CENTER", map, zoomSide, zoomX, zoomY)
    end
    if cluster.DielFrame then
        -- This frame belongs to the cluster, so match the map container's
        -- scale explicitly, including Edit Mode scales below one.
        cluster.DielFrame:SetScale(scale)
        cluster.DielFrame:ClearAllPoints()
        local corner = GetPositionSetting("sunCorner", sunCorners, "TOPLEFT")
        cluster.DielFrame:SetPoint(corner, map, corner,
            corner:find("LEFT") and 4 or -4, corner:find("TOP") and -4 or 4)
    end

    local rowY = headerUnderneath and (height * scale + 2 * spacing) or spacing
    local rowWidth = width * scale / rowScale
    local gap = 3
    local left, right = 0, rowWidth
    local function Place(frame, x, elementWidth, elementHeight)
        frame:SetScale(rowScale)
        frame:SetSize(elementWidth, elementHeight)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", cluster, "TOPLEFT",
            spacing / rowScale + x, -(rowY / rowScale + (23 - elementHeight) / 2))
    end
    -- Anchor every header control to the same row. Do not inherit Blizzard's
    -- stacked calendar/compartment anchors or its clock-inside-zone placement.
    if cluster.Tracking then
        Place(cluster.Tracking, left, 23, 23)
        left = left + 23 + gap
    end
    for _, frame in ipairs({AddonCompartmentFrame or false, GameTimeFrame or false, TimeManagerClockButton or false}) do
        if frame then
            local clock = frame == TimeManagerClockButton
            local elementWidth = clock and 48 or 23
            right = right - elementWidth
            Place(frame, right, elementWidth, clock and 16 or 23)
            right = right - gap
        end
    end
    if header then
        Place(header, left, math.max(1, right - left), 23)
        if MinimapZoneText then
            MinimapZoneText:ClearAllPoints()
            MinimapZoneText:SetPoint("LEFT", header, "LEFT", 2, 0)
            MinimapZoneText:SetWidth(math.max(1, right - left - 4))
            MinimapZoneText:SetWordWrap(false)
            MinimapZoneText:SetNonSpaceWrap(false)
        end
    end
end

local settingsControls = {}
local refreshingControls = false
local settingsCategory

local function RefreshSettingsControls()
    refreshingControls = true
    for _, controls in ipairs(settingsControls) do
        controls.spacing:SetValue(GetSpacing())
        controls.size:SetValue(GetMapSize())
        controls.spacingText:SetText("Spacing: " .. GetSpacing() .. " px")
        controls.sizeText:SetText("Map size: " .. GetMapSize() .. " × " .. GetMapSize())
        for _, group in ipairs(controls.positions) do
            local selected = GetPositionSetting(group.key, group.choices, group.default)
            for _, button in ipairs(group.buttons) do
                button:SetText((button.value == selected and "|cff54cdb1" or "|cffffffff") .. button.label .. "|r")
            end
        end
    end
    refreshingControls = false
end

local function CreateSettingsControls(parent, prefix)
    local controls = {}
    local function Slider(suffix, key, offset, minimum, maximum, low, high)
        local name = prefix .. suffix
        local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
        slider:SetPoint("TOP", 0, offset)
        slider:SetWidth(250)
        slider:SetMinMaxValues(minimum, maximum)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)
        _G[name .. "Low"]:SetText(low)
        _G[name .. "High"]:SetText(high)
        slider:SetScript("OnValueChanged", function(_, value)
            if refreshingControls then
                return
            end
            AggeMinimapDB = type(AggeMinimapDB) == "table" and AggeMinimapDB or {}
            AggeMinimapDB[key] = math.max(minimum, math.min(maximum, math.floor(value + 0.5)))
            RefreshSettingsControls()
            ApplyLayout()
        end)
        return slider, _G[name .. "Text"]
    end
    controls.size, controls.sizeText = Slider("Size", "size", -65, 160, 360, "160", "360")
    controls.spacing, controls.spacingText = Slider("Spacing", "spacing", -130, 0, 40, "Tight", "Roomy")
    controls.positions = {}
    local function PositionButtons(key, choices, default, title, labels, y, columns, buttonWidth)
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOP", 0, y)
        label:SetText(title)
        local group = {key = key, choices = choices, default = default, buttons = {}}
        for index, choice in ipairs(choices) do
            local button = CreateFrame("Button", prefix .. key .. choice, parent, "UIPanelButtonTemplate")
            button:SetSize(buttonWidth, 22)
            button:SetPoint("TOP", (index - 1) % columns * (buttonWidth + 6) - (columns - 1) * (buttonWidth + 6) / 2,
                y - 22 - math.floor((index - 1) / columns) * 26)
            button.value, button.label = choice, labels[index]
            button:SetScript("OnClick", function()
                AggeMinimapDB = type(AggeMinimapDB) == "table" and AggeMinimapDB or {}
                AggeMinimapDB[key] = choice
                RefreshSettingsControls()
                ApplyLayout()
            end)
            table.insert(group.buttons, button)
        end
        table.insert(controls.positions, group)
    end
    PositionButtons("sunCorner", sunCorners, "TOPLEFT", "Sun / moon corner",
        {"Top left", "Top right", "Bottom left", "Bottom right"}, -175, 2, 140)
    PositionButtons("zoomSide", zoomSides, "LEFT", "Zoom button edge",
        {"Left", "Right", "Top", "Bottom"}, -260, 4, 68)
    local note = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("BOTTOM", 0, 18)
    note:SetText("Changes apply after combat if you are fighting.")
    table.insert(settingsControls, controls)
    RefreshSettingsControls()
    return controls
end

local function OpenSettings()
    if not settingsWindow then
        local panel = CreateFrame("Frame", "AggeMinimapSettings", UIParent, "BasicFrameTemplateWithInset")
        panel:SetSize(340, 350)
        panel:SetPoint("CENTER")
        panel:SetFrameStrata("DIALOG")
        panel:SetClampedToScreen(true)
        panel.TitleText:SetText("AggeMinimap")
        CreateSettingsControls(panel, "AggeMinimap")
        panel:SetScript("OnShow", RefreshSettingsControls)
        table.insert(UISpecialFrames, "AggeMinimapSettings")
        settingsWindow = panel
    end
    RefreshSettingsControls()
    settingsWindow:Show()
end

local function RegisterSettings()
    if settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory or not Settings.RegisterAddOnCategory then
        return
    end
    local panel = CreateFrame("Frame", "AggeMinimapOptions")
    panel:Hide()
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AggeMinimap")
    -- Construct the same controls on demand, with separate names for each view.
    panel:SetScript("OnShow", function(self)
        if not self.controls then
            local content = CreateFrame("Frame", nil, self)
            content:SetSize(340, 350)
            content:SetPoint("TOPLEFT", 16, -40)
            self.controls = CreateSettingsControls(content, "AggeMinimapOptions")
        end
        RefreshSettingsControls()
    end)
    settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, "AggeMinimap")
    Settings.RegisterAddOnCategory(settingsCategory)
end

SLASH_AGGEMINIMAP1 = "/amm"
SlashCmdList.AGGEMINIMAP = OpenSettings


local function HideArt(region)
    if region then
        -- Keep the region and its anchors intact for Blizzard's layout code.
        region:SetAlpha(0)
        -- The header's hover handler changes alpha; transparent vertex color
        -- keeps its decorative textures invisible through those state changes.
        if region.SetVertexColor then
            region:SetVertexColor(1, 1, 1, 0)
        end
    end
end

local function CreateBorder(map)
    local frame = CreateFrame("Frame", nil, map)
    frame:SetPoint("TOPLEFT", map, "TOPLEFT", -1, 1)
    frame:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", 1, -1)
    frame:EnableMouse(false)

    local function Edge(first, second, horizontal)
        local texture = frame:CreateTexture(nil, "OVERLAY")
        texture:SetColorTexture(0.07, 0.07, 0.07, 1)
        texture:SetPoint(first)
        texture:SetPoint(second)
        if horizontal then
            texture:SetHeight(1)
        else
            texture:SetWidth(1)
        end
    end

    Edge("TOPLEFT", "TOPRIGHT", true)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
    Edge("TOPLEFT", "BOTTOMLEFT", false)
    Edge("TOPRIGHT", "BOTTOMRIGHT", false)
    return frame
end

local function ApplyStyle()
    if InCombatLockdown() then
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local map = Minimap
    if not map or not map.SetMaskTexture then
        return
    end

    map:SetMaskTexture("Interface\\AddOns\\AggeMinimap\\Square.tga")
    map:EnableMouseWheel(true) -- Forever already implements mouse-wheel zoom.
    if map ~= hookedMap then
        map:HookScript("OnMouseUp", function(_, button)
            if button == "RightButton" then
                OpenSettings()
            end
        end)
        hookedMap = map
    end

    -- Only decorative regions: never hide MinimapBackdrop, which owns buttons.
    HideArt(MinimapCompassTexture)
    HideArt(MinimapCompassTextureUnderlay)
    HideArt(MinimapBorder)
    HideArt(MinimapBorderTop)

    local cluster = MinimapCluster
    if cluster then
        HideArt(cluster.BorderTop)
        local header = cluster.ZoneTextButton
        if header then
            HideArt(header.StateTexture)
            HideArt(header.AddTexture)
        end

        -- Camelot resets the mask and compass art when rotateMinimap changes.
        -- A secure post-hook preserves Blizzard's implementation.
        if cluster ~= hookedCluster and type(cluster.UpdateMinimapConfig) == "function" then
            hooksecurefunc(cluster, "UpdateMinimapConfig", ApplyStyle)
            hookedCluster = cluster
            if type(cluster.SetHeaderUnderneath) == "function" then
                hooksecurefunc(cluster, "SetHeaderUnderneath", function(_, underneath)
                    headerUnderneath = underneath
                    ApplyLayout()
                end)
            end
            if type(cluster.SetEditModeScale) == "function" then
                hooksecurefunc(cluster, "SetEditModeScale", ApplyLayout)
            end
            -- ResizeLayout may otherwise grow the selection back around the
            -- old decorative extents after Edit Mode or a visibility change.
            if type(cluster.Layout) == "function" then
                hooksecurefunc(cluster, "Layout", ApplyLayout)
            end
        end
        if header and header ~= hookedHeader and header.GetPoint then
            local point = header:GetPoint(1)
            headerUnderneath = point and point:find("BOTTOM") ~= nil or false
            hookedHeader = header
        end
    end

    if not border then
        border = CreateBorder(map)
    end
    border:SetFrameLevel(map:GetFrameLevel() + 1)
    ApplyLayout()

    -- Used by LibDBIcon and other minimap-button placement libraries.
    if not GetMinimapShape or GetMinimapShape() ~= "SQUARE" then
        GetMinimapShape = function()
            return "SQUARE"
        end
    end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name ~= addonName and name ~= "Blizzard_Minimap" and name ~= "Blizzard_TimeManager"
        and name ~= "Blizzard_Settings" and name ~= "Blizzard_Settings_Shared" then
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent(event)
    end
    RegisterSettings()
    ApplyStyle()
    if event == "PLAYER_LOGIN" and not announced then
        announced = true
        print("|cff54cdb1AggeMinimap v" .. addonVersion .. ":|r Loaded. /amm for settings.")
    end
end)
