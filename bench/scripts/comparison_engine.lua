--- Comparison & Regression Detection Engine
--- Compares current results against historical baselines
--- Usage: nvim --headless -c "lua dofile('bench/scripts/comparison_engine.lua')" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")

local M = {}

local REGRESSION_THRESHOLDS = {
    slight = 1,
    minor = 5,
    warn = 10,
    critical = 20,
}

function M.run(opts)
    opts = opts or {}
    local ctx = rm.create_run({ benchmark = "comparison", thresholds = REGRESSION_THRESHOLDS }, "comparison")
    ctx:open_log("comparison")

    ctx:log("=== Comparison & Regression Detection ===")
    ctx:log("")

    local historical = rm.load_historical_runs(20)

    if #historical < 2 then
        ctx:log("Need at least 2 historical runs for comparison (found " .. #historical .. ")")
        local final = ctx:finalize()
        return final
    end

    local current = historical[#historical]
    local previous = historical[#historical - 1]
    local all_runs = historical

    ctx:log(string.format("Comparing run %d (latest) vs run %d (previous)", #historical, #historical - 1))

    local function find_best_and_median(category, name, metric)
        local vals = {}
        for _, run in ipairs(all_runs) do
            if run.results then
                for _, r in ipairs(run.results) do
                    if r._category == category and r._name == name and r[metric] ~= nil then
                        table.insert(vals, r[metric])
                    end
                end
            end
        end
        if #vals == 0 then
            return nil, nil
        end
        table.sort(vals)
        local median = vals[math.ceil(#vals / 2)]
        local best = vals[1]
        return best, median
    end

    local regressions = {}
    local improvements = {}
    local stable = {}
    local new_metrics = {}
    local missing_metrics = {}

    if current and current.results and previous and previous.results then
        local current_map = {}
        for _, r in ipairs(current.results) do
            local key = (r._category or "") .. "|" .. (r._name or "")
            if not current_map[key] then
                current_map[key] = {}
            end
            for k, v in pairs(r) do
                if not k:match("^_") and type(v) == "number" then
                    current_map[key][k] = v
                end
            end
        end

        local previous_map = {}
        for _, r in ipairs(previous.results) do
            local key = (r._category or "") .. "|" .. (r._name or "")
            if not previous_map[key] then
                previous_map[key] = {}
            end
            for k, v in pairs(r) do
                if not k:match("^_") and type(v) == "number" then
                    previous_map[key][k] = v
                end
            end
        end

        for key, metrics in pairs(current_map) do
            local prev_metrics = previous_map[key]
            if prev_metrics then
                for metric, val in pairs(metrics) do
                    local prev_val = prev_metrics[metric]
                    if prev_val and prev_val ~= 0 then
                        local delta = val - prev_val
                        local pct = (delta / prev_val) * 100
                        local best, median = find_best_and_median(key:match("^([^|]+)"), key:match("|(.+)$"), metric)

                        local entry = {
                            key = key,
                            metric = metric,
                            current = val,
                            previous = prev_val,
                            delta = delta,
                            delta_pct = pct,
                            best = best,
                            median = median,
                        }

                        if math.abs(pct) <= REGRESSION_THRESHOLDS.slight then
                            table.insert(stable, entry)
                        elseif pct > 0 then
                            entry.severity = "PASS"
                            if pct > REGRESSION_THRESHOLDS.slight then
                                entry.severity = "SLIGHT"
                            end
                            if pct > REGRESSION_THRESHOLDS.minor then
                                entry.severity = "MINOR"
                            end
                            if pct > REGRESSION_THRESHOLDS.warn then
                                entry.severity = "WARN"
                            end
                            if pct > REGRESSION_THRESHOLDS.critical then
                                entry.severity = "CRITICAL"
                            end
                            table.insert(regressions, entry)
                        else
                            table.insert(improvements, entry)
                        end
                    end
                end
            else
                table.insert(new_metrics, { key = key, metrics = metrics })
            end
        end

        for key, _ in pairs(previous_map) do
            if not current_map[key] then
                table.insert(missing_metrics, { key = key })
            end
        end
    end

    table.sort(regressions, function(a, b)
        local severity_order = { CRITICAL = 0, WARN = 1, MINOR = 2, SLIGHT = 3, PASS = 4 }
        return (severity_order[a.severity] or 99) < (severity_order[b.severity] or 99)
    end)

    ctx:log(
        string.format(
            "\nFound %d regressions, %d improvements, %d stable, %d new, %d missing",
            #regressions,
            #improvements,
            #stable,
            #new_metrics,
            #missing_metrics
        )
    )

    ctx:record("comparison_summary", "overview", {
        regressions = #regressions,
        improvements = #improvements,
        stable = #stable,
        new_metrics = #new_metrics,
        missing_metrics = #missing_metrics,
    })

    local critical_count = 0
    local warn_count = 0
    for _, r in ipairs(regressions) do
        if r.severity == "CRITICAL" then
            critical_count = critical_count + 1
            ctx:record("regression_critical", r.key .. "." .. r.metric, {
                current = r.current,
                previous = r.previous,
                delta_pct = r.delta_pct,
                severity = r.severity,
            })
            ctx:log(
                string.format(
                    "  CRITICAL: %s/%s: %.1f -> %.1f (%+.1f%%)",
                    r.key,
                    r.metric,
                    r.previous,
                    r.current,
                    r.delta_pct
                )
            )
        elseif r.severity == "WARN" then
            warn_count = warn_count + 1
            ctx:record("regression_warn", r.key .. "." .. r.metric, {
                current = r.current,
                previous = r.previous,
                delta_pct = r.delta_pct,
                severity = r.severity,
            })
        end
    end

    ctx:record("comparison_summary", "severity_counts", {
        critical = critical_count,
        warn = warn_count,
        improvements = #improvements,
    })

    if critical_count > 0 then
        ctx:log(string.format("  ALERT: %d CRITICAL regressions detected!", critical_count))
    end

    table.sort(improvements, function(a, b)
        return a.delta_pct < b.delta_pct
    end)
    for i = 1, math.min(5, #improvements) do
        local r = improvements[i]
        ctx:log(
            string.format(
                "  Improvement: %s/%s: %.1f -> %.1f (%+.1f%%)",
                r.key,
                r.metric,
                r.previous,
                r.current,
                r.delta_pct
            )
        )
    end

    -- Generate comparison report
    ctx:log("\n--- Generating Comparison Report ---")
    local compare_result = rm.compare(
        { dir = ctx.dir, results = ctx.results },
        { { results = previous and previous.results or {} } }
    )
    ctx:log(string.format("Comparison report: %s", compare_result))

    -- Generate beautiful regression report
    local report_lines = {}
    local function add(l)
        report_lines[#report_lines + 1] = l
    end

    add("# Regression Detection Report")
    add("")
    add(string.format("**Generated:** %s  \n", os.date()))
    add(string.format("**Runs compared:** latest vs previous (%d total)  \n", #historical))
    add("")

    add("## Summary")
    add("")
    add("| Category | Count |")
    add("|----------|-------|")
    add(string.format("| Regressions | %d |", #regressions))
    add(string.format("| Improvements | %d |", #improvements))
    add(string.format("| Stable metrics | %d |", #stable))
    add(string.format("| New metrics | %d |", #new_metrics))
    add(string.format("| Missing metrics | %d |", #missing_metrics))
    add("")

    if #regressions > 0 then
        add("## Regressions by Severity")
        add("")
        local severities = { "CRITICAL", "WARN", "MINOR", "SLIGHT" }
        local severity_icons = { CRITICAL = "❌", WARN = "⚠️", MINOR = "🔶", SLIGHT = "🔸" }
        for _, sev in ipairs(severities) do
            local sev_items = {}
            for _, r in ipairs(regressions) do
                if r.severity == sev then
                    table.insert(sev_items, r)
                end
            end
            if #sev_items > 0 then
                add(string.format("### %s %s (%d)", severity_icons[sev], sev, #sev_items))
                add("")
                add("| Metric | Previous | Current | Delta | Delta % |")
                add("|--------|----------|---------|-------|---------|")
                for _, r in ipairs(sev_items) do
                    add(
                        string.format(
                            "| %s/%s | %.2f | %.2f | %+.2f | %+.1f%% |",
                            r.key,
                            r.metric,
                            r.previous,
                            r.current,
                            r.delta,
                            r.delta_pct
                        )
                    )
                end
                add("")
            end
        end
    end

    if #improvements > 0 then
        add("## Top Improvements")
        add("")
        add("| Metric | Previous | Current | Delta | Delta % |")
        add("|--------|----------|---------|-------|---------|")
        for i = 1, math.min(10, #improvements) do
            local r = improvements[i]
            add(
                string.format(
                    "| %s/%s | %.2f | %.2f | %+.2f | %+.1f%% |",
                    r.key,
                    r.metric,
                    r.previous,
                    r.current,
                    r.delta,
                    r.delta_pct
                )
            )
        end
        add("")
    end

    add("## Historical Trends")
    add("")
    local metric_history = {}
    for _, run in ipairs(historical) do
        if run.results then
            for _, r in ipairs(run.results) do
                local key = (r._category or "") .. "/" .. (r._name or "")
                for k, v in pairs(r) do
                    if not k:match("^_") and type(v) == "number" then
                        local full_key = key .. "." .. k
                        if not metric_history[full_key] then
                            metric_history[full_key] = {}
                        end
                        table.insert(metric_history[full_key], v)
                    end
                end
            end
        end
    end

    for full_key, vals in pairs(metric_history) do
        if #vals >= 3 then
            local sorted = {}
            for _, v in ipairs(vals) do
                sorted[#sorted + 1] = v
            end
            table.sort(sorted)
            local trend = sorted[#sorted] - sorted[1]
            local pct_trend = (trend / math.max(0.001, sorted[1])) * 100
            local direction = pct_trend > 5 and "↑ degrading" or (pct_trend < -5 and "↓ improving" or "→ stable")
            add(
                string.format(
                    "- **%s**: %s (range: %.2f → %.2f, %.1f%%)",
                    full_key,
                    direction,
                    sorted[1],
                    sorted[#sorted],
                    pct_trend
                )
            )
        end
    end

    add("")
    add("---")
    add(string.format("_Generated by bench/scripts/comparison_engine.lua at %s_", os.date()))

    local report_path = ctx.dir .. "/reports/benchmark-report.md"
    local fh = io.open(report_path, "w")
    fh:write(table.concat(report_lines, "\n"))
    fh:close()
    ctx:log(string.format("Regression report: %s", report_path))

    local final = ctx:finalize()
    return final
end

return M
