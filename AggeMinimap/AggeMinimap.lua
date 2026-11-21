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
local renderedMap, renderedWidth, renderedHeight, renderedScale
local hiddenQuestRingMap

local function QuestAreaFixEnabled()
    return type(AggeMinimapDB) == "table" and AggeMinimapDB.questAreaFix == true
end

local function ApplyQuestAreaFix(map)
    if not map.SetQuestBlobRingAlpha then return end
    -- Only suppress the decorative ring; keep objective-area fill and pins.
    if QuestAreaFixEnabled() then
        map:SetQuestBlobRingAlpha(0)
        hiddenQuestRingMap = map
    elseif hiddenQuestRingMap == map then
        map:SetQuestBlobRingAlpha(1)
        hiddenQuestRingMap = nil
    end
end
local addonButtonLayouts = setmetatable({}, {__mode = "k"})
local addonButtonScanQueued = false

local function AlignAddonButtons()
    return type(AggeMinimapDB) ~= "table" or AggeMinimapDB.alignAddonButtons ~= false
end

local function GetAddonButtonPadding()
    local library = LibStub and LibStub("LibDBIcon-1.0", true)
    local padding = library and library.radius
    if type(padding) == "number" and padding == padding and math.abs(padding) < math.huge then
        return padding
    end
    return 5 -- LibDBIcon's default distance from the map edge.
end

local function GetVisibleMapSize(map)
    local container = MinimapCluster and MinimapCluster.MinimapContainer
    return (container or map):GetSize()
end

local function PlaceAddonButton(button, layout, map)
    if not layout.x or not layout.y then return end
    if button:IsProtected() then return end
    if InCombatLockdown() then
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    local width, height = GetVisibleMapSize(map)
    if (layout.library and width == height) or (not layout.library and not AlignAddonButtons()) then
        if layout.projected then
            layout.applying = true
            button:ClearAllPoints()
            button:SetPoint("CENTER", map, "CENTER", layout.x, layout.y)
            layout.applying = false
            layout.projected = false
        end
        return
    end
    local padding = GetAddonButtonPadding()
    local halfWidth = width / 2 + padding
    local halfHeight = height / 2 + padding
    if halfWidth <= 0 or halfHeight <= 0 then return end
    local x, y = layout.x, layout.y
    local angle = layout.library and ((button.db and button.db.minimapPos) or button.minimapPos)
    if type(angle) == "number" and angle == angle then
        x, y = math.cos(math.rad(angle)), math.sin(math.rad(angle))
    end
    local divisor = math.max(math.abs(x) / halfWidth, math.abs(y) / halfHeight)
    if divisor <= 0 then return end
    layout.applying = true
    button:ClearAllPoints()
    button:SetPoint("CENTER", map, "CENTER", x / divisor, y / divisor)
    layout.applying = false
    layout.projected = true
end

local function HookAddonButton(button, map)
    if addonButtonLayouts[button] or not button:IsObjectType("Button") or button:IsProtected()
        or button == map.ZoomIn or button == map.ZoomOut then return end
    -- Library buttons need the visible rectangle rather than the square native
    -- canvas. The optional fallback remains limited to draggable addon buttons.
    local name = button:GetName()
    local library = name and name:find("^LibDBIcon") ~= nil
    local visibleWidth, visibleHeight = GetVisibleMapSize(map)
    if library and visibleWidth == visibleHeight then return end
    if not library and (not AlignAddonButtons() or (not button:GetScript("OnDragStart") and not button:GetScript("OnDragStop"))) then return end
    local width, height = button:GetSize()
    if width < 12 or height < 12 or width > 64 or height > 64 or button:GetNumPoints() ~= 1 then return end
    local point, relativeTo, relativePoint, x, y = button:GetPoint(1)
    if point ~= "CENTER" or (relativeTo ~= map and relativeTo ~= "Minimap") or relativePoint ~= "CENTER" then return end
    if type(x) ~= "number" or type(y) ~= "number" or x ~= x or y ~= y then return end
    local radius = math.sqrt(x * x + y * y)
    if radius < math.min(visibleWidth, visibleHeight) / 2 - 24
        or radius > math.max(visibleWidth, visibleHeight) / 2 + 64 then return end
    local layout = {library = library}
    addonButtonLayouts[button] = layout
    local function Capture(self, point, relativeTo, relativePoint, x, y)
        if layout.applying then return end
        layout.x, layout.y = nil, nil
        layout.projected = false
        if point ~= "CENTER" or (relativeTo ~= map and relativeTo ~= "Minimap") or relativePoint ~= "CENTER"
            or type(x) ~= "number" or type(y) ~= "number" or x ~= x or y ~= y then return end
        local radius = math.sqrt(x * x + y * y)
        if radius == 0 or radius == math.huge then return end
        layout.x, layout.y = x, y
        PlaceAddonButton(self, layout, map)
    end
    hooksecurefunc(button, "SetPoint", Capture)
    Capture(button, button:GetPoint(1))
