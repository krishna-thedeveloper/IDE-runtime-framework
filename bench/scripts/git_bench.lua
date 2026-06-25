local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local function run_git_cmd(args, cwd)
  local cmd = "git " .. args
  if cwd then
    cmd = "git -C " .. cwd .. " " .. args
  end
  local start = lib.hrtime()
  local f = io.popen(cmd .. " 2>&1")
  local output = f:read("*a")
  f:close()
  local ms = lib.elapsed_ms(start)
  return ms, output
end

local function generate_git_repo(dir, file_count)
  os.execute("rm -rf " .. dir)
  os.execute("mkdir -p " .. dir)
  os.execute("cd " .. dir .. " && git init")

  for i = 1, math.min(file_count, 1000) do
    local fh = io.open(dir .. "/file_" .. string.format("%04d", i) .. ".ts", "w")
    fh:write(string.format("export const item_%d = %d;\n", i, i * 100))
    fh:close()
  end

  os.execute("cd " .. dir .. " && git add -A && git commit -m 'initial' 2>/dev/null")

  -- Create some changes for status/blame
  os.execute("cd " .. dir .. " && echo '// modified' >> file_0001.ts")
  os.execute("cd " .. dir .. " && echo '// new file' > new_file.ts && git add new_file.ts")

  -- Create branches
  os.execute("cd " .. dir .. " && git checkout -b feature/test 2>/dev/null")
  for i = 1, 10 do
    local fh = io.open(dir .. "/feature_file_" .. string.format("%04d", i) .. ".ts", "w")
    fh:write(string.format("export const feature_%d = %d;\n", i, i))
    fh:close()
  end
  os.execute("cd " .. dir .. " && git add -A && git commit -m 'feature work' 2>/dev/null")
  os.execute("cd " .. dir .. " && git checkout main 2>/dev/null")
end

function M.run(opts)
  opts = opts or {}
  local ctx = rm.create_run({ benchmark = "git" }, "git")
  ctx:open_log("git")

  local tmp_dir = rm.bench_dir .. "/tmp_git_bench"
  ctx:log("=== Git Benchmark ===\n")

  local repo_sizes = {
    { count = 100,  label = "100_files" },
    { count = 1000, label = "1k_files" },
  }

  for _, spec in ipairs(repo_sizes) do
    local repo_path = tmp_dir .. "/" .. spec.label
    ctx:log(string.format("--- %s ---", spec.label))

    local gen_start = lib.hrtime()
    generate_git_repo(repo_path, spec.count)
    local gen_ms = lib.elapsed_ms(gen_start)
    ctx:log(string.format("  repo setup: %dms", gen_ms))

    -- git status
    local status_ms = run_git_cmd("status", repo_path)
    ctx:log(string.format("  git status: %dms", status_ms))

    -- git diff
    local diff_ms, _ = run_git_cmd("diff", repo_path)
    ctx:log(string.format("  git diff: %dms", diff_ms))

    -- git log
    local log_ms, _ = run_git_cmd("log --oneline -10", repo_path)
    ctx:log(string.format("  git log: %dms", log_ms))

    -- git blame on a file
    local blame_ms, _ = run_git_cmd("blame file_0001.ts", repo_path)
    ctx:log(string.format("  git blame: %dms", blame_ms))

    -- git branch
    local branch_ms, _ = run_git_cmd("branch -a", repo_path)
    ctx:log(string.format("  git branch: %dms", branch_ms))

    -- git stash list
    local stash_ms, _ = run_git_cmd("stash list", repo_path)
    ctx:log(string.format("  git stash list: %dms", stash_ms))

    -- git grep (search within repo)
    local grep_ms, _ = run_git_cmd("grep 'item_'", repo_path)
    ctx:log(string.format("  git grep: %dms", grep_ms))

    ctx:record("git_operations", spec.label, {
      files = spec.count,
      setup_ms = math.floor(gen_ms),
      status_ms = math.floor(status_ms),
      diff_ms = math.floor(diff_ms),
      log_ms = math.floor(log_ms),
      blame_ms = math.floor(blame_ms),
      branch_ms = math.floor(branch_ms),
      stash_ms = math.floor(stash_ms),
      grep_ms = math.floor(grep_ms),
    })
  end

  os.execute("rm -rf " .. tmp_dir)

  local final = ctx:finalize()
  return final
end

return M
