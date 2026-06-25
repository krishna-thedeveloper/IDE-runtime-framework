--- Completion Engine Benchmark
--- Measures blink.cmp (and future engines) for latency, memory, typing simulation
--- Usage: nvim --headless -c "lua require('bench.scripts.completion_bench').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

function M.run(opts)
    opts = opts or {}
    local ctx = rm.create_run({ benchmark = "completion" }, "completion")
    ctx:open_log("completion")

    local proj_dir = rm.bench_dir .. "/projects"
    ctx:log("=== Completion Engine Benchmark ===")
    ctx:log("")

    -- Detect completion engine
    local engine_name = "unknown"
    if pcall(require, "blink.cmp") then
        engine_name = "blink.cmp"
    end
    if pcall(require, "cmp") then
        engine_name = "nvim-cmp"
    end
    ctx:log(string.format("Engine: %s", engine_name))
    ctx:record("completion_info", "engine", { name = engine_name })

    local function benchmark_completion(buf, label)
        local params = {
            textDocument = vim.lsp.util.make_text_document_params(buf),
            position = { line = 1, character = 5 },
            context = { triggerKind = 1 },
        }

        local latencies = {}
        local item_counts = {}

        for i = 1, 10 do
            local start_ns = vim.uv.hrtime()
            local result
            vim.lsp.buf_request(buf, "textDocument/completion", params, function(err, res)
                result = { err = err, res = res }
            end)
            vim.wait(5000, function()
                return result ~= nil
            end, 50)
            local ms = lib.elapsed_ms(start_ns)
            local items = result and result.res and result.res.items and #result.res.items
                or (result and result.res and #result.res)
                or 0
            table.insert(latencies, ms)
            table.insert(item_counts, items)
        end

        local stats = rm.stats(latencies)
        local avg_items = 0
        for _, c in ipairs(item_counts) do
            avg_items = avg_items + c
        end
        avg_items = avg_items / #item_counts

        ctx:record("completion_latency", label, {
            avg_ms = stats.avg,
            median_ms = stats.median,
            min_ms = stats.min,
            max_ms = stats.max,
            p95_ms = stats.p95,
            p99_ms = stats.p99,
            stddev_ms = stats.stddev,
            avg_items = avg_items,
            n = 10,
        })

        ctx:log(
            string.format(
                "  %s: avg=%.1fms median=%.0fms p95=%.0fms items=%.0f",
                label,
                stats.avg,
                stats.median,
                stats.p95,
                avg_items
            )
        )
        return stats
    end

    -- Small file
    ctx:log("--- Small file ---")
    local small_buf = vim.fn.bufadd(proj_dir .. "/small/src/file_0001.ts")
    vim.fn.bufload(small_buf)
    vim.bo[small_buf].filetype = "typescript"
    vim.wait(5000)
    benchmark_completion(small_buf, "small_file")

    -- Medium file
    ctx:log("--- Medium file ---")
    local med_buf = vim.fn.bufadd(proj_dir .. "/medium/src/file_0050.ts")
    vim.fn.bufload(med_buf)
    vim.bo[med_buf].filetype = "typescript"
    vim.wait(5000)
    benchmark_completion(med_buf, "medium_file")

    -- Large file
    ctx:log("--- Large file ---")
    local large_buf = vim.fn.bufadd(proj_dir .. "/large/src/file_0500.ts")
    vim.fn.bufload(large_buf)
    vim.bo[large_buf].filetype = "typescript"
    vim.wait(8000)
    benchmark_completion(large_buf, "large_file")

    -- Stress test: measure memory during completion
    ctx:log("--- Memory during completion ---")
    local mem_baseline = lib.nvim_rss_kb()
    vim.wait(2000)
    for i = 1, 20 do
        local params = {
            textDocument = vim.lsp.util.make_text_document_params(large_buf),
            position = { line = 1, character = 5 },
            context = { triggerKind = 1 },
        }
        vim.lsp.buf_request(large_buf, "textDocument/completion", params, function() end)
        vim.wait(100)
    end
    vim.wait(2000)
    local mem_after = lib.nvim_rss_kb()

    ctx:record("completion_memory", "blink.cmp", {
        baseline_kb = mem_baseline,
        after_typing_kb = mem_after,
        delta_kb = mem_after - mem_baseline,
    })
    ctx:log(
        string.format(
            "  Memory: baseline=%dKB after=%dKB delta=%dKB",
            mem_baseline,
            mem_after,
            mem_after - mem_baseline
        )
    )

    local final = ctx:finalize()
    return final
end

return M