end

local function HookAddonButtons(map)
    for _, button in ipairs({map:GetChildren()}) do HookAddonButton(button, map) end
    if MinimapBackdrop then
        for _, button in ipairs({MinimapBackdrop:GetChildren()}) do HookAddonButton(button, map) end
    end
end

local function QueueAddonButtonScan()
    if addonButtonScanQueued then return end
    local function Scan()
        addonButtonScanQueued = false
        if InCombatLockdown() then
            events:RegisterEvent("PLAYER_REGEN_ENABLED")
        elseif Minimap then
            HookAddonButtons(Minimap)
        end
    end
    if C_Timer and C_Timer.After then
        addonButtonScanQueued = true
        C_Timer.After(0, Scan)
    else
        Scan()
    end
end
local function GetNumberSetting(key, default, minimum, maximum)
    local value = type(AggeMinimapDB) == "table" and AggeMinimapDB[key]
    if type(value) ~= "number" or value ~= value then
        return default
    end
    return math.max(minimum, math.min(maximum, math.floor(value + 0.5)))
end

local function GetMapDimension(key)
    -- Preserve the old square-size setting when upgrading an existing profile.
    return GetNumberSetting(key, GetNumberSetting("size", 200, 160, 360), 160, 360)
end

local function IsAspectLinked()
    return type(AggeMinimapDB) ~= "table" or AggeMinimapDB.linkAspect ~= false
end

local function SetMapDimension(key, value)
    local width, height = GetMapDimension("width"), GetMapDimension("height")
    local function Round(number) return math.max(160, math.min(360, math.floor(number + 0.5))) end
    if IsAspectLinked() then
        local ratio = AggeMinimapDB.aspectRatio
        if type(ratio) ~= "number" or ratio ~= ratio or ratio < 160 / 360 or ratio > 360 / 160 then
            ratio = width / height
        end
        AggeMinimapDB.aspectRatio = ratio
        -- Limit both dimensions together so the linked ratio survives the bounds.
        if key == "width" then
            width = math.max(math.max(160, 160 * ratio), math.min(math.min(360, 360 * ratio), value))
            height = width / ratio
        else
            height = math.max(math.max(160, 160 / ratio), math.min(math.min(360, 360 / ratio), value))
            width = height * ratio
        end
    elseif key == "width" then
        width = value
    else
        height = value
    end
    AggeMinimapDB.width, AggeMinimapDB.height = Round(width), Round(height)
end

