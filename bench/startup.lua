--- Startup benchmark: cold, warm, repeated
-- Run: nvim --headless -c "luafile bench/startup.lua [flow_name]" -c "qa!"

local flow_name = arg and arg[1] or "unknown"
local bench_dir = vim.fn.getcwd() .. "/bench"
local results_dir = bench_dir .. "/results"
os.execute("mkdir -p " .. results_dir)

local lib = dofile(bench_dir .. "/lib.lua")
local st = results_dir .. "/startup_" .. flow_name .. ".log"
local f = io.open(st, "w")
f:write("=== Startup Benchmark ===\n")
f:write(string.format("Date: %s\n", os.date()))
f:write(string.format("Engine: %s\n", flow_name))
f:write("---\n")

local function run_startup(label)
  local args = {"nvim", "--headless", "--startuptime", bench_dir .. "/startup_tmp.log", "-c", "qa!"}
  local start = lib.hrtime()
  local handle = io.popen(table.concat(args, " ") .. " 2>&1")
  handle:read("*a")
  handle:close()
  local elapsed = lib.elapsed_ms(start)

  local slines = {}
  local sf = io.open(bench_dir .. "/startup_tmp.log", "r")
  if sf then
    for line in sf:lines() do
      table.insert(slines, line)
    end
    sf:close()
  end

  local total_time = 0
  for _, line in ipairs(slines) do
    local ms = tonumber(line:match("^%s*(%d+%.?%d*)"))
    if ms and ms > total_time then total_time = ms end
  end

  f:write(string.format("%s: wall=%dms startuptime=%.1fms\n", label, elapsed, total_time))
  io.write(string.format("  %s: wall=%dms startuptime=%.1fms\n", label, elapsed, total_time))
  os.execute("rm -f " .. bench_dir .. "/startup_tmp.log")
  return elapsed, total_time
end

io.write("--- Cold startups ---\n")
local cold_times = {}
for i = 1, 10 do
  local wall, su = run_startup(string.format("cold_%d", i))
  table.insert(cold_times, { wall = wall, startuptime = su })
end

io.write("\n--- Warm startups ---\n")
local warm_times = {}
for i = 1, 10 do
  local wall, su = run_startup(string.format("warm_%d", i))
  table.insert(warm_times, { wall = wall, startuptime = su })
end

local function stats(data, key)
  local vals = {}
  for _, v in ipairs(data) do vals[#vals+1] = v[key] end
  table.sort(vals)
  local sum = 0; for _, v in ipairs(vals) do sum = sum + v end
  local avg = sum / #vals
  local min = vals[1]
  local max = vals[#vals]
  local median = vals[math.ceil(#vals/2)]
  local p95 = vals[math.ceil(#vals * 0.95)]
  local p99 = vals[math.ceil(#vals * 0.99)]
  local variance = 0
  for _, v in ipairs(vals) do variance = variance + (v - avg)^2 end
  variance = variance / #vals
  local stddev = math.sqrt(variance)
  return avg, min, max, median, p95, p99, stddev, vals
end

f:write("\n--- Cold Start Stats (wall clock) ---\n")
local cavg, cmin, cmax, cmed, cp95, cp99, cstd, cv = stats(cold_times, "wall")
f:write(string.format("avg=%.1f min=%d max=%d median=%d p95=%d p99=%d stddev=%.1f\n", cavg, cmin, cmax, cmed, cp95, cp99, cstd))
f:write("values: " .. table.concat(cv, ",") .. "\n")

f:write("\n--- Cold Start Stats (startuptime) ---\n")
local csavg, csmin, csmax, csmed, csp95, csp99, csstd_csv = stats(cold_times, "startuptime")
f:write(string.format("avg=%.1f min=%.0f max=%.0f median=%.0f p95=%.0f p99=%.0f stddev=%.1f\n", csavg, csmin, csmax, csmed, csp95, csp99, csstd_csv))
local csvals = {}
for _, v in ipairs(cold_times) do csvals[#csvals+1] = v.startuptime end
f:write("values: " .. table.concat(csvals, ",") .. "\n")

f:write("\n--- Warm Start Stats (wall clock) ---\n")
local wavg, wmin, wmax, wmed, wp95, wp99, wstd, wv = stats(warm_times, "wall")
f:write(string.format("avg=%.1f min=%d max=%d median=%d p95=%d p99=%d stddev=%.1f\n", wavg, wmin, wmax, wmed, wp95, wp99, wstd))
f:write("values: " .. table.concat(wv, ",") .. "\n")

f:write("\n--- Warm Start Stats (startuptime) ---\n")
local wsavg, wsmin, wsmax, wsmed, wsp95, wsp99, wsstd_csv = stats(warm_times, "startuptime")
f:write(string.format("avg=%.1f min=%.0f max=%.0f median=%.0f p95=%.0f p99=%.0f stddev=%.1f\n", wsavg, wsmin, wsmax, wsmed, wsp95, wsp99, wsstd_csv))
local wsvals = {}
for _, v in ipairs(warm_times) do wsvals[#wsvals+1] = v.startuptime end
f:write("values: " .. table.concat(wsvals, ",") .. "\n")

f:close()
print("\nStartup benchmark done. Results in " .. st)
