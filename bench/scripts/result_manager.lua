--- Benchmark Result Manager
--- Provides versioned, timestamped result storage with JSON/CSV/MD output
local M = {}

M.bench_dir = vim.fn.getcwd() .. "/bench"
M.results_dir = M.bench_dir .. "/results"
M.historical_dir = M.results_dir .. "/historical"
M.raw_dir = M.results_dir .. "/raw"
M.reports_dir = M.results_dir .. "/reports"
M.comparisons_dir = M.results_dir .. "/comparisons"
M.dashboards_dir = M.bench_dir .. "/dashboards"

local function ensure_dir(d)
    if vim.fn.isdirectory(d) ~= 1 then
        os.execute("mkdir -p " .. d)
    end
end

function M.init()
    ensure_dir(M.results_dir)
    ensure_dir(M.historical_dir)
    ensure_dir(M.raw_dir)
    ensure_dir(M.reports_dir)
    ensure_dir(M.comparisons_dir)
end

function M.timestamp()
    return os.date("%Y-%m-%d_%H-%M-%S")
end

--- Resolve the shared run timestamp (RUN_TIMESTAMP env var or fresh)
function M.resolve_timestamp()
    return os.getenv("RUN_TIMESTAMP") or M.timestamp()
end

function M.run_dir(bench_name)
    local ts = M.resolve_timestamp()
    local base = M.historical_dir .. "/" .. ts
    if bench_name then
        return base .. "/" .. bench_name
    end
    return base
end

function M.base_run_dir()
    return M.historical_dir .. "/" .. M.resolve_timestamp()
end

