local M = {}

local generic_fields = {
  url = true,
  trigger = true,
  category = true,
  optional = true,
  metadata = true,
  condition = true,
}

function M.translate(spec)
  if not spec.url then
    return spec
  end

  local result = { spec.url }

  if spec.trigger then
    local t = spec.trigger

    if t.startup then
      result.lazy = false
    end

    if t.lazy then
      result.event = "VeryLazy"
    elseif t.event then
      result.event = t.event
    end

    if t.cmd then
      result.cmd = t.cmd
    end

    if t.keymap then
      result.keys = t.keymap
    end

    if t.require then
      result.module = t.require
    end

    if t.ft then
      result.ft = t.ft
    end
  end

  if spec.condition then
    result.cond = spec.condition
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

function M.load_plugin(name)
  pcall(require("lazy").load, { plugins = name })
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
