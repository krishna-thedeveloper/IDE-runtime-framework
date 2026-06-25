--- Main Benchmark Orchestrator
--- Runs all benchmarks in sequence, generates reports and comparisons
--- Usage:
---   nvim --headless -c "lua dofile('bench/runner.lua')" -c "qa!"                              # Run all
---   nvim --headless -c "lua arg={'startup'}; dofile('bench/runner.lua')" -c "qa!"              # Run startup only
---   nvim --headless -c "lua arg={'startup','lsp'}; dofile('bench/runner.lua')" -c "qa!"       # Run specific
---   nvim --headless -c "lua arg={'engine=ts_ls'}; dofile('bench/runner.lua')" -c "qa!"        # With config

-- Set shared RUN_TIMESTAMP for all benchmarks in this run
local run_ts = os.getenv("RUN_TIMESTAMP") or os.date("%Y-%m-%d_%H-%M-%S")
vim.env.RUN_TIMESTAMP = run_ts

-- Parse arguments
local args = arg or {}
local selected = {}
local config = {}

for _, a in ipairs(args) do
    if a:match("=") then
        local k, v = a:match("^(.-)=(.*)$")
        if k and v then
            config[k] = v
        end
    else
        table.insert(selected, a)
    end
end

-- If no specific benchmarks selected, run all
if #selected == 0 then
    selected = {
        "seed",
        "startup",
        "lsp",
        "completion",
        "theme",
        "buffer",
        "switching",
        "stability",
        "plugin_attribution",
        "cpu",
        "ts_backend",
        "treesitter",
        "project_indexing",
        "git",
        "editing",
        "search",
        "report",
        "compare",
        "dashboard",
    }
end

local function has(name)
    for _, s in ipairs(selected) do
        if s == name then
            return true
        end
    end
    return false
end

local bench_dir = vim.fn.getcwd() .. "/bench"
local scripts_dir = bench_dir .. "/scripts"
local engine = config.engine or vim.g.bench_engine or "ts_ls"

print(string.format("=== Benchmark Orchestrator ==="))
print(string.format("Run timestamp: %s", run_ts))
print(string.format("Selected: %s", table.concat(selected, ", ")))
print(string.format("Config: engine=%s", engine))
print("")

local results = {}
local errors = {}

local function run_benchmark(name, fn)
    if not has(name) then
        print(string.format("Skipping %s (not selected)", name))
        return
    end
    print(string.format("\n>>> Running: %s <<<", name))
    local ok, result = pcall(fn)
    if ok then
        table.insert(results, { name = name, result = result })
        print(string.format("=== %s: COMPLETE ===", name))
    else
        table.insert(errors, { name = name, error = result })
        print(string.format("=== %s: FAILED ===", name))
        print(tostring(result))
    end
end

-- 0. Seed projects if needed
run_benchmark("seed", function()
    dofile(bench_dir .. "/seed.lua")
    return true
end)

-- 1. Startup benchmark
run_benchmark("startup", function()
    local mod = dofile(scripts_dir .. "/startup_bench.lua")
    return mod.run({ engine = engine, cold = 10, warm = 5, hot = 5 })
end)

-- 2. LSP benchmark
run_benchmark("lsp", function()
    local mod = dofile(scripts_dir .. "/lsp_bench.lua")
    return mod.run()
end)

-- 3. Completion benchmark
run_benchmark("completion", function()
    local mod = dofile(scripts_dir .. "/completion_bench.lua")
    return mod.run()
end)

-- 4. Theme benchmark
run_benchmark("theme", function()
    local mod = dofile(scripts_dir .. "/theme_bench.lua")
    return mod.run()
end)

-- 5. Buffer/Window benchmark
run_benchmark("buffer", function()
    local mod = dofile(scripts_dir .. "/buffer_bench.lua")
    return mod.run()
end)

-- 6. Engine switching benchmark
run_benchmark("switching", function()
    local mod = dofile(scripts_dir .. "/engine_switching_bench.lua")
    return mod.run({ cycles = 100 })
end)

-- 7. Stability/Idle benchmark
run_benchmark("stability", function()
    local mod = dofile(scripts_dir .. "/stability_bench.lua")
    return mod.run({ idle_minutes = 5 })
end)

-- 8. Plugin manager benchmark (external runs)
run_benchmark("plugin_manager", function()
    local mod = dofile(scripts_dir .. "/plugin_manager_bench.lua")
    return mod.run()
end)

-- 9. Plugin attribution benchmark
run_benchmark("plugin_attribution", function()
    local mod = dofile(scripts_dir .. "/plugin_attribution_bench.lua")
    return mod.run({ cold = 5 })
end)

-- 10. CPU profiling benchmark
run_benchmark("cpu", function()
    local mod = dofile(scripts_dir .. "/cpu_bench.lua")
    return mod.run()
end)

-- 11. TypeScript backend comparison benchmark
run_benchmark("ts_backend", function()
    local mod = dofile(scripts_dir .. "/ts_backend_bench.lua")
    return mod.run()
end)

-- 12. Treesitter benchmark
run_benchmark("treesitter", function()
    local mod = dofile(scripts_dir .. "/treesitter_bench.lua")
    return mod.run()
end)

-- 13. Project indexing benchmark
run_benchmark("project_indexing", function()
    local mod = dofile(scripts_dir .. "/project_indexing_bench.lua")
    return mod.run()
end)

-- 14. Git benchmark
run_benchmark("git", function()
    local mod = dofile(scripts_dir .. "/git_bench.lua")
    return mod.run()
end)

-- 15. Editing workflow benchmark
run_benchmark("editing", function()
    local mod = dofile(scripts_dir .. "/editing_bench.lua")
    return mod.run()
end)

-- 16. Search benchmark
run_benchmark("search", function()
    local mod = dofile(scripts_dir .. "/search_bench.lua")
    return mod.run()
end)

-- Post-run: generate reports
run_benchmark("report", function()
    local mod = dofile(scripts_dir .. "/report_generator.lua")
    return mod.generate_all()
end)

-- Post-run: comparison
run_benchmark("compare", function()
    local mod = dofile(scripts_dir .. "/comparison_engine.lua")
    return mod.run()
end)

-- Post-run: dashboards
run_benchmark("dashboard", function()
    local mod = dofile(scripts_dir .. "/dashboard_generator.lua")
    return mod.run()
end)

-- Summary
print("\n" .. string.rep("=", 60))
print("=== BENCHMARK RUN COMPLETE ===")
print(string.rep("=", 60))
print(string.format("Run timestamp: %s", run_ts))
print(string.format("Run directory: %s", vim.fn.getcwd() .. "/bench/results/historical/" .. run_ts))
print(string.format("Benchmarks run: %d", #results))
print(string.format("Benchmarks failed: %d", #errors))
print("")
print("Results:")
for _, r in ipairs(results) do
    local dir = "(no output)"
    if r.result then
        dir = (type(r.result) == "table" and r.result.dir) or tostring(r.result) or "(no output)"
    end
    print(string.format("  [OK] %s: %s", r.name, dir))
end
for _, e in ipairs(errors) do
    print(string.format("  [FAIL] %s: %s", e.name, tostring(e.error)))
end
print("")

-- Print all result directories
print("Result directories:")
for _, r in ipairs(results) do
    if r.result and r.result.dir then
        print(string.format("  %s", r.result.dir))
    end
end

return { results = results, errors = errors }
