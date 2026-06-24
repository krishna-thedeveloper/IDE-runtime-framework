--- Benchmark Report Generator
--- Generates comprehensive markdown reports from benchmark results
--- Usage: nvim --headless -c "lua require('bench.scripts.report_generator').generate_all()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")

local M = {}

function M.generate_executive_summary(runs)
  local lines = {}
  local function add(l) lines[#lines+1] = l end

  add("# Benchmark Executive Summary")
  add("")
  add(string.format("**Generated:** %s", os.date()))
  add(string.format("**Total runs analyzed:** %d", #runs))
  add("")

  if #runs == 0 then
    add("No benchmark data available.")
    return table.concat(lines, "\n")
  end

  local latest = runs[#runs]
  local results = latest.results or {}

  add("## Latest Run Overview")
  add("")
  add(string.format("- **Date:** %s", latest.run and latest.run.timestamp or "unknown"))
  add(string.format("- **Duration:** %.1fs", latest.run and latest.run.duration_seconds or 0))
  add(string.format("- **Results:** %d data points", #results))
  add("")

  -- Extract key metrics
  local function find_result(category, name)
    for _, r in ipairs(results) do
      if r._category == category and r._name == name then return r end
    end
    return nil
  end

  add("## Key Performance Indicators")
  add("")
  add("| Metric | Value |")
  add("|--------|-------|")

  -- Startup (cold median)
  local cold_start = find_result("startup_stats", "cold")
  if cold_start then
    add(string.format("| Cold Startup (median) | %.0f ms |", cold_start.wall_median))
    add(string.format("| Cold Startup (p95) | %.0f ms |", cold_start.wall_p95))
    add(string.format("| Cold Startup (stddev) | %.1f ms |", cold_start.wall_stddev))
  end

  -- Memory
  local multi_lsp = find_result("lsp_multi", "all_servers")
  if multi_lsp then
    add(string.format("| Multi-LSP Memory | %d MB |", multi_lsp.grand_rss_mb))
  end

  -- LSP attach
  local ts_attach = find_result("lsp_attach", "ts_ls")
  if ts_attach then
    add(string.format("| TypeScript LSP Attach | %d ms |", ts_attach.ms))
  end

  -- Completion
  local completion = find_result("completion_latency", "large_file")
  if completion then
    add(string.format("| Completion Latency (large file) | %.1f ms |", completion.avg_ms))
  end

  -- Theme switching
  local theme_switch = find_result("engine_switching", "theme_switching")
  if theme_switch then
    add(string.format("| Theme Switching (median) | %.0f ms |", theme_switch.median_ms))
  end

  add("")

  -- Regressions
  add("## Regressions & Warnings")
  add("")
  local warnings = 0
  for _, r in ipairs(results) do
    if r._category:match("warn") or r._category:match("duplicate") or r._category:match("orphan") then
      warnings = warnings + 1
    end
  end
  add(string.format("- **Warnings:** %d", warnings))
  add("")

  -- Health score (simple heuristic)
  local health = 100
  if cold_start and cold_start.wall_median > 2000 then health = health - 20 end
  if multi_lsp and multi_lsp.grand_rss_mb > 1000 then health = health - 20 end
  if ts_attach and ts_attach.ms > 10000 then health = health - 20 end
  if completion and completion.avg_ms > 500 then health = health - 20 end
  if warnings > 5 then health = health - 20 end
  add(string.format("## Health Score: %d/100", math.max(0, health)))
  add("")

  local report = table.concat(lines, "\n")
  local path = rm.reports_dir .. "/executive-summary-" .. rm.timestamp() .. ".md"
  local fh = io.open(path, "w"); fh:write(report); fh:close()
  return path, report
end

function M.generate_full_report(runs)
  local lines = {}
  local function add(l) lines[#lines+1] = l end

  add("# Comprehensive Benchmark Report")
  add("")
  add(string.format("**Generated:** %s", os.date()))
  add(string.format("**Runs analyzed:** %d", #runs))
  add("")

  if #runs == 0 then
    add("No benchmark data available.")
    return table.concat(lines, "\n"), nil
  end

  -- Aggregate all results from all runs
  local all_results = {}
  for _, run in ipairs(runs) do
    if run.results then
      for _, r in ipairs(run.results) do
        table.insert(all_results, r)
      end
    end
  end

  -- Group by category
  local categories = {}
  for _, r in ipairs(all_results) do
    local cat = r._category or "Uncategorized"
    if not categories[cat] then categories[cat] = {} end
    table.insert(categories[cat], r)
  end

  -- Sort categories
  local cat_names = {}
  for k, _ in pairs(categories) do cat_names[#cat_names+1] = k end
  table.sort(cat_names)

  for _, cat in ipairs(cat_names) do
    add(string.format("## %s", cat))
    add("")
    add("| Name | Metric | Value |")
    add("|------|--------|-------|")

    local items = categories[cat]
    -- Sort by name then metric
    table.sort(items, function(a, b)
      if a._name ~= b._name then return (a._name or "") < (b._name or "") end
      return (a._timestamp or "") < (b._timestamp or "")
    end)

    for _, r in ipairs(items) do
      for k, v in pairs(r) do
        if not k:match("^_") then
          local val_str = type(v) == "number" and string.format("%.2f", v) or tostring(v)
          add(string.format("| %s | %s | %s |", r._name or "", k, val_str))
        end
      end
    end
    add("")
  end

  add("---")
  add(string.format("_Generated by bench/scripts/report_generator.lua at %s_", os.date()))

  local report = table.concat(lines, "\n")
  local path = rm.reports_dir .. "/comprehensive-report-" .. rm.timestamp() .. ".md"
  local fh = io.open(path, "w"); fh:write(report); fh:close()
  return path, report
end

function M.generate_startup_report(runs)
  local lines = {}
  local function add(l) lines[#lines+1] = l end

  add("# Startup Performance Report")
  add("")
  add(string.format("**Generated:** %s", os.date()))
  add("")

  -- Collect startup stats from all runs
  local startup_stats = {}
  for _, run in ipairs(runs) do
    if run.results then
      for _, r in ipairs(run.results) do
        if r._category == "startup_stats" then
          table.insert(startup_stats, r)
        end
      end
    end
  end

  if #startup_stats == 0 then
    add("No startup benchmark data found.")
    return table.concat(lines, "\n")
  end

  add("## Cold Startup")
  add("")
  add("| Metric | Wall Clock (ms) | Startuptime (ms) |")
  add("|--------|----------------|-------------------|")
  local function find_stat(arr, name)
    for _, r in ipairs(arr) do
      if r._name == name then return r end
    end
    return {}
  end
  local cold = find_stat(startup_stats, "cold")
  add(string.format("| Average | %.1f | %.1f |", cold.wall_avg or 0, cold.startup_avg or 0))
  add(string.format("| Median | %.0f | %.0f |", cold.wall_median or 0, cold.startup_median or 0))
  add(string.format("| P95 | %.0f | %.0f |", cold.wall_p95 or 0, cold.startup_p95 or 0))
  add(string.format("| P99 | %.0f | %.0f |", cold.wall_p99 or 0, cold.startup_p99 or 0))
  add(string.format("| Min | %.0f | %.0f |", cold.wall_min or 0, cold.startup_min or 0))
  add(string.format("| Max | %.0f | %.0f |", cold.wall_max or 0, cold.startup_max or 0))
  add(string.format("| Std Dev | %.1f | %.1f |", cold.wall_stddev or 0, cold.startup_stddev or 0))
  add(string.format("| Variance | %.1f | %.1f |", cold.wall_variance or 0, cold.startup_variance or 0))
  add("")

  add("## Warm Startup")
  add("")
  add("| Metric | Wall Clock (ms) | Startuptime (ms) |")
  add("|--------|----------------|-------------------|")
  local warm = find_stat(startup_stats, "warm")
  add(string.format("| Average | %.1f | %.1f |", warm.wall_avg or 0, warm.startup_avg or 0))
  add(string.format("| Median | %.0f | %.0f |", warm.wall_median or 0, warm.startup_median or 0))
  add(string.format("| P95 | %.0f | %.0f |", warm.wall_p95 or 0, warm.startup_p95 or 0))
  add("")

  add("## Hot Startup")
  add("")
  add("| Metric | Wall Clock (ms) | Startuptime (ms) |")
  add("|--------|----------------|-------------------|")
  local hot = find_stat(startup_stats, "hot")
  add(string.format("| Average | %.1f | %.1f |", hot.wall_avg or 0, hot.startup_avg or 0))
  add(string.format("| Median | %.0f | %.0f |", hot.wall_median or 0, hot.startup_median or 0))
  add(string.format("| P95 | %.0f | %.0f |", hot.wall_p95 or 0, hot.startup_p95 or 0))
  add("")

  add("## Startup Time Breakdown")
  add("")
  add("Listing all startup contributors sorted by time spent:")
  add("")

  -- Collect unique startup results
  local startup_results = {}
  for _, r in ipairs(runs) do
    if r.results then
      for _, res in ipairs(r.results) do
        if res._category == "startup" and res._name then
          local key = res._name
          if not startup_results[key] then startup_results[key] = {} end
          for k, v in pairs(res) do
            if not k:match("^_") then
              startup_results[key][k] = v
            end
          end
        end
      end
    end
  end

  add("| Run | Wall (ms) | Startuptime (ms) | Type |")
  add("|-----|-----------|-------------------|------|")
  for name, data in pairs(startup_results) do
    add(string.format("| %s | %s | %s | %s |",
      name, tostring(data.wall_ms or ""), tostring(data.startuptime_ms or ""), tostring(data.type or "")))
  end

  local report = table.concat(lines, "\n")
  local path = rm.reports_dir .. "/startup-report-" .. rm.timestamp() .. ".md"
  local fh = io.open(path, "w"); fh:write(report); fh:close()
  return path, report
end

function M.generate_all()
  local runs = rm.load_historical_runs(50)
  local results = {}
  local function add(title, path)
    if path then
      table.insert(results, { title = title, path = path })
    end
  end

  add("Executive Summary", M.generate_executive_summary(runs))
  add("Comprehensive Report", M.generate_full_report(runs))
  add("Startup Report", M.generate_startup_report(runs))

  io.write("=== Report Generation Complete ===\n")
  for _, r in ipairs(results) do
    io.write(string.format("  %s: %s\n", r.title, r.path))
  end
  return results
end

return M
