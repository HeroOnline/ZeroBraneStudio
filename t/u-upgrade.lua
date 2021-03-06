if ide.wxver >= "3.1" then
  ok(wx.wxFileName().ShouldFollowLink ~= nil, "wxlua/wxwidgets 3.1+ includes wxFileName().ShouldFollowLink.")
end

if ide.wxver >= "3.1.4" then
  ok(ide:GetEditorNotebook():GetActiveTabCtrl() ~= nil, "wxlua/wxwidgets 3.1.4+ includes wxAuiNotebook().GetActiveTabCtrl.")
end

local function waitToComplete(bid)
  while wx.wxProcess.Exists(bid) do
    wx.wxSafeYield()
    wx.wxWakeUpIdle()
    wx.wxMilliSleep(100)
  end
  wx.wxSafeYield()
  wx.wxWakeUpIdle() -- wake up one more time to process messages (if any)
end

local modules = {
  ["require([[lfs]])._VERSION"] = "LuaFileSystem 1.6.3",
  ["require([[lpeg]]).version()"] = "1.0.0",
  ["require([[ssl]])._VERSION"] = "0.9",
}
local envall = {'LUA_CPATH', 'LUA_CPATH_5_2', 'LUA_CPATH_5_3'}
local envs = {}
-- save and unset all LUA_CPATH* environmental variables, as we'll only be setting LUA_CPATH
-- for simplicity, so LUA_CPATH_5_2 and _5_3 need to be cleared as they take precedence
for _, env in ipairs(envall) do envs[env] = os.getenv(env); wx.wxUnsetEnv(env) end
for _, luaver in ipairs({"", "5.2", "5.3"}) do
  local clibs = ide.osclibs:gsub("clibs", "clibs"..luaver:gsub("%.",""))
  wx.wxSetEnv('LUA_CPATH', clibs)

  for mod, modver in pairs(modules) do
    local res = ""
    local cmd = ('"%s" -e "print(%s)"'):format(ide.interpreters.luadeb:fexepath(luaver), mod)
    local pid, err = ide:ExecuteCommand(cmd, "", function(s) res = res..s end)
    if pid then waitToComplete(pid) end
    -- when there is an error, show the error instead of the expected value
    is((pid and res or err):gsub("%s+$",""), modver,
      ("Checking module version (%s) with Lua%s."):format(mod:match("%[%[(%w+)%]%]"), luaver))
  end
end
for env, val in pairs(envs) do
  if val then wx.wxSetEnv(env, val) else wx.wxUnsetEnv(env) end
end

is(jit and jit.version, "LuaJIT 2.0.4", "Using LuaJIT with the expected version.")

if ide.osname == "Windows" then
  ok(jit and pcall(require, 'fs'), "fs module is loaded.")
end

require "lpeg"
local lexpath = package.searchpath("lexlpeg", ide.osclibs)
ok(package.loadlib(lexpath, "GetLexerCount") ~= nil, "LexLPeg lexer is loaded.")
