local M = {
  label = "Blink",
}

function M.get_capabilities()
  return require("blink.cmp").get_lsp_capabilities()
end

return M