local function GetSpacing()
    return GetNumberSetting("spacing", 0, -20, 40)
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
    ApplyQuestAreaFix(map)
    local scale = container:GetScale()
    local width = GetMapDimension("width")
    local height = GetMapDimension("height")
    if not scale or scale <= 0 or width <= 0 or height <= 0 then
        return
    end
    -- The stock container includes room for circular art outside the map.
    -- Fit it to the map, then size the Edit Mode frame explicitly.
    local canvasSize = math.max(width, height)
    local cropX, cropY = (canvasSize - width) / 2, (canvasSize - height) / 2
    -- Native terrain, player arrow, and pings share a projection only on a
    -- square canvas. Crop its center; never distort that native projection.
    map:SetSize(canvasSize, canvasSize)
    container:SetSize(width, height)
    local span = math.floor(math.min(width, height) / canvasSize * 128 + 0.5) * 2
    local mask = span == 256 and "Square.tga" or ("Masks\\" .. (width > height and "W" or "T") .. span .. ".tga")
    map:SetMaskTexture("Interface\\AddOns\\AggeMinimap\\" .. mask)
    map:SetHitRectInsets(cropX, cropX, cropY, cropY)
    HookAddonButtons(map)
    for button, layout in pairs(addonButtonLayouts) do
        PlaceAddonButton(button, layout, map)
    end
    map:ClearAllPoints()
    map:SetPoint("CENTER", container, "CENTER", 0, 0)
    if border then
        -- Size the border explicitly on every resize instead of relying on
        -- two opposing anchors being refreshed by the native minimap frame.
        border:SetSize(width + 2, height + 2)
    end
    local header = cluster.ZoneTextButton
    local desiredHeaderScale = cluster.scaleMinimapHeader and math.max(scale, 1) or 1
    local rowScale = math.min(desiredHeaderScale, width * scale / 198)
    local rowHeight = 23 * rowScale
    local outerSpacing = math.max(0, spacing)
    local headerGap = math.max(spacing, -rowHeight)
    -- Edit Mode selects the visible map and header, not the hidden canvas.
    local frameWidth = width * scale + 2 * outerSpacing
    local frameHeight = height * scale + rowHeight + 2 * outerSpacing + headerGap
    cluster:SetFixedSize(frameWidth, frameHeight)
    cluster:SetSize(frameWidth, frameHeight)
    cluster:SetHitRectInsets(0, 0, 0, 0)
    -- Keep only the actual native canvas on-screen. Clamp bounds can extend
    -- beyond the selection without reserving a second header-sized margin.
    local mapTop = outerSpacing + (headerUnderneath and 0 or rowHeight + headerGap)
    local clampX = math.max(0, cropX * scale - outerSpacing)
    local clampTop = math.max(0, cropY * scale - mapTop)
    local clampBottom = math.max(0, mapTop + (height + cropY) * scale - frameHeight)
    cluster:SetClampRectInsets(-clampX, clampX, clampTop, -clampBottom)
    cluster:SetClampedToScreen(true)

    container:ClearAllPoints()
    container:SetPoint("TOP", cluster, "TOP", 0,
        -mapTop / scale)

    -- Keep the native zoom buttons and their hover area on the selected edge.
    local zoomSide = GetPositionSetting("zoomSide", zoomSides, "LEFT")
    local vertical = zoomSide == "LEFT" or zoomSide == "RIGHT"
    local inset = (zoomSide == "RIGHT" or zoomSide == "TOP") and -12 or 12
    local zoomX, zoomY = vertical and inset or 0, vertical and 0 or inset
    if map.ZoomIn then
        map.ZoomIn:ClearAllPoints()
        map.ZoomIn:SetPoint("CENTER", container, zoomSide, zoomX + (vertical and 0 or -10), zoomY + (vertical and 10 or 0))
    end
    if map.ZoomOut then
        map.ZoomOut:ClearAllPoints()
        map.ZoomOut:SetPoint("CENTER", container, zoomSide, zoomX + (vertical and 0 or 10), zoomY + (vertical and -10 or 0))
    end
    if map.ZoomHitArea then
        map.ZoomHitArea:ClearAllPoints()
        map.ZoomHitArea:SetSize(vertical and 40 or 48, vertical and 48 or 40)
        map.ZoomHitArea:SetPoint("CENTER", container, zoomSide, zoomX, zoomY)
    end
    if cluster.DielFrame then
        -- This frame belongs to the cluster, so match the map container's
        -- scale explicitly, including Edit Mode scales below one.
        cluster.DielFrame:SetScale(scale)
        cluster.DielFrame:ClearAllPoints()
        local corner = GetPositionSetting("sunCorner", sunCorners, "TOPLEFT")
        cluster.DielFrame:SetPoint(corner, container, corner,
            corner:find("LEFT") and 4 or -4, corner:find("TOP") and -4 or 4)
    end

    local rowY = headerUnderneath and (height * scale + outerSpacing + headerGap) or outerSpacing
    local rowWidth = width * scale / rowScale
    local gap = 3
    local left, right = 0, rowWidth
    local function Place(frame, x, elementWidth, elementHeight)
        frame:SetScale(rowScale)
        frame:SetSize(elementWidth, elementHeight)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", cluster, "TOPLEFT",
            outerSpacing / rowScale + x, -(rowY / rowScale + (23 - elementHeight) / 2))
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

    -- Changing the frame dimensions can leave the native map render surface at
    -- its old size. Rebuild it through the zoom API, without button clicks or
    -- sounds, and restore the user's zoom before the next rendered frame.
    local renderScale = map.GetEffectiveScale and map:GetEffectiveScale() or scale
    if map ~= renderedMap or width ~= renderedWidth or height ~= renderedHeight or renderScale ~= renderedScale then
        if map.GetZoom and map.SetZoom and map.GetZoomLevels and map:GetZoomLevels() > 1 then
            renderedMap, renderedWidth, renderedHeight, renderedScale = map, width, height, renderScale
            local zoom = map:GetZoom()
            map:SetZoom(zoom == 0 and 1 or zoom - 1)
            map:SetZoom(zoom)
        end
    end
