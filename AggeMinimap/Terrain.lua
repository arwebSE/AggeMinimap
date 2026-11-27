local _, addon = ...
local tileSize = 1600 / 3

local watchedPinLibraries = setmetatable({}, {__mode = "k"})
function addon.WatchTerrainPins(library, isActive)
    if watchedPinLibraries[library] or type(library.minimapPins) ~= "table"
        or type(library.GetVectorToIcon) ~= "function" or type(library.AddMinimapIconWorld) ~= "function" then return end
    watchedPinLibraries[library] = true
    local watched = setmetatable({}, {__mode = "k"})

    local function WatchPin(pin)
        if watched[pin] or not pin.SetPoint or not library.minimapPins[pin] then return end
        watched[pin] = true
        local placing = false
        hooksecurefunc(pin, "SetPoint", function(self, point, relative, relativePoint)
            local map = Minimap
            local viewport = MinimapCluster and MinimapCluster.MinimapContainer
            if placing or not isActive() or not viewport or library.Minimap ~= map or GetCVarBool("rotateMinimap")
                or point ~= "CENTER" or relative ~= map or relativePoint ~= "CENTER"
                or self:IsProtected() or not library.minimapPins[self] then return end

            local bearing, distance = library:GetVectorToIcon(self)
            local radius = C_Minimap.GetViewRadius()
            if not bearing or not distance or not radius or radius <= 0 then return end
            -- HereBeDragons' world X points west and world Y points north.
            -- Its bearing is zero north and increases toward west.
            local width, height = viewport:GetSize()
            local unitsPerYard = map:GetHeight() / (2 * radius)
            local x = -math.sin(bearing) * distance * unitsPerYard
            local y = math.cos(bearing) * distance * unitsPerYard
            local pinScale = self:GetEffectiveScale() / map:GetEffectiveScale()
            local halfWidth = (width - self:GetWidth() * pinScale) / 2
            local halfHeight = (height - self:GetHeight() * pinScale) / 2
            if halfWidth <= 0 or halfHeight <= 0 then return end
            -- HereBeDragons may show an off-map waypoint as a floating label.
            -- A numbered label on the terrain should denote a real position.
            -- HBD shows the frame again on its next update before placing it.
            if math.abs(x) > halfWidth or math.abs(y) > halfHeight then
                self:Hide()
                return
            end
            placing = true
            self:ClearAllPoints()
            self:SetPoint("CENTER", map, "CENTER", x / pinScale, y / pinScale)
            placing = false
        end)
    end
    hooksecurefunc(library, "AddMinimapIconWorld", function(_, _, pin)
        if pin then WatchPin(pin) end
    end)
    for pin in pairs(library.minimapPins) do WatchPin(pin) end
end

