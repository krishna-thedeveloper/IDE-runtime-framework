--- Stability, Idle & Failure Recovery Tests
--- Measures long-running stability, resource leaks, and recovery from failures
--- Usage: nvim --headless -c "lua require('bench.scripts.stability_bench').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

function M.run(opts)
    opts = opts or {}
    local idle_minutes = opts.idle_minutes or 5
    local ctx = rm.create_run({
        benchmark = "stability",
        idle_minutes = idle_minutes,
    }, "stability")
    ctx:open_log("stability")

    local proj_dir = rm.bench_dir .. "/projects"
    ctx:log("=== Stability, Idle & Failure Recovery Tests ===")
    ctx:log(string.format("Idle duration: %d minutes", idle_minutes))
    ctx:log("")

    --- 1. Idle test
    ctx:log("--- 1. Idle Test (%d min) ---", idle_minutes)
    local idle_samples = {}
    for i = 1, idle_minutes do
        vim.wait(60000)
        collectgarbage("collect")
        local snap = lib.snapshot()
        local ac_total, ac_events = lib.count_autocmds()
        local timers = lib.count_timers()
        local procs = lib.process_tree()
        local cpu = lib.cpu_percent(vim.fn.getpid())

        table.insert(idle_samples, {
            minute = i,
            nvim_rss_mb = math.floor(snap.nvim_rss / 1024 / 1024),
            lsp_rss_mb = math.floor(snap.lsp_rss / 1024 / 1024),
            grand_rss_mb = math.floor(snap.grand_rss / 1024 / 1024),
            autocmds = ac_total,
            timers = timers,
            child_procs = #procs,
            modules = snap.modules,
            gc_kb = snap.gc_kb,
            cpu = cpu,
            clients = #snap.clients,
        })

        ctx:record("idle_snapshot", string.format("minute_%d", i), {
            nvim_rss_mb = math.floor(snap.nvim_rss / 1024 / 1024),
            lsp_rss_mb = math.floor(snap.lsp_rss / 1024 / 1024),
            grand_rss_mb = math.floor(snap.grand_rss / 1024 / 1024),
            autocmds = ac_total,
            timers = timers,
            child_procs = #procs,
            modules = snap.modules,
            cpu = cpu,
            clients = #snap.clients,
        })

        -- Detect anomalies
        if #procs > 20 then
            ctx:log(string.format("  WARNING: High child process count (%d) at minute %d", #procs, i))
        end
        if ac_total > 200 then
            ctx:log(string.format("  WARNING: High autocmd count (%d) at minute %d", ac_total, i))
        end
        if timers > 50 then
            ctx:log(string.format("  WARNING: High timer count (%d) at minute %d", timers, i))
        end

        -- Detect duplicate LSP clients
        local client_counts = {}
        for _, c in ipairs(vim.lsp.get_clients()) do
            client_counts[c.name] = (client_counts[c.name] or 0) + 1
        end
        for name, count in pairs(client_counts) do
            if count > 1 then
                ctx:record("idle_duplicate_clients", name, { minute = i, count = count })
                ctx:log(
                    string.format("  WARNING: Duplicate LSP client '%s' (%d instances) at minute %d", name, count, i)
                )
            end
        end

        ctx:log(
            string.format(
                "  minute %2d: nvim=%dMB lsp=%dMB total=%dMB autocmds=%d timers=%d procs=%d cpu=%.1f%%",
                i,
                math.floor(snap.nvim_rss / 1024 / 1024),
                math.floor(snap.lsp_rss / 1024 / 1024),
                math.floor(snap.grand_rss / 1024 / 1024),
                ac_total,
                timers,
                #procs,
                cpu
            )
        )
    end

    -- Idle trend analysis
    if #idle_samples >= 2 then
        local first = idle_samples[1]
        local last = idle_samples[#idle_samples]
        local mem_growth = last.grand_rss_mb - first.grand_rss_mb
        local mem_growth_pct = (mem_growth / math.max(1, first.grand_rss_mb)) * 100

        ctx:record("idle_trend", "memory_growth", {
            initial_mb = first.grand_rss_mb,
            final_mb = last.grand_rss_mb,
            growth_mb = mem_growth,
            growth_pct = mem_growth_pct,
            duration_minutes = idle_minutes,
        })
        ctx:log(
            string.format("  Idle memory growth: %d MB (%.1f%%) over %d min", mem_growth, mem_growth_pct, idle_minutes)
        )

        if mem_growth_pct > 20 then
            ctx:log("  CRITICAL: Possible memory leak detected!")
        elseif mem_growth_pct > 10 then
            ctx:log("  WARNING: Significant memory growth detected!")
        end

        local autocmd_growth = last.autocmds - first.autocmds
        if autocmd_growth > 10 then
            ctx:record("idle_trend", "autocmd_leak", {
                initial = first.autocmds,
                final = last.autocmds,
                growth = autocmd_growth,
            })
            ctx:log(string.format("  WARNING: Autocmd count grew by %d during idle", autocmd_growth))
        end
    end

    --- 2. GC pressure test
    ctx:log("\n--- 2. GC Pressure Test ---")
    local gc_results = {}
    for i = 1, 5 do
        local before = collectgarbage("count")
        -- Force creation of many objects
        local tbl = {}
        for j = 1, 100000 do
            tbl[j] = { key = "value_" .. j, data = { 1, 2, 3, 4, 5 } }
        end
        tbl = nil
        local after_create = collectgarbage("count")
        collectgarbage("collect")
        local after_gc = collectgarbage("count")
        table.insert(gc_results, {
            before = before,
            after_create = after_create,
            after_gc = after_gc,
            freed = after_create - after_gc,
        })
    end

    local avg_freed = 0
    for _, gr in ipairs(gc_results) do
        avg_freed = avg_freed + gr.freed
    end
    avg_freed = avg_freed / #gc_results
    ctx:record("gc_pressure", "average", {
        freed_kb = math.floor(avg_freed),
        samples = #gc_results,
    })
    ctx:log(string.format("  GC freed avg: %.0f KB per cycle", avg_freed))

    --- 3. Failure simulation (LSP crash)
    ctx:log("\n--- 3. Failure Simulation ---")
    ctx:log("  Testing LSP crash recovery...")
    local clients_before = #vim.lsp.get_clients()
    local ts_clients = {}
    for _, c in ipairs(vim.lsp.get_clients()) do
        if c.name == "ts_ls" or c.name == "typescript-tools" then
            table.insert(ts_clients, c)
        end
    end

    if #ts_clients > 0 then
        for _, c in ipairs(ts_clients) do
            if c.rpc and c.rpc.pid then
                ctx:log(string.format("  Killing LSP client %s (pid=%d)...", c.name, c.rpc.pid))
                os.execute("kill -9 " .. c.rpc.pid)
            end
        end
        vim.wait(5000)

        -- Check if client restarts
        local clients_after = #vim.lsp.get_clients()
        ctx:record("failure_recovery", "lsp_crash", {
            clients_before = clients_before,
            clients_after = clients_after,
            killed = #ts_clients,
            recovered = clients_after >= clients_before - #ts_clients,
        })
        ctx:log(
            string.format(
                "  LSP crash recovery: before=%d after=%d killed=%d",
                clients_before,
                clients_after,
                #ts_clients
            )
        )
    else
        ctx:log("  No TypeScript LSP client to kill")
    end

    --- 4. Buffer cleanup verification
    ctx:log("\n--- 4. Resource Cleanup Verification ---")
    local before_cleanup = lib.snapshot()
    vim.cmd("%bdelete!")
    vim.cmd("tabonly!")
    collectgarbage("collect")
    vim.wait(2000)
    local after_cleanup = lib.snapshot()

    local cleanup_delta = before_cleanup.nvim_rss - after_cleanup.nvim_rss
    ctx:record("resource_cleanup", "buffer_close", {
        before_rss_mb = math.floor(before_cleanup.nvim_rss / 1024 / 1024),
        after_rss_mb = math.floor(after_cleanup.nvim_rss / 1024 / 1024),
        freed_mb = math.floor(cleanup_delta / 1024 / 1024),
        clients_remaining = #vim.lsp.get_clients(),
    })
    ctx:log(
        string.format(
            "  Cleanup: freed %d MB (was %dMB, now %dMB) clients=%d",
            math.floor(cleanup_delta / 1024 / 1024),
            math.floor(before_cleanup.nvim_rss / 1024 / 1024),
            math.floor(after_cleanup.nvim_rss / 1024 / 1024),
            #vim.lsp.get_clients()
        )
    )

    local final = ctx:finalize()
    return final
end

return M
