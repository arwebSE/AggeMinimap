const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const parse = require('luaparse').parse;
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'AggeMinimap/AggeMinimap.lua'), 'utf8');
parse(source, { luaVersion: '5.1' });
for (const name of ['AggeMinimap.toc', 'AggeMinimap_Camelot.toc']) {
  const toc = fs.readFileSync(path.join(root, 'AggeMinimap', name), 'utf8');
  assert.match(toc, /^## Interface: 16001$/m);
  assert.match(toc, /^## Category: Map$/m);
  assert.ok(toc.includes('## IconTexture: Interface\\AddOns\\AggeMinimap\\Icon.tga'));
  const files = toc.split(/\r?\n/).filter(line => line && !line.startsWith('#'));
  assert.deepEqual(files, ['AggeMinimap.lua']);
  for (const file of files) assert.ok(fs.existsSync(path.join(root, 'AggeMinimap', file)));
}
const mask = fs.readFileSync(path.join(root, 'AggeMinimap/Square.tga'));
assert.equal(mask[2], 2);
assert.equal(mask.readUInt16LE(12), 8);
assert.equal(mask.readUInt16LE(14), 8);
assert.equal(mask[16], 32);
assert.equal(mask.length, 274);
assert.ok(mask.subarray(18).every(value => value === 255));
const icon = fs.readFileSync(path.join(root, 'AggeMinimap/Icon.tga'));
assert.equal(icon[2], 2);
assert.equal(icon.readUInt16LE(12), 128);
assert.equal(icon.readUInt16LE(14), 128);
assert.equal(icon[16], 32);
assert.equal(icon[17], 40);
assert.equal(icon.length, 18 + 128 * 128 * 4);

const setup = `
SlashCmdList = {}
UISpecialFrames = {}
C_AddOns = {GetAddOnMetadata = function(name, key)
    assert(name == 'AggeMinimap' and key == 'Version')
    return 'test-version'
end}
local frames = {}
local combat = false
local hooks = 0
local messages = {}
function print(message) table.insert(messages, message) end
local categoryCount = 0
local function InstallSettings()
    Settings = {
        RegisterCanvasLayoutCategory = function(panel, name)
            assert(name == 'AggeMinimap')
            return {panel = panel, name = name}
        end,
        RegisterAddOnCategory = function(category)
            categoryCount = categoryCount + 1
            assert(category.panel == AggeMinimapOptions)
        end,
    }
end
local function Region()
    return setmetatable({ alpha = 1, points = {}, events = {}, width = 198, height = 198, scale = 1 }, { __index = {
        SetAlpha = function(self, value) self.alpha = value end,
        SetVertexColor = function(self, r, g, b, a) self.vertexAlpha = a end,
        SetPoint = function(self, ...) table.insert(self.points, {...}) end,
        SetHeight = function(self, value) self.height = value end,
        SetWidth = function(self, value) self.width = value end,
        SetSize = function(self, w, h) self.width, self.height = w, h end,
        GetSize = function(self) return self.width, self.height end,
        GetScale = function(self) return self.scale end,
        SetScale = function(self, value) self.scale = value end,
        SetWordWrap = function(self, value) self.wordWrap = value end,
        SetNonSpaceWrap = function(self, value) self.nonSpaceWrap = value end,
        ClearAllPoints = function(self) self.points = {} end,
        GetPoint = function(self) return table.unpack(self.points[1] or {"TOP"}) end,
        SetFixedSize = function(self, w, h) self.fixedWidth, self.fixedHeight = w, h end,
        SetHitRectInsets = function() end,
        SetText = function(self, value) self.text = value end,
        GetName = function(self) return self.name end,
        SetFrameStrata = function() end,
        SetClampedToScreen = function() end,
        SetMovable = function(self, value) self.movable = value end,
        RegisterForDrag = function(self, button) self.dragButton = button end,
        StartMoving = function(self) self.moving = true end,
        StopMovingOrSizing = function(self) self.moving = false end,
        SetAllPoints = function() end,
        SetAtlas = function() end,
        SetTexture = function() end,
        SetJustifyH = function() end,
        SetTextColor = function() end,
        SetMinMaxValues = function(self, low, high) self.low, self.high = low, high end,
        SetValueStep = function() end,
        SetObeyStepOnDrag = function() end,
        SetValue = function(self, value)
            self.value = value
            if self.OnValueChanged then self:OnValueChanged(value) end
        end,
        Show = function(self)
            local wasShown = self.shown
            self.shown = true
            if not wasShown and self.OnShow then self:OnShow() end
        end,
        Hide = function(self) self.shown = false end,
        CreateFontString = function() return Region() end,
        EnableMouse = function() end,
        SetColorTexture = function() end,
        SetFrameLevel = function(self, level) self.level = level end,
        RegisterEvent = function(self, event) self.events[event] = true end,
        UnregisterEvent = function(self, event) self.events[event] = nil end,
        SetScript = function(self, script, fn) self[script] = fn end,
        HookScript = function(self, script, fn)
            local original = self[script]
            self.scriptHooks = (self.scriptHooks or 0) + 1
            self[script] = function(...)
                if original then original(...) end
                fn(...)
            end
        end,
        CreateTexture = function(self)
            local t = Region()
            self.textures = (self.textures or 0) + 1
            return t
        end,
    } })
end
function CreateFrame(_, name, parent, template)
    local f = Region()
    f.name = name
    if name then _G[name] = f end
    if template == 'BasicFrameTemplateWithInset' then f.TitleText = Region() end
    if template == 'PortraitFrameTemplate' then
        f.TitleContainer = Region()
        f.TitleContainer.TitleText = Region()
        f.PortraitContainer = Region()
        f.Bg = Region()
        f.NineSlice = Region()
    end
    if template == 'OptionsSliderTemplate' then
        _G[name .. 'Low'] = Region()
        _G[name .. 'High'] = Region()
        _G[name .. 'Text'] = Region()
    end
    f.parent = parent
    table.insert(frames, f)
    return f
end
function InCombatLockdown() return combat end
function hooksecurefunc(target, key, callback)
    local original = target[key]
    target[key] = function(...) original(...); callback(...) end
    hooks = hooks + 1
end
local masks = 0
local function MakeMinimap()
    Minimap = Region()
    Minimap.ZoomIn = Region()
    Minimap.ZoomOut = Region()
    Minimap.ZoomHitArea = Region()
    function Minimap:SetMaskTexture(value)
        assert(not combat, 'mask changed in combat')
        self.mask = value
        masks = masks + 1
    end
    function Minimap:EnableMouseWheel(value) self.wheel = value end
    function Minimap:GetFrameLevel() return 4 end
    Minimap.zoom, Minimap.zoomUpdates = 0, 0
    function Minimap:GetZoom() return self.zoom end
    function Minimap:GetZoomLevels() return 6 end
    function Minimap:SetZoom(value)
        assert(not combat, 'render refresh must wait until combat ends')
        assert(value >= 0 and value < self:GetZoomLevels(), 'zoom must stay in bounds')
        self.zoom = value
        self.zoomUpdates = self.zoomUpdates + 1
        self.renderWidth, self.renderHeight = self.width, self.height
    end
    Minimap.OnMouseUp = function(self) self.nativeClicks = (self.nativeClicks or 0) + 1 end
    Minimap.OnMouseWheel = function() end
    MinimapBackdrop = Region()
    MinimapCompassTexture = Region()
    MinimapCompassTextureUnderlay = Region()
    MinimapCluster = Region()
    MinimapCluster.MinimapContainer = Region()
    MinimapCluster.ZoneTextButton = Region()
    MinimapCluster.ZoneTextButton.StateTexture = Region()
    MinimapCluster.ZoneTextButton.AddTexture = Region()
    MinimapCluster.Tracking = Region()
    MinimapCluster.IndicatorFrame = Region()
    MinimapCluster.DielFrame = Region()
    GameTimeFrame = Region()
    AddonCompartmentFrame = Region()
    TimeManagerClockButton = Region()
    MinimapZoneText = Region()
    function MinimapCluster:SetHeaderUnderneath(value)
        self.ZoneTextButton:ClearAllPoints()
        self.ZoneTextButton:SetPoint(value and 'BOTTOM' or 'TOP')
    end
    function MinimapCluster:SetEditModeScale(value)
        self.DielFrame:SetScale(math.max(1, value))
        self.DielFrame:ClearAllPoints()
        self.DielFrame:SetPoint('CENTER', self, 'CENTER', 63, 72)
        self.MinimapContainer.scale = value
    end
    function MinimapCluster:Layout()
        self:SetSize(self.fixedWidth or 300, self.fixedHeight or 300)
    end
    function MinimapCluster:UpdateMinimapConfig()
        Minimap.mask = 'round'
        MinimapCompassTextureUnderlay.alpha = 1
    end
end
`;
const checks = `
local events = frames[1]
local function Fire(event, name)
    if events.events[event] then events:OnEvent(event, name) end
end
Fire('ADDON_LOADED', 'Unrelated')
assert(masks == 0)
Fire('ADDON_LOADED', 'AggeMinimap')
if not Minimap then
    assert(#frames == 1, 'must tolerate delayed minimap load')
    MakeMinimap()
    Fire('ADDON_LOADED', 'Blizzard_Minimap')
end
assert(Minimap.mask == 'Interface\\\\AddOns\\\\AggeMinimap\\\\Square.tga')
assert(Minimap.wheel == true)
assert(GetMinimapShape() == 'SQUARE')
assert(hooks == 4)
assert(#frames == 2 and frames[2].textures == 4)
assert(frames[2].level == 5)
assert(MinimapCompassTexture.alpha == 0)
assert(MinimapCluster.ZoneTextButton.StateTexture.alpha == 0)
MinimapCluster.ZoneTextButton.AddTexture:SetAlpha(0.2)
assert(MinimapCluster.ZoneTextButton.AddTexture.vertexAlpha == 0, 'hover trim must stay transparent')
assert(MinimapCluster.Tracking.alpha == 1)
assert(MinimapCluster.IndicatorFrame.alpha == 1)
assert(MinimapBackdrop.alpha == 1)
local click, wheel = Minimap.OnMouseUp, Minimap.OnMouseWheel
local zoomUpdates = Minimap.zoomUpdates
MinimapCluster:UpdateMinimapConfig()
assert(Minimap.mask ~= 'round')
assert(MinimapCompassTextureUnderlay.alpha == 0)
Fire('PLAYER_ENTERING_WORLD')
Fire('PLAYER_ENTERING_WORLD')
assert(#frames == 2 and hooks == 4, 'must not duplicate frames or hooks')
assert(Minimap.OnMouseUp == click and Minimap.OnMouseWheel == wheel)
assert(Minimap.zoomUpdates == zoomUpdates, 'unchanged layouts must not trigger render refresh')
assert(Minimap.scriptHooks == 1, 'right-click hook must only be installed once')
combat = true
local before = masks
Fire('PLAYER_ENTERING_WORLD')
MinimapCluster:UpdateMinimapConfig()
assert(masks == before, 'styling must wait for combat to end')
assert(events.events.PLAYER_REGEN_ENABLED)
combat = false
Fire('PLAYER_REGEN_ENABLED')
assert(Minimap.mask ~= 'round')
assert(not events.events.PLAYER_REGEN_ENABLED)
assert(SLASH_AGGEMINIMAP1 == '/amm' and type(SlashCmdList.AGGEMINIMAP) == 'function')
assert(Minimap.width == 200 and Minimap.height == 200, 'new profiles default to 200 x 200')
assert(MinimapCluster.width == 200 and MinimapCluster.height == 223, 'default spacing must be zero')
AggeMinimapDB = {size = 198, spacing = 2}
Fire('PLAYER_ENTERING_WORLD')
assert(MinimapCluster.width == 202 and MinimapCluster.height == 227, 'legacy square size must be preserved')
assert(MinimapCluster.MinimapContainer.width == 198)
AggeMinimapDB = {size = 198, spacing = 20}
Fire('PLAYER_ENTERING_WORLD')
assert(MinimapCluster.width == 238 and MinimapCluster.height == 281)
MinimapCluster:SetHeaderUnderneath(true)
assert(MinimapCluster.MinimapContainer.points[1][5] == -20)
assert(MinimapCluster.ZoneTextButton.points[1][5] == -238)
MinimapCluster:SetHeaderUnderneath(false)
assert(MinimapCluster.MinimapContainer.points[1][5] == -63)
MinimapCluster:SetEditModeScale(1.5)
assert(MinimapCluster.width == 337 and MinimapCluster.height == 380)
MinimapCluster:Layout()
assert(MinimapCluster.width == 337, 'Edit Mode layout must keep compact size')
combat = true
AggeMinimapDB.spacing = 0
MinimapCluster:SetEditModeScale(1)
assert(MinimapCluster.width == 337, 'layout must wait until combat ends')
combat = false
Fire('PLAYER_REGEN_ENABLED')
assert(MinimapCluster.width == 198 and MinimapCluster.height == 221)
for _, invalid in ipairs({false, 'bad', 100, -10}) do
    AggeMinimapDB.spacing = invalid
    Fire('PLAYER_ENTERING_WORLD')
    assert(MinimapCluster.width >= 198 and MinimapCluster.width <= 278)
end
AggeMinimapDB.spacing = 2
Minimap:OnMouseUp('LeftButton')
assert(not AggeMinimapSettings, 'left-click must not open options')
Minimap:OnMouseUp('RightButton')
assert(Minimap.nativeClicks == 2, 'native map click handler must be preserved')
assert(AggeMinimapSettings.shown and #UISpecialFrames == 1)
assert(AggeMinimapSettings.movable)
for _, frame in ipairs(frames) do
    if frame.parent == AggeMinimapSettings and frame.OnDragStart then
        assert(frame.dragButton == 'LeftButton')
        frame:OnDragStart()
        assert(AggeMinimapSettings.moving)
        frame:OnDragStop()
        assert(not AggeMinimapSettings.moving)
    end
end
assert(AggeMinimapSpacing.low == -20 and AggeMinimapSpacing.high == 40)
assert(AggeMinimapLinkAspect.selected, 'aspect ratio must be linked by default')
AggeMinimapSpacing:SetValue(12)
assert(AggeMinimapDB.spacing == 12)
assert(MinimapCluster.width == 222 and MinimapCluster.height == 257)
assert(AggeMinimapSpacingText.text == 'Spacing: 12 px')
SlashCmdList.AGGEMINIMAP()
assert(#UISpecialFrames == 1, 'reopen must reuse the settings window')
combat = true
AggeMinimapSpacing:SetValue(5)
assert(MinimapCluster.width == 222)
combat = false
Fire('PLAYER_REGEN_ENABLED')
assert(MinimapCluster.width == 208 and AggeMinimapDB.spacing == 5)
local function CheckSingleRow()
    local function CheckAnchor(frame, anchor, relativeAnchor, x, y)
        assert(#frame.points == 1, 'edge controls must have one anchor')
        local point = frame.points[1]
        assert(point[1] == anchor and point[2] == Minimap and point[3] == relativeAnchor)
        assert(point[4] == x and point[5] == y, 'edge controls must stay aligned with the square')
    end
    local side = AggeMinimapDB.zoomSide or 'LEFT'
    local vertical = side == 'LEFT' or side == 'RIGHT'
    local inset = (side == 'RIGHT' or side == 'TOP') and -12 or 12
    local x, y = vertical and inset or 0, vertical and 0 or inset
    CheckAnchor(Minimap.ZoomIn, 'CENTER', side, x + (vertical and 0 or -10), y + (vertical and 10 or 0))
    CheckAnchor(Minimap.ZoomOut, 'CENTER', side, x + (vertical and 0 or 10), y + (vertical and -10 or 0))
    CheckAnchor(Minimap.ZoomHitArea, 'CENTER', side, x, y)
    local corner = AggeMinimapDB.sunCorner or 'TOPLEFT'
    CheckAnchor(MinimapCluster.DielFrame, corner, corner, corner:find('LEFT') and 4 or -4, corner:find('TOP') and -4 or 4)
    assert(Minimap.ZoomHitArea.width == (vertical and 40 or 48) and Minimap.ZoomHitArea.height == (vertical and 48 or 40))
    assert(MinimapCluster.DielFrame.scale == MinimapCluster.MinimapContainer.scale)
    local previousRight
    local centerY
    for _, frame in ipairs({MinimapCluster.Tracking, MinimapCluster.ZoneTextButton,
            TimeManagerClockButton, GameTimeFrame, AddonCompartmentFrame}) do
        local point = frame.points[1]
        assert(point[1] == 'TOPLEFT' and point[2] == MinimapCluster)
        local x, top = point[4] * frame.scale, point[5] * frame.scale
        local right = x + frame.width * frame.scale
        local center = top - frame.height * frame.scale / 2
        assert(not centerY or math.abs(centerY - center) < 0.001, 'all controls must share one row')
        centerY = center
        assert(not previousRight or x >= previousRight, 'header controls must not overlap')
        local outerSpacing = math.max(0, AggeMinimapDB.spacing)
        assert(x >= outerSpacing - 0.001 and right <= MinimapCluster.width - outerSpacing + 0.001)
        previousRight = right
    end
    assert(Minimap.width == MinimapCluster.MinimapContainer.width and Minimap.height == MinimapCluster.MinimapContainer.height)
    assert(Minimap.renderWidth == Minimap.width and Minimap.renderHeight == Minimap.height, 'render surface must follow frame size')
    assert(#Minimap.points == 1 and Minimap.points[1][1] == 'CENTER' and Minimap.points[1][2] == MinimapCluster.MinimapContainer)
    assert(frames[2].width == Minimap.width + 2 and frames[2].height == Minimap.height + 2, 'border must follow both map dimensions')
    assert(#frames[2].points == 1 and frames[2].points[1][1] == 'CENTER' and frames[2].points[1][2] == Minimap)
end
for _, size in ipairs({160, 198, 260, 360}) do
    for _, scale in ipairs({0.5, 1, 1.5, 2}) do
        AggeMinimapDB.size = size
        MinimapCluster:SetEditModeScale(scale)
        for _, underneath in ipairs({false, true}) do
            MinimapCluster:SetHeaderUnderneath(underneath)
            for _, corner in ipairs({'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT'}) do
                _G['AggeMinimapsunCorner' .. corner]:OnClick()
                for _, side in ipairs({'LEFT', 'RIGHT', 'TOP', 'BOTTOM'}) do
                    _G['AggeMinimapzoomSide' .. side]:OnClick()
                    CheckSingleRow()
                end
            end
        end
    end
end
assert(MinimapZoneText.wordWrap == false and MinimapZoneText.nonSpaceWrap == false)
AggeMinimapWidth:SetValue(240)
assert(Minimap.width == 240 and Minimap.height == 240 and AggeMinimapDB.width == 240)
assert(AggeMinimapWidthText.text == 'Width: 240 px')
InstallSettings()
Fire('ADDON_LOADED', 'Blizzard_Settings_Shared')
assert(categoryCount == 1 and not AggeMinimapOptions.shown)
AggeMinimapOptions:Show()
assert(AggeMinimapOptionssunCornerBOTTOMRIGHT.selected)
AggeMinimapOptionssunCornerTOPRIGHT:OnClick()
assert(AggeMinimapDB.sunCorner == 'TOPRIGHT')
assert(AggeMinimapsunCornerTOPRIGHT.selected)
combat = true
AggeMinimapOptionszoomSideRIGHT:OnClick()
assert(Minimap.ZoomIn.points[1][3] == 'BOTTOM', 'position changes must wait for combat to end')
combat = false
Fire('PLAYER_REGEN_ENABLED')
assert(Minimap.ZoomIn.points[1][3] == 'RIGHT')
CheckSingleRow()
assert(AggeMinimapOptionsWidth.value == 240 and AggeMinimapOptionsHeight.value == 240)
assert(AggeMinimapOptionsSpacing.value == AggeMinimapDB.spacing)
AggeMinimapOptionsWidth:SetValue(250)
assert(AggeMinimapDB.width == 250 and Minimap.width == 250 and Minimap.height == 250)
assert(AggeMinimapWidth.value == 250, 'Options changes must sync to /amm')
AggeMinimapSpacing:SetValue(9)
assert(AggeMinimapOptionsSpacing.value == 9, '/amm changes must sync to Options')
AggeMinimapLinkAspect:OnClick()
assert(not AggeMinimapOptionsLinkAspect.selected, 'link toggle must sync between views')
AggeMinimapHeight:SetValue(200)
assert(Minimap.width == 250 and Minimap.height == 200, 'unlinked height must preserve width')
AggeMinimapOptionsWidth:SetValue(300)
assert(Minimap.width == 300 and Minimap.height == 200, 'unlinked width must preserve height')
AggeMinimapOptionsLinkAspect:OnClick()
AggeMinimapHeight:SetValue(240)
assert(Minimap.width == 360 and Minimap.height == 240, 'link must preserve the current 3:2 ratio')
AggeMinimapWidth:SetValue(160)
assert(Minimap.width == 240 and Minimap.height == 160, 'linked minimum must constrain both dimensions')
AggeMinimapHeight:SetValue(360)
assert(Minimap.width == 360 and Minimap.height == 240, 'linked maximum must constrain both dimensions')
AggeMinimapLinkAspect:OnClick()
AggeMinimapWidth:SetValue(160)
AggeMinimapHeight:SetValue(360)
for _, scale in ipairs({0.5, 1, 2}) do
    MinimapCluster:SetEditModeScale(scale)
    for _, spacing in ipairs({-20, -5, 0, 40}) do
        AggeMinimapSpacing:SetValue(spacing)
        for _, underneath in ipairs({false, true}) do
            MinimapCluster:SetHeaderUnderneath(underneath)
            CheckSingleRow()
            assert(MinimapCluster.width >= Minimap.width * scale, 'negative spacing must contain map width')
            assert(MinimapCluster.height >= Minimap.height * scale, 'negative spacing must contain map height')
            local mapTop = -MinimapCluster.MinimapContainer.points[1][5] * scale
            assert(mapTop >= 0 and mapTop + Minimap.height * scale <= MinimapCluster.height + 0.001)
        end
    end
end
combat = true
AggeMinimapWidth:SetValue(210)
assert(Minimap.width == 160 and AggeMinimapDB.width == 210, 'dimension changes must defer in combat')
combat = false
Fire('PLAYER_REGEN_ENABLED')
assert(Minimap.width == 210 and Minimap.height == 360)
AggeMinimapSpacing:SetValue(-100)
assert(AggeMinimapDB.spacing == -20)
Fire('PLAYER_ENTERING_WORLD')
assert(AggeMinimapWidth.value == 210 and AggeMinimapHeight.value == 360 and not AggeMinimapLinkAspect.selected,
    'saved rectangle and link state must survive refresh')
combat = true
AggeMinimapOptionsResetDefaults:OnClick()
assert(AggeMinimapDB.width == 200 and AggeMinimapDB.height == 200 and AggeMinimapDB.spacing == 0)
assert(AggeMinimapDB.size == nil and AggeMinimapLinkAspect.selected)
assert(AggeMinimapWidth.value == 200 and AggeMinimapOptionsHeight.value == 200, 'reset must sync both settings views')
assert(AggeMinimapsunCornerTOPLEFT.selected and AggeMinimapzoomSideLEFT.selected)
assert(Minimap.width == 210 and Minimap.height == 360, 'reset must defer layout in combat')
combat = false
Fire('PLAYER_REGEN_ENABLED')
assert(Minimap.width == 200 and Minimap.height == 200)
CheckSingleRow()
AggeMinimapWidth:SetValue(250)
AggeMinimapResetDefaults:OnClick()
assert(Minimap.width == 200 and Minimap.height == 200, 'standalone reset must restore dimensions')
for _, zoom in ipairs({0, 2, 5}) do
    Minimap.zoom = zoom
    for _, size in ipairs({200, 230, 231, 250, 300, 360, 200}) do
        AggeMinimapWidth:SetValue(size)
        assert(Minimap:GetZoom() == zoom, 'resizing must preserve the user zoom at both limits')
        assert(Minimap.renderWidth == size and Minimap.renderHeight == size, 'large maps must refresh native rendering')
    end
end
local refreshes = Minimap.zoomUpdates
MinimapCluster:SetEditModeScale(1.5)
assert(Minimap.zoomUpdates == refreshes + 2, 'Edit Mode scale changes must refresh rendering')
MinimapCluster:Layout()
assert(Minimap.zoomUpdates == refreshes + 2, 'repeated layouts must not refresh rendering')
AggeMinimapLinkAspect:OnClick()
for _, dimensions in ipairs({{360, 160}, {160, 360}, {300, 200}, {200, 300}}) do
    AggeMinimapWidth:SetValue(dimensions[1])
    AggeMinimapHeight:SetValue(dimensions[2])
    assert(Minimap.renderWidth == dimensions[1] and Minimap.renderHeight == dimensions[2],
        'wide and tall rectangles must refresh both render dimensions')
    assert(Minimap:GetZoom() == 5, 'rectangle resizing must preserve zoom')
    CheckSingleRow()
end
AggeMinimapOptions:Hide()
AggeMinimapOptions:Show()
Fire('PLAYER_LOGIN')
Fire('PLAYER_LOGIN')
Fire('PLAYER_ENTERING_WORLD')
assert(categoryCount == 1, 'category must only register once')
assert(#messages == 1 and messages[1]:find('Loaded. /amm for settings.', 1, true))
assert(messages[1]:find('AggeMinimap vtest-version:', 1, true), 'message must use addon metadata version')
`;
for (const delayed of [false, true]) {
  const state = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(state);
  const program = setup + (delayed ? '' : '\nMakeMinimap()\n') +
    '\nlocal function LoadAddon(...)\n' + source + '\nend\nLoadAddon("AggeMinimap")\n' + checks;
  const status = lauxlib.luaL_dostring(state, to_luastring(program));
  if (status !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
  lua.lua_close(state);
}
console.log('PASS: Lua 5.1 syntax, manifests, mask, lifecycle, rectangular layouts, legacy sizes, aspect linking and bounds, negative spacing, combat deferral, synchronized settings, and login message.');
