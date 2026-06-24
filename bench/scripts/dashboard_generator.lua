--- Dashboard Generator
--- Generates ASCII trend charts and JSON data for external visualization
--- Usage: nvim --headless -c "lua require('bench.scripts.dashboard_generator').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")

local M = {}

--- Simple ASCII bar chart
function M.ascii_chart(values, width, height, label)
  width = width or 60
  height = height or 12
  if not values or #values == 0 then return "(no data)" end

  local min = math.min(unpack(values))
  local max = math.max(unpack(values))
  local range = max - min
  if range == 0 then range = 1 end

  local lines = {}
  lines[#lines+1] = string.format("--- %s (range: %.1f - %.1f) ---", label or "", min, max)

  for row = height, 1, -1 do
    local threshold = min + (range * (row - 1) / height)
    local bar = ""
    for i, v in ipairs(values) do
      if i > width then break end
      if v >= threshold then
        bar = bar .. "█"
      else
        bar = bar .. " "
      end
    end
    local val_label = ""
    if row == height then val_label = string.format(" %.0f", max)
    elseif row == 1 then val_label = string.format(" %.0f", min) end
    lines[#lines+1] = string.format("%s%s", bar, val_label)
  end

  -- X axis
  local x_axis = ""
  for i = 1, math.min(#values, width) do
    if i % 5 == 1 then
      x_axis = x_axis .. "."
    else
      x_axis = x_axis .. "─"
    end
  end
  lines[#lines+1] = x_axis

  return table.concat(lines, "\n")
end

function M.run()
  local ctx = rm.create_run({ benchmark = "dashboard" })
  ctx:open_log("dashboard")

  ctx:log("=== Dashboard Generation ===")
  ctx:log("")

  local historical = rm.load_historical_runs(50)
  ctx:log(string.format("Loaded %d historical runs", #historical))

  if #historical == 0 then
    ctx:log("No historical data available for dashboards")
    local final = ctx:finalize()
    return final
  end

  -- Extract time series for key metrics
  local series = {
    cold_startup_median = {},
    cold_startup_p95 = {},
    memory_total = {},
    lsp_attach = {},
    completion_latency = {},
    nvim_rss = {},
    lsp_rss = {},
    clients = {},
    modules = {},
  }

  local timestamps = {}

  for _, run in ipairs(historical) do
    if run.results then
      local ts = run.run and run.run.timestamp or "unknown"
      table.insert(timestamps, ts)

      for _, r in ipairs(run.results) do
        if r._category == "startup_stats" and r._name == "cold" then
          if r.wall_median then table.insert(series.cold_startup_median, r.wall_median) end
          if r.wall_p95 then table.insert(series.cold_startup_p95, r.wall_p95) end
        end
        if r._category == "lsp_multi" and r._name == "all_servers" then
          if r.grand_rss_mb then table.insert(series.memory_total, r.grand_rss_mb) end
        end
        if r._category == "lsp_attach" and r._name == "ts_ls" then
          if r.ms then table.insert(series.lsp_attach, r.ms) end
        end
        if r._category == "completion_latency" and r._name == "large_file" then
          if r.avg_ms then table.insert(series.completion_latency, r.avg_ms) end
        end
        if r._category == "idle_snapshot" then
          if r.nvim_rss_mb then table.insert(series.nvim_rss, r.nvim_rss_mb) end
          if r.lsp_rss_mb then table.insert(series.lsp_rss, r.lsp_rss_mb) end
          if r.clients then table.insert(series.clients, r.clients) end
          if r.modules then table.insert(series.modules, r.modules) end
        end
      end
    end
  end

  -- Generate ASCII charts
  ctx:log("")
  if #series.cold_startup_median > 0 then
    ctx:log(M.ascii_chart(series.cold_startup_median, 50, 10, "Cold Startup Median (ms)"))
  end
  if #series.cold_startup_p95 > 0 then
    ctx:log("")
    ctx:log(M.ascii_chart(series.cold_startup_p95, 50, 10, "Cold Startup P95 (ms)"))
  end
  if #series.memory_total > 0 then
    ctx:log("")
    ctx:log(M.ascii_chart(series.memory_total, 50, 10, "Total Memory (MB)"))
  end
  if #series.lsp_attach > 0 then
    ctx:log("")
    ctx:log(M.ascii_chart(series.lsp_attach, 50, 10, "LSP Attach Time (ms)"))
  end
  if #series.completion_latency > 0 then
    ctx:log("")
    ctx:log(M.ascii_chart(series.completion_latency, 50, 10, "Completion Latency (ms)"))
  end
  if #series.nvim_rss > 0 and #series.lsp_rss > 0 then
    ctx:log("")
    ctx:log("--- Memory breakdown by run ---")
    for i = 1, math.min(#series.nvim_rss, #series.lsp_rss) do
      ctx:log(string.format("  Run %d: nvim=%dMB lsp=%dMB total=%dMB",
        i, series.nvim_rss[i] or 0, series.lsp_rss[i] or 0,
        (series.nvim_rss[i] or 0) + (series.lsp_rss[i] or 0)))
    end
  end

  -- Generate dashboard markdown
  ctx:log("\n--- Generating Dashboard Report ---")

  local report_lines = {}
  local function add(l) report_lines[#report_lines+1] = l end

  add("# Benchmark Dashboards")
  add("")
  add(string.format("**Generated:** %s", os.date()))
  add(string.format("**Historical runs:** %d", #historical))
  add("")

  add("## Startup Performance Trend")
  add("")
  add("```")
  add(M.ascii_chart(series.cold_startup_median, 55, 10, "Cold Startup Median (ms)"))
  add("```")
  add("```")
  add(M.ascii_chart(series.cold_startup_p95, 55, 10, "Cold Startup P95 (ms)"))
  add("```")
  add("")

  add("## Memory Trend")
  add("")
  add("```")
  add(M.ascii_chart(series.memory_total, 55, 10, "Total Memory (MB)"))
  add("```")
  add("")

  -- Memory breakdown table
  add("| Run | NVIM (MB) | LSP (MB) | Total (MB) |")
  add("|-----|-----------|----------|------------|")
  for i = 1, math.min(#series.nvim_rss, #series.lsp_rss, 20) do
    add(string.format("| %d | %d | %d | %d |",
      i, series.nvim_rss[i] or 0, series.lsp_rss[i] or 0,
      (series.nvim_rss[i] or 0) + (series.lsp_rss[i] or 0)))
  end
  add("")

  add("## LSP Performance Trend")
  add("")
  add("```")
  add(M.ascii_chart(series.lsp_attach, 55, 10, "LSP Attach Time (ms)"))
  add("```")
  add("")

  add("## Completion Latency Trend")
  add("")
  add("```")
  add(M.ascii_chart(series.completion_latency, 55, 10, "Completion Latency (ms)"))
  add("```")
  add("")

  add("## Historical Data (JSON)")
  add("")
  add("Raw data available for external visualization tools:")
  add("")
  for name, vals in pairs(series) do
    if #vals > 0 then
      local mn, mx = vals[1], vals[1]
    for _, v in ipairs(vals) do if v < mn then mn = v end if v > mx then mx = v end end
    add(string.format("- **%s**: %d data points, range [%.1f, %.1f]",
        name, #vals, mn, mx))
    end
  end
  add("")
  add("---")
  add(string.format("_Generated by bench/scripts/dashboard_generator.lua at %s_", os.date()))

  -- Write dashboard report
  local report_path = rm.reports_dir .. "/dashboard-" .. rm.timestamp() .. ".md"
  local fh = io.open(report_path, "w"); fh:write(table.concat(report_lines, "\n")); fh:close()
  ctx:log(string.format("Dashboard report: %s", report_path))

  -- Write JSON data for external visualization
  local json_data = {
    generated = os.date(),
    run_count = #historical,
    series = series,
    timestamps = timestamps,
  }
  os.execute("mkdir -p " .. rm.dashboards_dir)
  local json_path = rm.dashboards_dir .. "/dashboard-data-" .. rm.timestamp() .. ".json"
  local fh = io.open(json_path, "w")
  if fh then
    fh:write(vim.fn.json_encode(json_data))
    fh:close()
  end
  ctx:log(string.format("Dashboard JSON: %s", json_path))

  ctx:record("dashboard", "generation", {
    historical_runs = #historical,
    series_count = 0,
  })
  for _, v in pairs(series) do if #v > 0 then ctx:record("dashboard", "series", { count = #v }) end end

  local final = ctx:finalize()
  return final
end

return M
