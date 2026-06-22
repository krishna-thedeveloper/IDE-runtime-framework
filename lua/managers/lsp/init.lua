local M = {}

function M.setup()
  local servers = require("plugins.lsp.servers")

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
    callback = function(ev)
      local bufopts = { buffer = ev.buf, silent = true }

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
      vim.keymap.set("n", "K", function()
        vim.lsp.buf.hover({
          border = "rounded",
          title = " Documentation ",
          title_pos = "left",
        })
      end, bufopts)

      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)

      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, bufopts)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, bufopts)
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, bufopts)
    end,
  })

  vim.diagnostic.config({
    virtual_text = {
      prefix = "",
      source = true,
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
      border = "rounded",
      source = true,
    },
  })

  local capabilities = require("managers.completion").get_capabilities()

  vim.lsp.config("*", {
    capabilities = capabilities,
  })

  for server, config in pairs(servers) do
    vim.lsp.config(server, config)
    vim.lsp.enable(server)
  end
end

return M