end

local settingsControls = {}
local refreshingControls = false
local settingsCategory

local function SettingsText(parent, value, x, y, font)
    local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    text:SetPoint("TOPLEFT", x, y)
    text:SetText(value)
    text:SetJustifyH("LEFT")
    if font == "GameFontHighlightSmall" then
        text:SetTextColor(0.8, 0.73, 0.6)
    end
    return text
end

local function SettingsButton(parent, name, label, width, x, y)
    local button = CreateFrame("Button", name, parent)
    button:SetSize(width, 28)
    button:SetPoint("TOPLEFT", x, y)
    local fill = button:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetAtlas("UI-Character-Info-Title")
    fill:SetVertexColor(0.65, 0.65, 0.68)
    button.highlight = button:CreateTexture(nil, "ARTWORK")
    button.highlight:SetAllPoints()
    button.highlight:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
    button.highlight:SetVertexColor(0.78, 0.81, 0.86)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", 8, 0)
    button.label:SetPoint("RIGHT", -8, 0)
    button.label:SetJustifyH("CENTER")
    function button:SetText(value) self.label:SetText(value) end
    button.selection = {}
    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local line = button:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(1, 0.76, 0.2, 0.85)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetPoint(edge .. "LEFT")
            line:SetPoint(edge .. "RIGHT")
            line:SetHeight(1)
        else
            line:SetPoint("TOP" .. edge)
            line:SetPoint("BOTTOM" .. edge)
            line:SetWidth(1)
        end
        table.insert(button.selection, line)
    end
    function button:Select(selected)
        self.selected = selected
        self.highlight:SetAlpha(selected and 0.4 or 0)
        self.label:SetTextColor(1, selected and 0.82 or 0.95, selected and 0.2 or 0.85)
        for _, line in ipairs(self.selection) do line:SetAlpha(selected and 1 or 0) end
    end
    button:SetText(label)
    button:Select(false)
    button:SetScript("OnEnter", function(self) self.highlight:SetAlpha(self.selected and 0.5 or 0.25) end)
    button:SetScript("OnLeave", function(self) self:Select(self.selected) end)
    return button
end

