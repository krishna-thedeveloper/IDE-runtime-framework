local M = {}

function M.setup(opts)
    local lint = require("lint")
    lint.linters_by_ft = opts.linters_by_ft

    local events = opts.events or { "BufWritePost", "BufReadPost", "InsertLeave" }

    local lint_timer
    vim.api.nvim_create_autocmd(events, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = function()
            local names = M._available(lint.linters_by_ft[vim.bo.filetype] or {})
            if #names == 0 then
                return
            end
            if lint_timer then
                lint_timer:stop()
            end
            lint_timer = (vim.uv or vim.loop).new_timer()
            lint_timer:start(
                100,
                0,
                vim.schedule_wrap(function()
                    lint.try_lint(vim.list_extend({}, names))
                end)
            )
        end,
    })
end

function M._available(names)
    local lint = require("lint")
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

return M
