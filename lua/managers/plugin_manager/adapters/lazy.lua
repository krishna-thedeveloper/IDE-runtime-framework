local M = {}

local generic_fields = {
  url = true,
  on_startup = true,
  on_lazy = true,
  on_event = true,
  on_cmd = true,
  on_keymap = true,
  on_require = true,
}

function M.translate(spec)
  if type(spec[1]) == "string" and spec.url == nil then
    return spec
  end

  local result = { spec.url }

  if spec.on_startup then
    result.lazy = false
  end

  if spec.on_lazy then
    result.event = "VeryLazy"
  elseif spec.on_event then
    result.event = spec.on_event
  end

  if spec.on_cmd then
    result.cmd = spec.on_cmd
  end

  if spec.on_keymap then
    result.keys = spec.on_keymap
  end

  if spec.on_require then
    result.module = spec.on_require
  end

  for k, v in pairs(spec) do
    if not generic_fields[k] and result[k] == nil then
      result[k] = v
    end
  end

  return result
end

function M.translate_all(specs)
  local lazy_specs = {}
  for _, spec in ipairs(specs) do
    table.insert(lazy_specs, M.translate(spec))
  end
  return lazy_specs
end

function M.bootstrap(specs, opts)
  opts = opts or {}
  local lazy_opts = opts.lazy_opts or {}

  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
        { out, "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end

  vim.opt.rtp:prepend(lazypath)

  local lazy_specs = M.translate_all(specs)
  require("lazy").setup(lazy_specs, lazy_opts)
end

return M
