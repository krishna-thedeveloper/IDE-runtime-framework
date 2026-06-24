--- Engine Measurement Helper
--- Invoked as subprocess by ts_backend_bench.lua
--- Uses env vars ENGINE_NAME, PROJ_PATH, OUTPUT_FILE to receive config
vim.cmd("set noswapfile shortmess+=F")
vim.wait(2000)

vim.cmd("e " .. (vim.fn.getenv("PROJ_PATH") or ".") .. "/src/index.ts")
vim.bo.filetype = "typescript"

local engine_name = vim.fn.getenv("ENGINE_NAME") or "ts_ls"
local output_file = vim.fn.getenv("OUTPUT_FILE") or "/tmp/ts_bench_out.json"
local proj_path = vim.fn.getenv("PROJ_PATH") or vim.fn.getcwd()
local proj_label = vim.fn.getenv("PROJ_LABEL") or "unknown"

local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local results = {
  engine = engine_name,
  project = proj_label,
  attach_ms = nil,
  attached = false,
  operations = {},
  memory = {},
  cpu = {},
  errors = {},
}

local function capture(fn, label)
  local ok, err = pcall(fn)
  if not ok then table.insert(results.errors, label .. ": " .. tostring(err)) end
end

-- Wait for LSP client to attach
local attach_start = lib.hrtime()
local attached = lib.wait_for_client(engine_name, 60000)
local attach_ms = lib.elapsed_ms(attach_start)

if not attached then
  results.attached = false
  local f = io.open(output_file, "w")
  if f then f:write(vim.json.encode(results)); f:close() end
  os.exit(0)
end

results.attached = true
results.attach_ms = attach_ms
vim.wait(3000)

local buf = vim.api.nvim_get_current_buf()
local snap = lib.snapshot()
results.memory.baseline = {
  nvim_rss_mb = math.floor(snap.nvim_rss / 1024 / 1024),
  lsp_rss_mb = math.floor(snap.lsp_rss / 1024 / 1024),
  grand_rss_mb = math.floor(snap.grand_rss / 1024 / 1024),
  gc_kb = snap.gc_kb, modules = snap.modules,
}
results.cpu.baseline = math.floor(snap.cpu * 100) / 100

local ops = {
  { name = "completion", method = "textDocument/completion", params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = 10, character = 5 }, context = { triggerKind = 1 } } },
  { name = "hover", method = "textDocument/hover", params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = 10, character = 5 } } },
  { name = "definition", method = "textDocument/definition", params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = 10, character = 5 } } },
  { name = "references", method = "textDocument/references", params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = 10, character = 5 } } },
  { name = "rename", method = "textDocument/rename", params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = 10, character = 5 }, newName = "newVarBench" } },
  { name = "formatting", method = "textDocument/formatting", params = {
    textDocument = vim.lsp.util.make_text_document_params(buf) } },
}

for _, op in ipairs(ops) do
  capture(function()
    local op_start = lib.hrtime()
    local done = false
    local op_result
    vim.lsp.buf_request(buf, op.method, op.params, function(err, res)
      op_result = { err = err, res = res }; done = true
    end)
    vim.wait(op.timeout or 10000, function() return done end, 50)
    local ms = math.floor(lib.elapsed_ms(op_start) * 100) / 100
    local count
    if op.name == "completion" and op_result and op_result.res then
      count = (op_result.res.items and #op_result.res.items) or (op_result.res and #op_result.res) or 0
    elseif op.name == "references" and op_result and op_result.res then
      count = #op_result.res
    end
    results.operations[op.name] = { ms = ms, count = count }
  end, op.name)
end

vim.wait(2000)
snap = lib.snapshot()
results.memory.after_ops = {
  nvim_rss_mb = math.floor(snap.nvim_rss / 1024 / 1024),
  lsp_rss_mb = math.floor(snap.lsp_rss / 1024 / 1024),
  grand_rss_mb = math.floor(snap.grand_rss / 1024 / 1024),
  gc_kb = snap.gc_kb,
}
results.cpu.after_ops = math.floor(snap.cpu * 100) / 100

local procs = lib.process_tree()
results.child_processes = {}
for _, p in ipairs(procs) do
  if p.rss and p.rss > 0 then
    table.insert(results.child_processes, { pid = p.pid, rss_kb = math.floor(p.rss / 1024), comm = p.comm })
  end
end

local clients = vim.lsp.get_clients()
results.clients = {}
for _, c in ipairs(clients) do
  table.insert(results.clients, { name = c.name, pid = c.rpc and c.rpc.pid, attached_bufs = #(c.attached_buffers or {}) })
end

results.resources = { autocmds = lib.count_autocmds(), modules = lib.count_modules() }

local f = io.open(output_file, "w")
if f then f:write(vim.json.encode(results)); f:close() end

vim.cmd("%bdelete!")
vim.wait(500)
for _, c in ipairs(vim.lsp.get_clients()) do
  if c.name == engine_name then c:stop() end
end
vim.wait(1000)
os.exit(0)
