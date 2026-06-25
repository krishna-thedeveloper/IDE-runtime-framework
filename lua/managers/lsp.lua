local M = {}

function M.setup()
    local servers = require("config.lsp_servers")

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

            vim.keymap.set("n", "<leader>ch", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
            end, vim.tbl_extend("keep", { desc = "Toggle inlay hints" }, bufopts))

            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
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

    -- Clean up stale LSP clients when the working directory changes.
    -- Prevents accumulation of duplicate client instances across projects.
    vim.api.nvim_create_autocmd("DirChanged", {
        group = vim.api.nvim_create_augroup("lsp_cleanup", { clear = true }),
        callback = function()
            vim.schedule(function()
                M.stop_stale_clients()
            end)
        end,
    })

    -- Dedup guard: stop any existing client with the same name already attached
    -- to this buffer's root directory before a new one attaches.
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_dedup", { clear = true }),
        callback = function(ev)
            local new_client = vim.lsp.get_client_by_id(ev.data and ev.data.client_id)
            if not new_client then
                return
            end
            local new_root = new_client.config and new_client.config.root_dir
            if not new_root then
                return
            end
            for _, client in ipairs(vim.lsp.get_clients()) do
                if
                    client.id ~= new_client.id
                    and client.name == new_client.name
                    and client.config
                    and client.config.root_dir == new_root
                then
                    client:stop()
                end
            end
        end,
    })
end

function M.stop_stale_clients()
    local cwd = vim.fn.getcwd()
    local stopped = 0
    for _, client in ipairs(vim.lsp.get_clients()) do
        local root = client.config and client.config.root_dir
        if root and root ~= cwd then
            client:stop()
            stopped = stopped + 1
        end
    end
    if stopped > 0 then
        vim.notify(string.format("Stopped %d stale LSP client(s)", stopped), vim.log.levels.INFO)
    end
end

vim.api.nvim_create_user_command("LspClean", function()
    M.stop_stale_clients()
    vim.notify("LSP clients cleaned", vim.log.levels.INFO)
end, {})

return M