local function RefreshSettingsControls()
    refreshingControls = true
    for _, controls in ipairs(settingsControls) do
        controls.spacing:SetValue(GetSpacing())
        controls.width:SetValue(GetMapDimension("width"))
        controls.height:SetValue(GetMapDimension("height"))
        controls.spacingText:SetText("Spacing: " .. GetSpacing() .. " px")
        controls.widthText:SetText("Width: " .. GetMapDimension("width") .. " px")
        controls.heightText:SetText("Height: " .. GetMapDimension("height") .. " px")
        controls.link:SetText(IsAspectLinked() and "Aspect ratio: Linked" or "Aspect ratio: Unlinked")
        controls.link:Select(IsAspectLinked())
        controls.alignButtons:SetChecked(AlignAddonButtons())
        controls.questAreaFix:SetChecked(QuestAreaFixEnabled())
        for _, group in ipairs(controls.positions) do
            local selected = GetPositionSetting(group.key, group.choices, group.default)
            for _, button in ipairs(group.buttons) do
                button:Select(button.value == selected)
            end
        end
    end
    refreshingControls = false
end

local function CreateSettingsControls(parent, prefix)
    local controls = {}
    SettingsText(parent, "MAP LAYOUT", 0, 0)
    SettingsText(parent, "Adjust map dimensions and header gap.", 0, -23, "GameFontHighlightSmall")
    SettingsText(parent, "BUTTON POSITIONS", 286, 0)
    local divider = parent:CreateTexture(nil, "BACKGROUND")
    divider:SetColorTexture(0.65, 0.45, 0.2, 0.45)
    divider:SetPoint("TOPLEFT", 262, 0)
    divider:SetSize(1, 304)
    local function Slider(suffix, key, offset, minimum, maximum, low, high)
        local name = prefix .. suffix
        local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 8, offset)
        slider:SetWidth(226)
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
            value = math.max(minimum, math.min(maximum, math.floor(value + 0.5)))
            if key == "width" or key == "height" then
                SetMapDimension(key, value)
            else
                AggeMinimapDB[key] = value
            end
            RefreshSettingsControls()
            ApplyLayout()
        end)
        return slider, _G[name .. "Text"]
    end
    controls.width, controls.widthText = Slider("Width", "width", -64, 160, 360, "160", "360")
    SettingsText(parent, "Default: 200 px", 8, -94, "GameFontHighlightSmall")
    controls.height, controls.heightText = Slider("Height", "height", -128, 160, 360, "160", "360")
    SettingsText(parent, "Default: 200 px", 8, -158, "GameFontHighlightSmall")
    controls.link = SettingsButton(parent, prefix .. "LinkAspect", "", 226, 8, -184)
    controls.link:SetScript("OnClick", function()
        local linked = IsAspectLinked()
        local ratio = GetMapDimension("width") / GetMapDimension("height")
        AggeMinimapDB = type(AggeMinimapDB) == "table" and AggeMinimapDB or {}
        AggeMinimapDB.linkAspect = not linked
        AggeMinimapDB.aspectRatio = not linked and ratio or nil
        RefreshSettingsControls()
    end)
    SettingsText(parent, "Default: linked. Click to toggle.", 8, -218, "GameFontHighlightSmall")
    controls.spacing, controls.spacingText = Slider("Spacing", "spacing", -266, -20, 40, "-20", "40")
    SettingsText(parent, "Default: 0 px. Negative overlaps header.", 8, -296, "GameFontHighlightSmall")
    controls.positions = {}
    local function PositionButtons(key, choices, default, title, labels, y)
        SettingsText(parent, title, 286, y, "GameFontHighlightSmall")
        local group = {key = key, choices = choices, default = default, buttons = {}}
        for index, choice in ipairs(choices) do
            local button = SettingsButton(parent, prefix .. key .. choice, labels[index], 130,
                286 + (index - 1) % 2 * 136, y - 23 - math.floor((index - 1) / 2) * 34)
            button.value = choice
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
        {"Top left", "Top right", "Bottom left", "Bottom right"}, -31)
    PositionButtons("zoomSide", zoomSides, "LEFT", "Zoom button edge",
        {"Left", "Right", "Top", "Bottom"}, -145)
    controls.alignButtons = CreateFrame("CheckButton", prefix .. "AlignAddonButtons", parent, "UICheckButtonTemplate")
    controls.alignButtons:SetSize(26, 26)
    controls.alignButtons:SetPoint("TOPLEFT", 280, -259)
    controls.alignButtons:SetHitRectInsets(0, -246, 0, 0)
    SettingsText(parent, "Minimap icon compatibility fix", 310, -265, "GameFontHighlightSmall")
    controls.alignButtons:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Minimap icon compatibility fix", 1, 0.82, 0)
        GameTooltip:AddLine("Helps older addon icons that follow a circular path line up with square or rectangular minimap edges.", 1, 1, 1, true)
        GameTooltip:AddLine("Enabled by default.", 1, 1, 1, true)
        GameTooltip:AddLine("Changes made during combat apply when combat ends.", 0.8, 0.73, 0.6, true)
        GameTooltip:Show()
    end)
    local function HideCompatibilityTooltip(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end
    controls.alignButtons:SetScript("OnLeave", HideCompatibilityTooltip)
    controls.alignButtons:SetScript("OnHide", HideCompatibilityTooltip)
    controls.alignButtons:SetScript("OnClick", function(self)
        AggeMinimapDB = type(AggeMinimapDB) == "table" and AggeMinimapDB or {}
        AggeMinimapDB.alignAddonButtons = self:GetChecked()
        RefreshSettingsControls()
        ApplyLayout()
    end)
    controls.questAreaFix = CreateFrame("CheckButton", prefix .. "QuestAreaFix", parent, "UICheckButtonTemplate")
    controls.questAreaFix:SetSize(26, 26)
    controls.questAreaFix:SetPoint("TOPLEFT", 280, -293)
    controls.questAreaFix:SetHitRectInsets(0, -246, 0, 0)
    SettingsText(parent, "Quest-area outline fix", 310, -299, "GameFontHighlightSmall")
    controls.questAreaFix:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Quest-area outline fix (experimental)", 1, 0.82, 0)
        GameTooltip:AddLine("Hides the decorative quest-area ring that may look circular on a square minimap. Keeps shaded quest areas and icons.", 1, 1, 1, true)
        GameTooltip:AddLine("Disabled by default. Compare on/off while tracking a quest area.", 1, 1, 1, true)
        GameTooltip:AddLine("Changes made during combat apply when combat ends.", 0.8, 0.73, 0.6, true)
        GameTooltip:Show()
    end)
    controls.questAreaFix:SetScript("OnLeave", HideCompatibilityTooltip)
    controls.questAreaFix:SetScript("OnHide", HideCompatibilityTooltip)
    controls.questAreaFix:SetScript("OnClick", function(self)
        AggeMinimapDB = type(AggeMinimapDB) == "table" and AggeMinimapDB or {}
        AggeMinimapDB.questAreaFix = self:GetChecked()
        RefreshSettingsControls()
        ApplyLayout()
    end)
    local footer = parent:CreateTexture(nil, "BACKGROUND")
    footer:SetColorTexture(0.65, 0.45, 0.2, 0.45)
    footer:SetPoint("TOPLEFT", 0, -331)
    footer:SetSize(552, 1)
    SettingsText(parent, "Saved automatically for your account.", 0, -349, "GameFontHighlightSmall")
    SettingsText(parent, "Layout changes apply after combat.", 0, -367, "GameFontHighlightSmall")
    local reset = SettingsButton(parent, prefix .. "ResetDefaults", "Reset defaults", 140, 286, -347)
    reset:SetScript("OnClick", function()
        AggeMinimapDB = type(AggeMinimapDB) == "table" and AggeMinimapDB or {}
        AggeMinimapDB.size = nil
        AggeMinimapDB.width, AggeMinimapDB.height = 200, 200
        AggeMinimapDB.spacing = 0
        AggeMinimapDB.linkAspect, AggeMinimapDB.aspectRatio = true, 1
        AggeMinimapDB.sunCorner, AggeMinimapDB.zoomSide = "TOPLEFT", "LEFT"
        AggeMinimapDB.alignAddonButtons = true
        AggeMinimapDB.questAreaFix = false
        RefreshSettingsControls()
        ApplyLayout()
    end)
    table.insert(settingsControls, controls)
    RefreshSettingsControls()
    return controls
