return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            events = { "BufWritePost", "BufReadPost", "InsertLeave" },
            linters_by_ft = {
                lua = { "selene" },
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescriptreact = { "eslint_d" },
            },
        },
        config = function(_, opts)
            local lint = require("lint")

            for name, linter in pairs(opts.linters or {}) do
                if type(linter) == "table" then
                    lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name] or {}, linter)
                end
            end

            lint.linters_by_ft = opts.linters_by_ft

            local function available(names)
                local result = {}
                for _, name in ipairs(names) do
                    local linter = lint.linters[name]
                    if not linter then
                        goto continue
                    end
                    local cmd = type(linter) == "table" and linter.cmd or name
                    if type(cmd) == "function" then
                        local ok, resolved = pcall(cmd)
                        cmd = ok and resolved or name
                    end
                    cmd = type(cmd) == "table" and cmd[1] or cmd
                    if type(cmd) == "string" and vim.fn.executable(cmd) == 1 then
                        table.insert(result, name)
                    end
                    ::continue::
                end
                return result
            end

            local lint_timer
            vim.api.nvim_create_autocmd(opts.events, {
                group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
                callback = function()
                    local names = available(lint._resolve_linter_by_ft(vim.bo.filetype))
                    if #names == 0 then
                        return
                    end
                    if lint_timer then
                        lint_timer:stop()
                    end
                    lint_timer = vim.uv.new_timer()
                    lint_timer:start(100, 0, vim.schedule_wrap(function()
                        lint.try_lint(vim.list_extend({}, names))
                    end))
                end,
            })
        end,
    },
}
