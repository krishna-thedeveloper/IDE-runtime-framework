# Benchmark Makefile — run from project root (nvim/)
# Examples:
#   make bench-seed       # generate test projects
#   make bench-startup    # run startup benchmark
#   make bench-run        # run full benchmark (ts_ls flow)
#   make bench-compare    # run both flows and compare
#   make bench-worst      # run worst-case benchmark
#   make bench-all        # run full comparison (takes ~30 min)
#   make bench-clean      # remove generated data

BENCH_DIR = $(CURDIR)/bench

.PHONY: bench-seed bench-startup bench-run bench-compare bench-worst bench-all bench-clean

bench-seed:
	@echo "=== Generating benchmark projects ==="
	nvim --headless -c "luafile $(BENCH_DIR)/seed.lua" -c "qa!" 2>&1
	@echo "Done."

bench-startup: bench-seed
	@echo "=== Flow A (ts_ls) startup ==="
	nvim --headless -c "lua arg={'ts_ls'}; dofile('$(BENCH_DIR)/startup.lua')" -c "qa!" 2>&1
	@echo "=== Flow B (typescript-tools) startup ==="
	nvim --headless -c "lua arg={'typescript_tools'}; dofile('$(BENCH_DIR)/startup.lua')" -c "qa!" 2>&1

bench-run: bench-seed
	@echo "=== Flow A (ts_ls) full benchmark ==="
	nvim --headless -c "lua arg={'ts_ls'}; dofile('$(BENCH_DIR)/run.lua')" -c "qa!" 2>&1

bench-compare: bench-seed
	@echo "=== Flow A (ts_ls) ==="
	nvim --headless -c "lua arg={'ts_ls'}; dofile('$(BENCH_DIR)/run.lua')" -c "qa!" 2>&1
	@echo "=== Flow B (typescript-tools) ==="
	nvim --headless -c "lua arg={'typescript_tools'}; dofile('$(BENCH_DIR)/run.lua')" -c "qa!" 2>&1

bench-worst: bench-seed
	@echo "=== Worst-case benchmark ==="
	nvim --headless -c "luafile $(BENCH_DIR)/worst.lua" -c "qa!" 2>&1

bench-all: bench-compare bench-startup bench-worst
	@echo "=== All benchmarks complete ==="

bench-clean:
	rm -rf $(BENCH_DIR)/projects $(BENCH_DIR)/results
	@echo "Cleaned."
