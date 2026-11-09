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

const runtimePath = path.join(root, 'tests/runtime.lua');
parse(fs.readFileSync(runtimePath, 'utf8'), { luaVersion: '5.1' });
for (const mode of ['normal', 'delayed']) {
  const state = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(state);
  try {
    let status = lauxlib.luaL_loadfile(state, to_luastring(runtimePath));
    if (status === lua.LUA_OK) {
      lua.lua_pushstring(state, to_luastring(mode));
      status = lua.lua_pcall(state, 1, 0, 0);
    }
    if (status !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
  } finally {
    lua.lua_close(state);
  }
}
console.log('PASS: Lua 5.1 syntax, manifests, textures, and Lua runtime tests.');
