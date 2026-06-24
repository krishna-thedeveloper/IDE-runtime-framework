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

function M.run_dir()
  return M.historical_dir .. "/" .. M.timestamp()
end

--- Create a new benchmark run context
--- Returns a context object with methods for recording results
function M.create_run(config)
  config = config or {}
  M.init()
  local dir = M.run_dir()
  ensure_dir(dir)
  ensure_dir(dir .. "/raw")
  ensure_dir(dir .. "/reports")

  local ctx = {
    dir = dir,
    start_time = os.time(),
    start_ns = vim.uv.hrtime(),
    config = config,
    results = {},
    log_file = nil,
    log_fh = nil,
  }

  function ctx.open_log(name)
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
      local ok, _ = pcall(function() ctx.log_fh:write(line .. "\n") end)
      if ok then
        pcall(function() ctx.log_fh:flush() end)
      end
    end
    io.write(line .. "\n")
    io.flush()
  end

  function ctx:log(...)
    local parts = {}
    for _, v in ipairs({...}) do parts[#parts+1] = tostring(v) end
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
    if not ok then json = "{}" end
    self:_log(string.format("[RESULT] %s / %s: %s", tostring(category), tostring(name), tostring(json)))
    return metrics
  end

  function ctx:write_csv(filename, data)
    if not data or #data == 0 then return end
    local filename_s = tostring(filename)
    local keys = {}
    for _, row in ipairs(data) do
      if type(row) == "table" then
        for k, _ in pairs(row) do
          if not keys[k] then keys[#keys+1] = k end
        end
      end
    end
    table.sort(keys)
    if #keys == 0 then return end
    local fh = io.open(dir .. "/raw/" .. filename_s .. ".csv", "w")
    fh:write(table.concat(keys, ",") .. "\n")
    for _, row in ipairs(data) do
      if type(row) == "table" then
        local vals = {}
        for _, k in ipairs(keys) do
          vals[#vals+1] = tostring(row[k] or "")
        end
        fh:write(table.concat(vals, ",") .. "\n")
      else
        local vals = {}
        for _ in ipairs(keys) do vals[#vals+1] = tostring(row) end
        fh:write(table.concat(vals, ",") .. "\n")
      end
    end
    fh:close()
  end

  function ctx:write_json(filename, data)
    local filename_s = tostring(filename)
    local fh = io.open(dir .. "/raw/" .. filename_s .. ".json", "w")
    local ok, encoded = pcall(vim.fn.json_encode, data)
    fh:write(ok and encoded or "{}")
    fh:close()
  end

  --- Generate markdown report for this run
  function ctx:generate_report()
    local report = {}
    local function add(l) report[#report+1] = l end

    add(string.format("# Benchmark Report: %s", os.date("%Y-%m-%d %H:%M:%S")))
    add("")
    add("## Summary")
    add(string.format("- **Date:** %s", os.date()))
    add(string.format("- **Config:** %s", vim.inspect(config)))
    add(string.format("- **Total results:** %d", #ctx.results))
    add(string.format("- **Duration:** %.1fs", (vim.uv.hrtime() - ctx.start_ns) / 1e9))
    add("")

    -- Group by category
    local categories = {}
    for _, r in ipairs(ctx.results) do
      local cat = r._category or "uncategorized"
      if not categories[cat] then categories[cat] = {} end
      table.insert(categories[cat], r)
    end

    for cat, items in pairs(categories) do
      add(string.format("## %s", cat))
      add("")
      add("| Name | Metric | Value |")
      add("|------|--------|-------|")
      for _, r in ipairs(items) do
        for k, v in pairs(r) do
          if not k:match("^_") then
            add(string.format("| %s | %s | %s |", r._name or "", k, tostring(v)))
          end
        end
      end
      add("")
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
    if ctx.log_fh then ctx.log_fh:close() end

    -- Write combined JSON
    self:write_json("all_results", {
      run = {
        timestamp = os.date(),
        config = config,
        duration_seconds = elapsed,
        result_count = #ctx.results,
      },
      results = ctx.results,
    })

    -- Write CSV per category
    local by_cat = {}
    for _, r in ipairs(ctx.results) do
      local cat = r._category or "uncategorized"
      if not by_cat[cat] then by_cat[cat] = {} end
      table.insert(by_cat[cat], r)
    end
    for cat, items in pairs(by_cat) do
      self:write_csv(cat, items)
    end

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
  if not vals or #vals == 0 then return {} end
  local sorted = {}
  for _, v in ipairs(vals) do sorted[#sorted+1] = v end
  table.sort(sorted)
  local n = #sorted
  local sum = 0; for _, v in ipairs(sorted) do sum = sum + v end
  local avg = sum / n
  local min = sorted[1]
  local max = sorted[n]
  local median = sorted[math.ceil(n/2)]
  local p95 = sorted[math.ceil(n * 0.95)]
  local p99 = sorted[math.ceil(n * 0.99)]
  local variance = 0
  for _, v in ipairs(sorted) do variance = variance + (v - avg)^2 end
  variance = variance / n
  local stddev = math.sqrt(variance)
  return {
    n = n, sum = sum, avg = avg, min = min, max = max,
    median = median, p95 = p95, p99 = p99,
    stddev = stddev, variance = variance,
    sorted = sorted,
  }
end

--- Load previous runs for comparison
function M.load_historical_runs(limit)
  limit = limit or 10
  local runs = {}
  local dirs = vim.fn.globpath(M.historical_dir, "*/raw/all_results.json", false, true)
  table.sort(dirs)
  for i = math.max(1, #dirs - limit + 1), #dirs do
    local fh = io.open(dirs[i], "r")
    if fh then
      local ok, data = pcall(vim.fn.json_decode, fh:read("*a"))
      fh:close()
      if ok and data then
        table.insert(runs, data)
      end
    end
  end
  -- Reverse to get chronological order
  local ordered = {}
  for i = #runs, 1, -1 do ordered[#ordered+1] = runs[i] end
  return ordered
end

--- Compare current results against historical
function M.compare(ctx, baseline)
  baseline = baseline or {}
  local report = {}
  local function add(l) report[#report+1] = l end

  add("# Comparison Report")
  add(string.format("- **Current:** %s (%s)", ctx.dir, os.date()))
  add(string.format("- **Baseline:** %s entries", #baseline))
  add("")

  local current_by_cat = {}
  for _, r in ipairs(ctx.results) do
    local cat = r._category or "uncategorized"
    if not current_by_cat[cat] then current_by_cat[cat] = {} end
    table.insert(current_by_cat[cat], r)
  end

  local baseline_by_cat = {}
  for _, run in ipairs(baseline) do
    if run.results then
      for _, r in ipairs(run.results) do
        local cat = r._category or "uncategorized"
        if not baseline_by_cat[cat] then baseline_by_cat[cat] = {} end
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
            if pct > 20 then verdict = "CRITICAL"
            elseif pct > 10 then verdict = "WARN"
            elseif pct > 5 then verdict = "MINOR"
            elseif pct > 1 then verdict = "SLIGHT"
            end
            add(string.format("| %s.%s | %.1f | %.1f | %+.1f | %+.1f%% | %s |",
              cur._name or "", k, v, bv, delta, pct, verdict))
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
