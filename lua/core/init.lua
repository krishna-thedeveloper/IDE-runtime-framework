local ok, err = pcall(function()
  require("core.options")
  require("core.autocmds")
  require("core.keymaps")
end)

if not ok then
  vim.api.nvim_echo({ { "Core init error: " .. tostring(err), "ErrorMsg" } }, true, {})
  return
end

require("config.lazy")
