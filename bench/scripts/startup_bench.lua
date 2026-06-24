--- Comprehensive Startup Benchmark
--- Measures cold/warm/hot startup across configurable iterations
--- Usage: nvim --headless -c "lua require('bench.scripts.startup_bench').run({engine='ts_ls', cold=25, warm=10, hot=10})" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")

local M = {}

function M.run(opts)
  opts = opts or {}
  local engine = opts.engine or vim.g.bench_engine or "ts_ls"
  local cold_n = opts.cold or 25
  local warm_n = opts.warm or 10
  local hot_n = opts.hot or 10
  local nvim_bin = "nvim"

  local ctx = rm.create_run({ benchmark = "startup", engine = engine, cold = cold_n, warm = warm_n, hot = hot_n })
  ctx:open_log("startup_" .. engine)

  ctx:log("=== Startup Benchmark ===")
  ctx:log(string.format("Engine: %s", engine))
  ctx:log(string.format("Iterations: cold=%d warm=%d hot=%d", cold_n, warm_n, hot_n))
  ctx:log("")

  local bench_dir = rm.bench_dir
  local tmp_log = bench_dir .. "/startup_tmp.log"

  local function run_single(label)
    local args = { nvim_bin, "--headless", "--startuptime", tmp_log, "-c", "qa!" }
    local start_ns = vim.uv.hrtime()
    local handle = io.popen(table.concat(args, " ") .. " 2>&1")
    handle:read("*a")
    handle:close()
    local wall_ms = math.floor((vim.uv.hrtime() - start_ns) / 1e6)

    -- Parse startuptime log
    local entries = {}
    local sf = io.open(tmp_log, "r")
    if sf then
      for line in sf:lines() do
        local ms, event = line:match("^%s*(%d+%.?%d*)%s+(.+)$")
        if ms and event then
          table.insert(entries, { ms = tonumber(ms), event = event })
        end
      end
      sf:close()
    end

    local total_startuptime = 0
    local timing_breakdown = {}
    for _, e in ipairs(entries) do
      if e.ms > total_startuptime then total_startuptime = e.ms end
      if e.event:match("^loading") then
        local plugin = e.event:match("loading (.+)")
        if plugin then
          timing_breakdown[plugin] = (timing_breakdown[plugin] or 0) + e.ms
        end
      end
    end

    os.execute("rm -f " .. tmp_log)

    return {
      wall_ms = wall_ms,
      startuptime_ms = total_startuptime,
      entries = entries,
      timing_breakdown = timing_breakdown,
    }
  end

  -- Cold startups
  ctx:log("--- Cold startups ---")
  local cold_results = {}
  for i = 1, cold_n do
    ctx:log(string.format("Cold %d/%d...", i, cold_n))
    local r = run_single(string.format("cold_%d", i))
    table.insert(cold_results, r)
    ctx:record("startup", string.format("cold_%d", i), {
      wall_ms = r.wall_ms,
      startuptime_ms = r.startuptime_ms,
      type = "cold",
    })
  end

  -- Warm startups (same session context simulated)
  ctx:log("--- Warm startups ---")
  local warm_results = {}
  for i = 1, warm_n do
    ctx:log(string.format("Warm %d/%d...", i, warm_n))
    local r = run_single(string.format("warm_%d", i))
    table.insert(warm_results, r)
    ctx:record("startup", string.format("warm_%d", i), {
      wall_ms = r.wall_ms,
      startuptime_ms = r.startuptime_ms,
      type = "warm",
    })
  end

  -- Hot startups (with rc caching)
  ctx:log("--- Hot startups ---")
  local hot_results = {}
  for i = 1, hot_n do
    ctx:log(string.format("Hot %d/%d...", i, hot_n))
    local r = run_single(string.format("hot_%d", i))
    table.insert(hot_results, r)
    ctx:record("startup", string.format("hot_%d", i), {
      wall_ms = r.wall_ms,
      startuptime_ms = r.startuptime_ms,
      type = "hot",
    })
  end

  -- Compute statistics
  local function compute_stats(results, label)
    local wall_vals = {}
    local startup_vals = {}
    for _, r in ipairs(results) do
      table.insert(wall_vals, r.wall_ms)
      table.insert(startup_vals, r.startuptime_ms)
    end

    local wall_stats = rm.stats(wall_vals)
    local startup_stats = rm.stats(startup_vals)

    ctx:record("startup_stats", label, {
      wall_avg = wall_stats.avg,
      wall_min = wall_stats.min,
      wall_max = wall_stats.max,
      wall_median = wall_stats.median,
      wall_p95 = wall_stats.p95,
      wall_p99 = wall_stats.p99,
      wall_stddev = wall_stats.stddev,
      wall_variance = wall_stats.variance,
      startup_avg = startup_stats.avg,
      startup_min = startup_stats.min,
      startup_max = startup_stats.max,
      startup_median = startup_stats.median,
      startup_p95 = startup_stats.p95,
      startup_p99 = startup_stats.p99,
      startup_stddev = startup_stats.stddev,
      startup_variance = startup_stats.variance,
      n = #results,
    })

    ctx:write_csv(label .. "_wall", wall_vals)
    ctx:write_csv(label .. "_startuptime", startup_vals)

    ctx:log(string.format("\n%s Stats (wall clock):", label))
    ctx:log(string.format("  avg=%.1f min=%d max=%d median=%d p95=%d p99=%d stddev=%.1f",
      wall_stats.avg, wall_stats.min, wall_stats.max, wall_stats.median, wall_stats.p95, wall_stats.p99, wall_stats.stddev))
    ctx:log(string.format("%s Stats (startuptime):", label))
    ctx:log(string.format("  avg=%.1f min=%.0f max=%.0f median=%.0f p95=%.0f p99=%.0f stddev=%.1f",
      startup_stats.avg, startup_stats.min, startup_stats.max, startup_stats.median, startup_stats.p95, startup_stats.p99, startup_stats.stddev))
  end

  compute_stats(cold_results, "cold")
  compute_stats(warm_results, "warm")
  compute_stats(hot_results, "hot")

  -- Build startup timing breakdown (aggregated)
  ctx:log("\nTop 20 slowest startup contributors (by wall-clock occurrence):")
  local contrib = {}
  for _, r in ipairs(cold_results) do
    for plugin, ms in pairs(r.timing_breakdown) do
      contrib[plugin] = (contrib[plugin] or 0) + ms
    end
  end
  local sorted = {}
  for k, v in pairs(contrib) do sorted[#sorted+1] = { name = k, total = v } end
  table.sort(sorted, function(a, b) return a.total > b.total end)
  for i = 1, math.min(20, #sorted) do
    ctx:log(string.format("  %d. %s: total %.1f ms", i, sorted[i].name, sorted[i].total))
  end

  local final = ctx:finalize()
  return final
end

return M
