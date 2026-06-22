local base = require("managers.base")

local completion = base.create_adapter_manager({
  state_file = vim.fn.stdpath("state") .. "/completion.txt",
  adapter_prefix = "managers.completion.adapters",
  desc = "Completion",
  key = "c",
})

local base_use = completion.use
function completion.use(name)
  base_use(name)
  pcall(vim.lsp.config, "*", { capabilities = completion.get_capabilities() })
end

function completion.get_capabilities()
  local adapter = completion.get_active_adapter()
  if adapter and adapter.get_capabilities then
    return adapter.get_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

return completion
