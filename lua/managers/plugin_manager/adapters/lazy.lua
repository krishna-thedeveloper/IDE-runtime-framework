local M = {}

local generic_to_lazy = {
  url = function(_, spec)
    return spec.url
  end,
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

  if spec.cond then
    result.cond = spec.cond
  end

  if spec.dependencies then
    result.dependencies = spec.dependencies
  end

  if spec.build then
    result.build = spec.build
  end

  if spec.version then
    result.version = spec.version
  end

  if spec.priority then
    result.priority = spec.priority
  end

  if spec.name then
    result.name = spec.name
  end

  if spec.config then
    result.config = spec.config
  end

  if spec.opts then
    result.opts = spec.opts
  end

  if spec.opts_extend then
    result.opts_extend = spec.opts_extend
  end

  if spec.main then
    result.main = spec.main
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