--- Create a new benchmark run context
--- If bench_name is provided and RUN_TIMESTAMP is set, writes to a subfolder of the shared run dir
function M.create_run(config, bench_name)
    config = config or {}
    M.init()
    local dir = M.run_dir(bench_name)
    ensure_dir(dir)
    ensure_dir(dir .. "/raw")
    ensure_dir(dir .. "/reports")

    local ctx = {
        dir = dir,
        bench_name = bench_name,
        start_time = os.time(),
        start_ns = vim.uv.hrtime(),
        config = config,
        results = {},
        log_file = nil,
        log_fh = nil,
    }

    function ctx:open_log(name)
        name = tostring(name)
        ctx.log_file = dir .. "/raw/" .. name .. ".log"
        ctx.log_fh = io.open(ctx.log_file, "w")
        ctx:_log("=== Benchmark Run ===")
        ctx:_log("Date: " .. os.date())
        ctx:_log("Config: " .. vim.inspect(config))
        ctx:_log("Run Dir: " .. dir)
        ctx:_log("---")
        return ctx.log_file
    end

    function ctx:_log(line)
        if ctx.log_fh then
            local ok, _ = pcall(function()
                ctx.log_fh:write(line .. "\n")
            end)
            if ok then
                pcall(function()
                    ctx.log_fh:flush()
                end)
            end
        end
        io.write(line .. "\n")
        io.flush()
    end

    function ctx:log(...)
        local parts = {}
        for _, v in ipairs({ ... }) do
            parts[#parts + 1] = tostring(v)
        end
        self:_log(table.concat(parts, " "))
    end

    function ctx:record(category, name, metrics)
        metrics = metrics or {}
        metrics._category = tostring(category)
        metrics._name = tostring(name)
        metrics._timestamp = os.date("%Y-%m-%d %H:%M:%S")
        metrics._run_time = os.time()
        table.insert(ctx.results, metrics)
        local ok, json = pcall(vim.fn.json_encode, metrics)
        if not ok then
            json = "{}"
        end
        self:_log(string.format("[RESULT] %s / %s: %s", tostring(category), tostring(name), tostring(json)))
        return metrics
    end

    function ctx:write_json(filename, data)
        local filename_s = tostring(filename)
        local fh = io.open(dir .. "/raw/" .. filename_s .. ".json", "w")
        local ok, encoded = pcall(vim.fn.json_encode, data)
        fh:write(ok and encoded or "{}")
        fh:close()
    end

    --- Generate markdown report for this bench_name
    function ctx:generate_report()
        local report = {}
        local function add(l)
            report[#report + 1] = l
        end

        local bench_label = ctx.bench_name or "benchmark"
        add(string.format("# %s Report", bench_label:gsub("^%l", string.upper):gsub("_", " ")))
        add("")
        add(string.format("**Date:** %s  \n", os.date()))
        add(string.format("**Config:** `%s`  \n", vim.inspect(config)))
        add(string.format("**Results:** %d data points  \n", #ctx.results))
        add(string.format("**Duration:** %.1fs  \n", (vim.uv.hrtime() - ctx.start_ns) / 1e9))
        add("")

        local categories = {}
        for _, r in ipairs(ctx.results) do
            local cat = r._category or "uncategorized"
            if not categories[cat] then
                categories[cat] = {}
            end
            table.insert(categories[cat], r)
        end

        local cat_names = {}
        for k, _ in pairs(categories) do
            cat_names[#cat_names + 1] = k
        end
        table.sort(cat_names)

        for _, cat in ipairs(cat_names) do
            add(string.format("## %s", cat:gsub("^%l", string.upper):gsub("_", " ")))
            add("")

            -- Separate stats records (have _name matching *_stats or containing aggregated data)
            local stats_records = {}
            local data_records = {}
            for _, r in ipairs(categories[cat]) do
                local name = r._name or ""
                if
                    name:match("_stats$")
                    or name:match("^(cold|warm|hot)$")
                    or name:match("overview")
                    or r.n ~= nil
                    or r.avg ~= nil
                then
                    table.insert(stats_records, r)
                else
                    table.insert(data_records, r)
                end
            end

            -- Stats table
            if #stats_records > 0 then
                add("### Summary Statistics")
                add("")
                -- Collect all numeric metrics across all stats records
                local metrics = {}
                for _, r in ipairs(stats_records) do
                    for k, v in pairs(r) do
                        if not k:match("^_") and type(v) == "number" then
                            if not metrics[k] then
                                metrics[k] = {}
                            end
                            metrics[k][r._name] = v
                        end
                    end
                end

                local metric_names = {}
                for k, _ in pairs(metrics) do
                    metric_names[#metric_names + 1] = k
                end
                table.sort(metric_names)

                -- Header row
                local header = "| Metric |"
                local sep = "|--------|"
                local stat_names = {}
                for _, r in ipairs(stats_records) do
                    local sn = r._name:gsub("_stats$", "")
                    table.insert(stat_names, sn)
                    header = header .. " " .. sn:gsub("^%l", string.upper) .. " |"
                    sep = sep .. "--------|"
                end
                add(header)
                add(sep)

                for _, mk in ipairs(metric_names) do
                    local row = "| " .. mk .. " |"
                    for _, sn in ipairs(stat_names) do
                        local val = metrics[mk][sn]
                        if val ~= nil then
                            row = row .. " " .. string.format("%.2f", val) .. " |"
                        else
                            row = row .. " — |"
                        end
                    end
                    add(row)
                end
                add("")
            end

            -- Individual data records in a compact table
            if #data_records > 0 then
                add("### Individual Runs")
                add("")
                local all_keys = {}
                local seen_k = {}
                for _, r in ipairs(data_records) do
                    for k, v in pairs(r) do
                        if not k:match("^_") and not seen_k[k] then
                            seen_k[k] = true
                            all_keys[#all_keys + 1] = k
                        end
                    end
                end
                table.sort(all_keys)

                local header = "| Run |"
                local sep = "|-----|"
                for _, k in ipairs(all_keys) do
                    header = header .. " " .. k .. " |"
                    sep = sep .. "--------|"
                end
                add(header)
                add(sep)

                for _, r in ipairs(data_records) do
                    local row = "| " .. (r._name or "") .. " |"
                    for _, k in ipairs(all_keys) do
                        local v = r[k]
                        if v ~= nil then
                            local vs = type(v) == "number" and string.format("%.2f", v) or tostring(v)
                            row = row .. " " .. vs .. " |"
                        else
                            row = row .. " — |"
                        end
                    end
                    add(row)
                end
                add("")
            end

            -- Fallback: if we couldn't classify (e.g. mixed), show flat table
            if #stats_records == 0 and #data_records == 0 then
                add("| Name | Metric | Value |")
                add("|------|--------|-------|")
                for _, r in ipairs(categories[cat]) do
                    for k, v in pairs(r) do
                        if not k:match("^_") then
                            local val_str = type(v) == "number" and string.format("%.2f", v) or tostring(v)
                            add(string.format("| %s | %s | %s |", r._name or "", k, val_str))
                        end
                    end
                end
                add("")
            end
        end

        add("---")
        add(string.format("_Generated by bench/scripts/result_manager.lua at %s_", os.date()))

        local report_path = dir .. "/reports/benchmark-report.md"
        local fh = io.open(report_path, "w")
        fh:write(table.concat(report, "\n"))
        fh:close()
        return report_path
    end

    --- Finalise run and generate all outputs
    function ctx:finalize()
        local elapsed = (vim.uv.hrtime() - ctx.start_ns) / 1e9
        self:log(string.format("\n=== Run complete. Duration: %.1fs ===", elapsed))
        if ctx.log_fh then
            ctx.log_fh:close()
        end

        self:write_json("all_results", {
            run = {
                timestamp = os.date(),
                bench_name = ctx.bench_name,
                config = config,
                duration_seconds = elapsed,
                result_count = #ctx.results,
            },
            results = ctx.results,
        })

        local report_path = ctx:generate_report()

        return {
            dir = dir,
            results = ctx.results,
            report = report_path,
            duration = elapsed,
        }
    end

    return ctx
end

--- Statistics helpers
function M.stats(vals)
    if not vals or #vals == 0 then
        return {}
    end
    local sorted = {}
    for _, v in ipairs(vals) do
        sorted[#sorted + 1] = v
    end
    table.sort(sorted)
    local n = #sorted
    local sum = 0
    for _, v in ipairs(sorted) do
        sum = sum + v
    end
    local avg = sum / n
    local min = sorted[1]
    local max = sorted[n]
    local median = sorted[math.ceil(n / 2)]
    local p95 = sorted[math.ceil(n * 0.95)]
    local p99 = sorted[math.ceil(n * 0.99)]
    local variance = 0
    for _, v in ipairs(sorted) do
        variance = variance + (v - avg) ^ 2
    end
    variance = variance / n
    local stddev = math.sqrt(variance)
    return {
        n = n,
        sum = sum,
        avg = avg,
        min = min,
        max = max,
        median = median,
        p95 = p95,
        p99 = p99,
        stddev = stddev,
        variance = variance,
        sorted = sorted,
    }
end

--- Collect all results from a single run directory (merges sub-benchmarks)
function M.load_run(timestamp)
    local run_dir = M.historical_dir .. "/" .. timestamp
    if vim.fn.isdirectory(run_dir) ~= 1 then
        return nil
    end

    -- Check for merged results.json first
    local merged_path = run_dir .. "/results.json"
    local fh = io.open(merged_path, "r")
    if fh then
        local content = fh:read("*a")
        fh:close()
        local ok, data = pcall(vim.fn.json_decode, content)
        if ok and data then
            return data
        end
    end

    -- Fallback: aggregate from sub-benchmarks (new format: <ts>/<bench>/raw/all_results.json)
    local benchmarks = {}
    local all_results = {}
    local total_duration = 0
    total_count = 0
    local configs = {}

    -- Also check old format: <ts>/raw/all_results.json (pre-subfolder layout)
    local old_path = run_dir .. "/raw/all_results.json"
    local old_fh = io.open(old_path, "r")
    if old_fh then
        local content = old_fh:read("*a")
        old_fh:close()
        local ok, old_data = pcall(vim.fn.json_decode, content)
        if ok and old_data then
            local bn = (old_data.run and old_data.run.bench_name) or "benchmark"
            benchmarks[bn] = old_data
            if old_data.results then
                for _, r in ipairs(old_data.results) do
                    table.insert(all_results, r)
                end
            end
            total_count = total_count + (old_data.run and old_data.run.result_count or 0)
            total_duration = math.max(total_duration, old_data.run and old_data.run.duration_seconds or 0)
            if old_data.run and old_data.run.config then
                configs[#configs + 1] = old_data.run.config
            end
        end
    end

    local subdirs = vim.fn.globpath(run_dir, "*/raw/all_results.json", false, true)
    for _, path in ipairs(subdirs) do
        local fh2 = io.open(path, "r")
        if fh2 then
            local content = fh2:read("*a")
            fh2:close()
            local ok, data = pcall(vim.fn.json_decode, content)
            if ok and data then
                local bn = data.run and data.run.bench_name
                    or vim.fn.fnamemodify(vim.fn.fnamemodify(path, ":h:h"), ":t")
                benchmarks[bn] = data
                if data.results then
                    for _, r in ipairs(data.results) do
                        table.insert(all_results, r)
                    end
                end
                total_count = total_count + (data.run and data.run.result_count or 0)
                total_duration = math.max(total_duration, data.run and data.run.duration_seconds or 0)
                if data.run and data.run.config then
                    configs[#configs + 1] = data.run.config
                end
            end
        end
    end

    return {
        run = {
            timestamp = timestamp,
            duration_seconds = total_duration,
            result_count = total_count,
            configs = configs,
        },
        benchmarks = benchmarks,
        results = all_results,
    }
end

--- Load historical runs for comparison
function M.load_historical_runs(limit)
    limit = limit or 20
    local runs = {}

    -- List run directories (timestamp-named)
    local dirs = vim.fn.globpath(M.historical_dir, "*", false, true)
    table.sort(dirs)

    for _, d in ipairs(dirs) do
        local ts = vim.fn.fnamemodify(d, ":t")
        if ts:match("%d%d%d%d%-%d%d%-%d%d_") then
            local run_data = M.load_run(ts)
            if run_data then
                table.insert(runs, run_data)
            end
        end
    end

    -- Return last N runs
    local ordered = {}
    for i = math.max(1, #runs - limit + 1), #runs do
        table.insert(ordered, runs[i])
    end
    return ordered
end

--- Merge all sub-benchmark results in a run into a single results.json + summary.md
function M.merge_run_results(timestamp)
    local run_dir = M.historical_dir .. "/" .. timestamp
    if vim.fn.isdirectory(run_dir) ~= 1 then
        io.write(string.format("Run directory not found: %s\n", run_dir))
        return nil
    end

    local run_data = M.load_run(timestamp)
    if not run_data then
        io.write(string.format("No data found in: %s\n", run_dir))
        return nil
    end

    -- Write merged results.json
    local merged = {
        timestamp = os.date(),
        run_id = timestamp,
        run = run_data.run,
        benchmarks = run_data.benchmarks,
        results = run_data.results,
    }
    local json_path = run_dir .. "/results.json"
    local fh = io.open(json_path, "w")
    local ok, encoded = pcall(vim.fn.json_encode, merged)
    fh:write(ok and encoded or "{}")
    fh:close()
    io.write(string.format("Merged results: %s (%d total results)\n", json_path, #run_data.results))

    -- Generate summary.md
    local summary = {}
    local function add(l)
        summary[#summary + 1] = l
    end

    add(string.format("# Benchmark Summary — %s", timestamp))
    add("")
    add(string.format("**Generated:** %s  \n", os.date()))
    local bn_count = 0
    for _ in pairs(run_data.benchmarks or {}) do
        bn_count = bn_count + 1
    end
    add(string.format("**Benchmarks:** %d  \n", bn_count))
    add("")

    add(string.format("**Total data points:** %d  \n", #run_data.results))
    add(string.format("**Duration:** %.1fs  \n", run_data.run and run_data.run.duration_seconds or 0))
    add("")

    -- Health score
    local health = 100
    local health_notes = {}

    -- Find key metrics
    local function find_result(cat, name)
        for _, r in ipairs(run_data.results) do
            if r._category == cat and r._name == name then
                return r
            end
        end
        return nil
    end

    local cold_start = find_result("startup_stats", "cold")
    if cold_start and cold_start.wall_median then
        if cold_start.wall_median > 2000 then
            health = health - 20
            health_notes[#health_notes + 1] = "Cold startup > 2s"
        end
        if cold_start.wall_median > 1000 then
            health = health - 10
            health_notes[#health_notes + 1] = "Cold startup > 1s"
        end
    end

    local multi_lsp = find_result("lsp_multi", "all_servers")
    if multi_lsp and multi_lsp.grand_rss_mb then
        if multi_lsp.grand_rss_mb > 1000 then
            health = health - 20
            health_notes[#health_notes + 1] = "Memory > 1GB"
        end
        if multi_lsp.grand_rss_mb > 500 then
            health = health - 10
            health_notes[#health_notes + 1] = "Memory > 500MB"
        end
    end

    local ts_attach = find_result("lsp_attach", "ts_ls")
    if ts_attach and ts_attach.ms then
        if ts_attach.ms > 10000 then
            health = health - 20
            health_notes[#health_notes + 1] = "TS attach > 10s"
        end
        if ts_attach.ms > 5000 then
            health = health - 10
            health_notes[#health_notes + 1] = "TS attach > 5s"
        end
    end

    health = math.max(0, health)
    local health_bar = ""
    for i = 1, 20 do
        if i <= health / 5 then
            health_bar = health_bar .. "█"
        else
            health_bar = health_bar .. "░"
        end
    end

    add("## Health Score")
    add("")
    if health >= 80 then
        add(string.format("| Status | Score |"))
        add(string.format("|--------|-------|"))
        add(string.format("| **%s** | **%d/100** |", "✅ GOOD", health))
    elseif health >= 50 then
        add(string.format("| Status | Score |"))
        add(string.format("|--------|-------|"))
        add(string.format("| **%s** | **%d/100** |", "⚠️ WARNING", health))
    else
        add(string.format("| Status | Score |"))
        add(string.format("|--------|-------|"))
        add(string.format("| **%s** | **%d/100** |", "❌ CRITICAL", health))
    end
    add("")
    add("```")
    add(health_bar)
    add("```")
    add("")
    if #health_notes > 0 then
        add("### Issues")
        add("")
        for _, note in ipairs(health_notes) do
            add(string.format("- %s", note))
        end
        add("")
    end

    -- Key Performance Indicators
    add("## Key Performance Indicators")
    add("")
    add("| Metric | Value | Status |")
    add("|--------|-------|--------|")
    if cold_start and cold_start.wall_median then
        local status = cold_start.wall_median < 1000 and "✅" or (cold_start.wall_median < 2000 and "⚠️" or "❌")
        add(string.format("| Cold Startup (median) | %.0f ms | %s |", cold_start.wall_median, status))
    end
    if cold_start and cold_start.wall_p95 then
        add(string.format("| Cold Startup (p95) | %.0f ms | |", cold_start.wall_p95))
    end
    if cold_start and cold_start.wall_stddev then
        add(string.format("| Cold Startup (stddev) | %.1f ms | |", cold_start.wall_stddev))
    end
    if multi_lsp and multi_lsp.grand_rss_mb then
        local status = multi_lsp.grand_rss_mb < 500 and "✅" or (multi_lsp.grand_rss_mb < 1000 and "⚠️" or "❌")
        add(string.format("| Multi-LSP Memory | %d MB | %s |", multi_lsp.grand_rss_mb, status))
    end
    if ts_attach and ts_attach.ms then
        local status = ts_attach.ms < 5000 and "✅" or (ts_attach.ms < 10000 and "⚠️" or "❌")
        add(string.format("| TypeScript LSP Attach | %d ms | %s |", ts_attach.ms, status))
    end
    local completion = find_result("completion_latency", "ts_ls_completion")
    if completion and completion.avg_ms then
        local status = completion.avg_ms < 100 and "✅" or (completion.avg_ms < 500 and "⚠️" or "❌")
        add(string.format("| TS Completion (avg) | %.1f ms | %s |", completion.avg_ms, status))
    end
    local theme_switch = find_result("engine_switching", "theme_switching")
    if theme_switch and theme_switch.median_ms then
        local status = theme_switch.median_ms < 100 and "✅" or (theme_switch.median_ms < 500 and "⚠️" or "❌")
        add(string.format("| Theme Switching (median) | %.0f ms | %s |", theme_switch.median_ms, status))
    end
    add("")

    -- Per-benchmark sections
    add("## Benchmarks")
    add("")
    add("| Benchmark | Status | Results | Report |")
    add("|-----------|--------|---------|--------|")
    local bn_sorted = {}
    for bn, _ in pairs(run_data.benchmarks or {}) do
        bn_sorted[#bn_sorted + 1] = bn
    end
    table.sort(bn_sorted)
    for _, bn in ipairs(bn_sorted) do
        local data = run_data.benchmarks[bn]
        local count = data.run and data.run.result_count or 0
        local report_rel = bn .. "/reports/benchmark-report.md"
        add(
            string.format(
                "| %s | ✅ | %d | [View](%s) |",
                bn:gsub("^%l", string.upper):gsub("_", " "),
                count,
                report_rel
            )
        )
    end
    add("")

    if run_data.benchmarks and run_data.benchmarks.dashboard then
        add("## Dashboard")
        add("")
        add("[View Dashboard](dashboard/reports/benchmark-report.md)")
        add("")
    end

    if run_data.benchmarks and run_data.benchmarks.comparison then
        add("## Comparison")
        add("")
        add("[View Comparison](comparison/reports/benchmark-report.md)")
        add("")
    end

    add("---")
    add(string.format("_Generated by bench/scripts/result_manager.lua at %s_", os.date()))

    local summary_path = run_dir .. "/summary.md"
    local sfh = io.open(summary_path, "w")
    sfh:write(table.concat(summary, "\n"))
    sfh:close()
    io.write(string.format("Summary report: %s\n", summary_path))

    return merged
end

--- Compare current results against historical baseline
function M.compare(ctx, baseline)
    baseline = baseline or {}
    local report = {}
    local function add(l)
        report[#report + 1] = l
    end

    add("# Comparison Report")
    add(string.format("- **Current:** %s (%s)", ctx.dir, os.date()))
    add(string.format("- **Baseline:** %s entries", #baseline))
    add("")

    local current_by_cat = {}
    for _, r in ipairs(ctx.results) do
        local cat = r._category or "uncategorized"
        if not current_by_cat[cat] then
            current_by_cat[cat] = {}
        end
        table.insert(current_by_cat[cat], r)
    end

    local baseline_by_cat = {}
    for _, run in ipairs(baseline) do
        if run.results then
            for _, r in ipairs(run.results) do
                local cat = r._category or "uncategorized"
                if not baseline_by_cat[cat] then
                    baseline_by_cat[cat] = {}
                end
                table.insert(baseline_by_cat[cat], r)
            end
        end
    end

    for cat, items in pairs(current_by_cat) do
        add(string.format("## %s", cat))
        add("")
        add("| Metric | Current | Baseline | Delta | Delta % | Verdict |")
        add("|--------|---------|----------|-------|---------|---------|")

        local b_items = baseline_by_cat[cat] or {}
        for _, cur in ipairs(items) do
            for k, v in pairs(cur) do
                if not k:match("^_") and type(v) == "number" then
                    local bv = nil
                    for _, b in ipairs(b_items) do
                        if b._name == cur._name and b[k] ~= nil then
                            bv = b[k]
                            break
                        end
                    end
                    if bv and type(bv) == "number" and bv ~= 0 then
                        local delta = v - bv
                        local pct = (delta / bv) * 100
                        local verdict = "PASS"
                        if pct > 20 then
                            verdict = "CRITICAL"
                        elseif pct > 10 then
                            verdict = "WARN"
                        elseif pct > 5 then
                            verdict = "MINOR"
                        elseif pct > 1 then
                            verdict = "SLIGHT"
                        end
                        add(
                            string.format(
                                "| %s.%s | %.1f | %.1f | %+.1f | %+.1f%% | %s |",
                                cur._name or "",
                                k,
                                v,
                                bv,
                                delta,
                                pct,
                                verdict
                            )
                        )
                    end
                end
            end
        end
        add("")
    end

    ensure_dir(M.comparisons_dir)
    local report_path = M.comparisons_dir .. "/comparison-" .. M.timestamp() .. ".md"
    local fh = io.open(report_path, "w")
    fh:write(table.concat(report, "\n"))
    fh:close()
    return report_path
end

--- Simple regression detection
function M.detect_regressions(results, thresholds)
    thresholds = thresholds or { slight = 1, minor = 5, warn = 10, critical = 20 }
    local regressions = {}
    for _, r in ipairs(results) do
        for k, v in pairs(r) do
            if not k:match("^_") and type(v) == "number" then
                local entry = {
                    category = r._category,
                    name = r._name,
                    metric = k,
                    value = v,
                }
                table.insert(regressions, entry)
            end
        end
    end
    return regressions
end

return M
