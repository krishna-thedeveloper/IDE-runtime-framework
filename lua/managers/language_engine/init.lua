local config = require("config.language_engines")
local M = {}

local providers = {}
local active = {}

local function load_providers()
  for lang, lang_cfg in pairs(config) do
    providers[lang] = {}
    for _, name in ipairs(lang_cfg.providers) do
      local ok, mod = pcall(require, "managers.language_engine.providers." .. name)
      if ok then
        providers[lang][name] = mod
      end
    end
  end
end

local function load_settings()
  local path = vim.fn.stdpath("config") .. "/language_engines.dat"
  local f = io.open(path, "r")
  if f then
    for line in f:lines() do
      local lang, engine = line:match("^(%S+)%s+(%S+)$")
      if lang and engine and config[lang] then
        active[lang] = engine
      end
    end
    f:close()
  end
end

local function save_settings()
  vim.fn.mkdir(vim.fn.stdpath("config"), "p")
  local f = io.open(vim.fn.stdpath("config") .. "/language_engines.dat", "w")
  if f then
    for lang, engine in pairs(active) do
      f:write(lang .. " " .. engine .. "\n")
    end
    f:close()
  end
end

function M.get(language)
  return active[language] or (config[language] and config[language].default) or nil
end

function M.is_active(language, engine)
  return M.get(language) == engine
end

function M.set(language, engine)
  if not config[language] then
    return false, "No such language: " .. language
  end
  if not providers[language] or not providers[language][engine] then
    return false, "No such engine '" .. engine .. "' for " .. language
  end
  active[language] = engine
  save_settings()
  return true
end

function M.provider(language)
  local name = M.get(language)
  if name and providers[language] and providers[language][name] then
    return providers[language][name]
  end
  return nil
end

load_providers()
load_settings()

vim.api.nvim_create_user_command("LanguageEngine", function(opts)
  local args = vim.split(opts.args or "", "%s+")
  if #args == 1 and args[1] == "" then args = {} end
  if #args == 0 then
    local lines = {}
    for lang in pairs(config) do
      local p = M.provider(lang)
      table.insert(lines, lang .. ": " .. (p and p.label or M.get(lang) or "default"))
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  elseif #args == 2 then
    local lang, engine = args[1], args[2]
    local ok, err = M.set(lang, engine)
    if ok then
      vim.notify(lang .. " engine set to: " .. engine .. ". Restart Neovim to apply.", vim.log.levels.INFO)
    else
      vim.notify(err, vim.log.levels.ERROR)
    end
  else
    vim.notify("Usage: LanguageEngine [language] [engine]", vim.log.levels.ERROR)
  end
end, { nargs = "*" })

return M