function addon.CreateTerrainRenderer(applyMode)
    if not addon.minimapTileIDs or not C_Minimap or not C_Minimap.SetDrawGroundTextures
        or not C_Minimap.GetDrawGroundTextures or not C_Minimap.GetViewRadius then return end

    local active, previousGround = false, nil
    local layer, tiles, driver
    local lastWidth, lastHeight, lastX, lastY, lastIDs, lastRadius

    local function UpdateZoomHover(area)
        local map = Minimap
        if not map or not map.ZoomIn or not map.ZoomOut then return end
        if InCombatLockdown() and (map.ZoomIn:IsProtected() or map.ZoomOut:IsProtected()) then return end
        -- Check the rectangle geometrically so the terrain strips do not need an
        -- input frame above the existing addon buttons or native zoom controls.
        local show = map:IsVisible() and (area:IsMouseOver()
            or map.ZoomIn:IsMouseOver() or map.ZoomOut:IsMouseOver())
        map.ZoomIn:SetShown(show)
        map.ZoomOut:SetShown(show)
    end

    local function SetSeparateTerrain(value)
        if active == value then return end
        if value then
            previousGround = C_Minimap.GetDrawGroundTextures()
            C_Minimap.SetDrawGroundTextures(false)
        else
            C_Minimap.SetDrawGroundTextures(previousGround)
        end
        active = value
        layer:SetShown(value)
        if not value then UpdateZoomHover(Minimap) end
        applyMode(value)
    end

    local function GetGroundPosition()
        if (IsIndoors and IsIndoors()) or (IsInInstance and IsInInstance())
            or GetCVarBool("rotateMinimap") then return end
        local north, west, _, instance = UnitPosition("player")
        local radius = C_Minimap.GetViewRadius()
        if type(north) ~= "number" or type(west) ~= "number" or not addon.minimapTileIDs[instance]
            or type(radius) ~= "number" or radius <= 0 then return end
        return 32 - west / tileSize, 32 - north / tileSize, addon.minimapTileIDs[instance], radius
    end

    local function CreateTerrainLayer(viewport)
        layer = CreateFrame("Frame", nil, viewport)
        layer:SetAllPoints(viewport)
        layer:SetFrameLevel(math.max(0, Minimap:GetFrameLevel() - 1))
        layer:Hide()
        tiles = {}
        for i = 1, 9 do
            tiles[i] = {texture = layer:CreateTexture(nil, "BACKGROUND")}
        end
    end

    local function DrawTerrain(viewport, width, height, x, y, ids, radius)
        if not layer then CreateTerrainLayer(viewport) end
        -- Match the centered native square's scale on both axes. The extra
        -- width shows more terrain at the same scale.
        local tilePixels = tileSize * height / (2 * radius)
        local halfWidth, halfHeight = width / (2 * tilePixels), height / (2 * tilePixels)
        local left, top = x - halfWidth, y - halfHeight
        local right, bottom = x + halfWidth, y + halfHeight
        local count = 0
        for row = math.floor(top), math.ceil(bottom) - 1 do
            for col = math.floor(left), math.ceil(right) - 1 do
                local id = col >= 0 and col < 64 and row >= 0 and row < 64 and ids[col * 64 + row]
                count = count + 1
                local tile = tiles[count]
                if not id or not tile then return false end
                local texture = tile.texture
                if tile.id ~= id then
                    if texture:SetTexture(id) == false then return false end
                    tile.id = id
                end
                local x1, x2 = math.max(left, col), math.min(right, col + 1)
                local y1, y2 = math.max(top, row), math.min(bottom, row + 1)
                texture:ClearAllPoints()
                texture:SetPoint("TOPLEFT", layer, "TOPLEFT", (x1 - left) * tilePixels, -(y1 - top) * tilePixels)
                texture:SetSize((x2 - x1) * tilePixels, (y2 - y1) * tilePixels)
                texture:SetTexCoord(x1 - col, x2 - col, y1 - row, y2 - row)
                texture:Show()
            end
        end
        for i = count + 1, #tiles do tiles[i].texture:Hide() end
        return count > 0
    end

    local function UpdateTerrain()
        local viewport = MinimapCluster and MinimapCluster.MinimapContainer
        if (active or not InCombatLockdown()) and viewport and Minimap and Minimap:IsVisible() then
            local width, height = viewport:GetSize()
            if width > height then
                local x, y, ids, radius = GetGroundPosition()
                if x then
                    if active and width == lastWidth and height == lastHeight
                        and x == lastX and y == lastY and ids == lastIDs and radius == lastRadius then return end
                    if DrawTerrain(viewport, width, height, x, y, ids, radius) then
                        lastWidth, lastHeight, lastX, lastY, lastIDs, lastRadius = width, height, x, y, ids, radius
                        SetSeparateTerrain(true)
                        return
                    end
                end
            end
        end
        SetSeparateTerrain(false)
    end

    local elapsed = 0
    local stopAfterFallback = false
    local function Tick(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.05 then return end
        elapsed = 0
        local ok, err = pcall(UpdateTerrain)
        if not ok then
            driver:SetScript("OnUpdate", nil)
            SetSeparateTerrain(false)
            if geterrorhandler then geterrorhandler()(err) end
        elseif active then
            UpdateZoomHover(MinimapCluster.MinimapContainer)
        end
        if not active and stopAfterFallback then driver:Hide() end
    end

    return function(wide)
        if wide and not driver then
            driver = CreateFrame("Frame")
            driver:SetScript("OnUpdate", Tick)
        end
        if driver then
            stopAfterFallback = not wide
            driver:SetShown(wide or active)
        end
    end
end