end

local function OpenSettings()
    if not settingsWindow then
        local panel = CreateFrame("Frame", "AggeMinimapSettings", UIParent, "PortraitFrameTemplate")
        if panel.PortraitContainer then panel.PortraitContainer:Hide() end
        if panel.NineSlice and NineSliceUtil then
            NineSliceUtil.ApplyLayoutByName(panel.NineSlice, "ButtonFrameTemplateNoPortrait")
        end
        if panel.TitleContainer then
            panel.TitleContainer:ClearAllPoints()
            panel.TitleContainer:SetPoint("TOPLEFT", 18, -1)
            panel.TitleContainer:SetPoint("TOPRIGHT", -24, -1)
        end
        local title = panel.TitleContainer and panel.TitleContainer.TitleText or panel.TitleText
        title:SetText("AggeMinimap")
        if panel.Bg then
            panel.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
            panel.Bg:SetVertexColor(0.65, 0.65, 0.65)
        end
        panel:SetSize(600, 470)
        panel:SetPoint("CENTER")
        panel:SetFrameStrata("DIALOG")
        -- Raise the whole window together, including its background and child
        -- controls, rather than interleaving with another dialog's children.
        panel:SetToplevel(true)
        panel:EnableMouse(true)
        panel:SetClampedToScreen(true)
        panel:SetMovable(true)
        local titleBar = CreateFrame("Frame", nil, panel)
        titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -2)
        titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -28, -2)
        titleBar:SetHeight(24)
        titleBar:EnableMouse(true)
        titleBar:SetScript("OnMouseDown", function() panel:Raise() end)
        titleBar:RegisterForDrag("LeftButton")
        titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
        titleBar:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)
        panel:SetScript("OnHide", function() panel:StopMovingOrSizing() end)
        local content = CreateFrame("Frame", nil, panel)
        content:SetPoint("TOPLEFT", 24, -55)
        content:SetSize(552, 390)
        CreateSettingsControls(content, "AggeMinimap")
        local done = SettingsButton(panel, nil, "Done", 100, 476, -402)
        done:SetScript("OnClick", function() panel:Hide() end)
        panel:SetScript("OnShow", RefreshSettingsControls)
        table.insert(UISpecialFrames, "AggeMinimapSettings")
        settingsWindow = panel
    end
    RefreshSettingsControls()
    settingsWindow:Show()
    -- Show does not fire OnShow when an already-visible window is reopened.
    settingsWindow:Raise()
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
            content:SetSize(552, 390)
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
    frame:SetPoint("CENTER", map, "CENTER", 0, 0)
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

    map:EnableMouseWheel(true) -- Forever already implements mouse-wheel zoom.
    if map ~= hookedMap then
        map:HookScript("OnMouseUp", function(_, button)
            if button == "RightButton" then
                OpenSettings()
            elseif button == "LeftButton" and map.PingLocation and map.GetEffectiveScale then
                -- Blizzard's handler rejects square/rectangle corners outside
                -- its old circular hit test. Fill only that missing region.
                local cursorX, cursorY = GetCursorPosition()
                local centerX, centerY = map:GetCenter()
                local scale = map:GetEffectiveScale()
                local x, y = cursorX / scale - centerX, cursorY / scale - centerY
                local width, height = GetVisibleMapSize(map)
                if math.abs(x) <= width / 2 and math.abs(y) <= height / 2
                    and x * x + y * y >= (map:GetWidth() / 2) ^ 2 then
                    map:PingLocation(x, y)
                end
            end
        end)
        map:HookScript("OnEnter", QueueAddonButtonScan)
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
        QueueAddonButtonScan()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent(event)
    end
    RegisterSettings()
    ApplyStyle()
    QueueAddonButtonScan()
    if event == "PLAYER_LOGIN" and not announced then
        announced = true
        print("|cff80e5b0AggeMinimap:|r v" .. addonVersion .. " loaded. /amm for settings.")
    end
end)
