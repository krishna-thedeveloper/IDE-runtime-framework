--- Buffer/Window/Treesitter/Search/Git/File-Explorer Benchmarks
--- Usage: nvim --headless -c "lua require('bench.scripts.buffer_bench').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

function M.run(opts)
    opts = opts or {}
    local ctx = rm.create_run({ benchmark = "buffer_window" }, "buffer")
    ctx:open_log("buffer_window")

    local proj_dir = rm.bench_dir .. "/projects"
    ctx:log("=== Buffer & Window Benchmarks ===")
    ctx:log("")

    --- Buffer scaling
    ctx:log("--- Buffer Scaling ---")
    local buffer_counts = { 1, 10, 50, 100, 500, 1000 }
    for _, n in ipairs(buffer_counts) do
        vim.cmd("%bdelete!")
        collectgarbage("collect")
        local snap_before = lib.snapshot()

        for i = 1, math.min(n, 1000) do
            local fn = string.format(proj_dir .. "/large/src/file_%04d.ts", i)
            local b = vim.fn.bufadd(fn)
            vim.fn.bufload(b)
            vim.bo[b].filetype = "typescript"
        end
        vim.wait(5000)

        local snap_after = lib.snapshot()
        local mem_delta = (snap_after.grand_rss - snap_before.grand_rss) / 1024 / 1024

        -- Measure buffer switching latency
        local switch_times = {}
        for i = 1, 10 do
            local s = lib.hrtime()
            vim.cmd("b" .. (i % n + 1))
            local elapsed = lib.elapsed_ms(s)
            table.insert(switch_times, elapsed)
        end
        local switch_stats = rm.stats(switch_times)

        ctx:record("buffer_scaling", tostring(n) .. "_buffers", {
            count = n,
            nvim_rss_mb = math.floor(snap_after.nvim_rss / 1024 / 1024),
            lsp_rss_mb = math.floor(snap_after.lsp_rss / 1024 / 1024),
            grand_rss_mb = math.floor(snap_after.grand_rss / 1024 / 1024),
            delta_mb = math.floor(mem_delta),
            switch_avg_ms = switch_stats.avg,
            switch_median_ms = switch_stats.median,
            modules = snap_after.modules,
        })
        ctx:log(
            string.format(
                "  %3d buffers: nvim=%dMB lsp=%dMB total=%dMB delta=%dMB switch=%dms",
                n,
                math.floor(snap_after.nvim_rss / 1024 / 1024),
                math.floor(snap_after.lsp_rss / 1024 / 1024),
                math.floor(snap_after.grand_rss / 1024 / 1024),
                math.floor(mem_delta),
                switch_stats.median
            )
        )
    end

    --- Window scaling
    ctx:log("\n--- Window Scaling ---")
    vim.cmd("%bdelete!")
    local window_configs = { 1, 2, 4, 8, 16 }
    for _, n in ipairs(window_configs) do
        vim.cmd("tabonly!")
        local snap_before = lib.snapshot()

        if n == 1 then
        -- single window, no splits
        elseif n == 2 then
            vim.cmd("vsplit")
        elseif n <= 4 then
            vim.cmd("vsplit")
            vim.cmd("split")
            if n == 4 then
                vim.cmd("vsplit")
            end
        else
            -- Create grid of splits
            local cols = math.ceil(math.sqrt(n))
            local rows = math.ceil(n / cols)
            for r = 1, rows - 1 do
                vim.cmd("split")
            end
            for c = 1, cols - 1 do
                vim.cmd("wincmd j")
                vim.cmd("vsplit")
                for r = 1, rows - 2 do
                    vim.cmd("wincmd k")
                end
            end
        end

        -- Open a file in each window
        vim.wait(1000)
        local snap_after = lib.snapshot()
        ctx:record("window_scaling", tostring(n) .. "_windows", {
            count = n,
            nvim_rss_mb = math.floor(snap_after.nvim_rss / 1024 / 1024),
            grand_rss_mb = math.floor(snap_after.grand_rss / 1024 / 1024),
            delta_mb = math.floor((snap_after.grand_rss - snap_before.grand_rss) / 1024 / 1024),
        })
        ctx:log(
            string.format(
                "  %2d windows: nvim=%dMB total=%dMB delta=%dMB",
                n,
                math.floor(snap_after.nvim_rss / 1024 / 1024),
                math.floor(snap_after.grand_rss / 1024 / 1024),
                math.floor((snap_after.grand_rss - snap_before.grand_rss) / 1024 / 1024)
            )
        )
    end

    --- Treesitter benchmarks
    ctx:log("\n--- Treesitter Benchmarks ---")
    local ts_files = {
        { path = proj_dir .. "/small/src/file_0001.ts", label = "small (5KB)" },
        { path = proj_dir .. "/medium/src/file_0050.ts", label = "medium (20KB)" },
        { path = proj_dir .. "/large/src/file_0500.ts", label = "large (50KB)" },
    }
    for _, f in ipairs(ts_files) do
        vim.cmd("%bdelete!")
        local buf = vim.fn.bufadd(f.path)
        vim.fn.bufload(buf)
        vim.bo[buf].filetype = "typescript"
        vim.wait(2000)

        -- Parse time
        local parse_times = {}
        for i = 1, 5 do
            local s = lib.hrtime()
            local ok, parser = pcall(vim.treesitter.get_parser, buf, "typescript")
            if ok and parser then
                parser:parse()
                table.insert(parse_times, lib.elapsed_ms(s))
            end
        end
        if #parse_times > 0 then
            local stats = rm.stats(parse_times)
            ctx:record("treesitter_parse", f.label, {
                avg_ms = stats.avg,
                median_ms = stats.median,
                min_ms = stats.min,
                max_ms = stats.max,
            })
            ctx:log(string.format("  %s: treesitter parse avg=%.1fms", f.label, stats.avg))
        end
    end

    --- Search/Picker benchmarks (if available)
    ctx:log("\n--- Search/Picker Benchmarks ---")
    local picker_found = nil
    for _, name in ipairs({ "snacks", "telescope", "fzf-lua" }) do
        local ok, mod = pcall(require, name)
        if ok then
            picker_found = name
            break
        end
    end

    if picker_found then
        ctx:log(string.format("  Available: %s", picker_found))
        -- Measure picker startup by checking if lazy-loaded
        local picker_load_times = {}
        for i = 1, 5 do
            collectgarbage("collect")
            local s = lib.hrtime()
            pcall(require, picker_found)
            table.insert(picker_load_times, lib.elapsed_ms(s))
        end
        local stats = rm.stats(picker_load_times)
        ctx:record("picker_startup", picker_found, {
            avg_ms = stats.avg,
            median_ms = stats.median,
        })
        ctx:log(string.format("  %s load: avg=%.1fms", picker_found, stats.avg))
    else
        ctx:log("  No picker available")
    end

    local final = ctx:finalize()
    return final
end

return M
