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
    function Minimap:SetMaskTexture(value)
        assert(not combat, 'mask changed in combat')
        self.mask = value
        masks = masks + 1
    end
    function Minimap:EnableMouseWheel(value) self.wheel = value end
    function Minimap:GetFrameLevel() return 4 end
    Minimap.OnMouseUp = function() end
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
    GameTimeFrame = Region()
    AddonCompartmentFrame = Region()
    TimeManagerClockButton = Region()
    MinimapZoneText = Region()
    function MinimapCluster:SetHeaderUnderneath(value)
        self.ZoneTextButton:ClearAllPoints()
        self.ZoneTextButton:SetPoint(value and 'BOTTOM' or 'TOP')
    end
    function MinimapCluster:SetEditModeScale(value)
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
MinimapCluster:UpdateMinimapConfig()
assert(Minimap.mask ~= 'round')
assert(MinimapCompassTextureUnderlay.alpha == 0)
Fire('PLAYER_ENTERING_WORLD')
Fire('PLAYER_ENTERING_WORLD')
assert(#frames == 2 and hooks == 4, 'must not duplicate frames or hooks')
assert(Minimap.OnMouseUp == click and Minimap.OnMouseWheel == wheel)
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
assert(MinimapCluster.width == 202 and MinimapCluster.height == 227, 'tight default bounds')
assert(MinimapCluster.MinimapContainer.width == 198)
AggeMinimapDB = {spacing = 20}
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
SlashCmdList.AGGEMINIMAP()
assert(AggeMinimapSettings.shown and #UISpecialFrames == 1)
assert(AggeMinimapSpacing.low == 0 and AggeMinimapSpacing.high == 40)
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
        assert(x >= AggeMinimapDB.spacing - 0.001 and right <= MinimapCluster.width - AggeMinimapDB.spacing + 0.001)
        previousRight = right
    end
    assert(Minimap.width == Minimap.height, 'map must be square')
end
for _, size in ipairs({160, 198, 260, 360}) do
    for _, scale in ipairs({0.5, 1, 1.5, 2}) do
        AggeMinimapDB.size = size
        MinimapCluster:SetEditModeScale(scale)
        for _, underneath in ipairs({false, true}) do
            MinimapCluster:SetHeaderUnderneath(underneath)
            CheckSingleRow()
        end
    end
end
assert(MinimapZoneText.wordWrap == false and MinimapZoneText.nonSpaceWrap == false)
AggeMinimapSize:SetValue(240)
assert(Minimap.width == 240 and Minimap.height == 240 and AggeMinimapDB.size == 240)
assert(AggeMinimapSizeText.text == 'Map size: 240 × 240')
InstallSettings()
Fire('ADDON_LOADED', 'Blizzard_Settings_Shared')
assert(categoryCount == 1 and not AggeMinimapOptions.shown)
AggeMinimapOptions:Show()
assert(AggeMinimapOptionsSize.value == 240)
assert(AggeMinimapOptionsSpacing.value == AggeMinimapDB.spacing)
AggeMinimapOptionsSize:SetValue(250)
assert(AggeMinimapDB.size == 250 and Minimap.width == 250)
assert(AggeMinimapSize.value == 250, 'Options changes must sync to /amm')
AggeMinimapSpacing:SetValue(9)
assert(AggeMinimapOptionsSpacing.value == 9, '/amm changes must sync to Options')
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
console.log('PASS: Lua 5.1 syntax, manifests, mask, lifecycle, square layouts, sliders, combat deferral, Options registration, synchronized settings views, and single login message.');
