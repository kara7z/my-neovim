#!/usr/bin/env bash
# Run from any directory; every available check propagates failures.
set -uo pipefail
CFG="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export NVIM_CONFIG_DIR="$CFG"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
cd "$CFG" || exit 1
pass=0
fail=0

run() {
  echo ""
  echo "== $1 =="
  local name="$1"
  shift
  if "$@"; then
    echo "PASS $name"
    pass=$((pass + 1))
  else
    echo "FAIL $name"
    fail=$((fail + 1))
  fi
}

# Passed to run() as a callback.
# shellcheck disable=SC2329
syntax() {
  local file result=0
  while IFS= read -r -d '' file; do
    luac -p "$file" || result=1
  done < <(find "$CFG/lua" "$CFG/tests" -name '*.lua' -print0)
  luac -p "$CFG/init.lua" || result=1
  return "$result"
}

run "Lua syntax" syntax
for tool in stylua selene shellcheck; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "SKIP $tool (not installed)"
    continue
  fi
  case "$tool" in
    stylua) run "Formatting" stylua --check "$CFG" ;;
    selene) run "Lua lint" selene --config "$CFG/selene.toml" "$CFG/lua" ;;
    shellcheck) run "Shell lint" shellcheck tests/*.sh ;;
  esac
done
run "Unit checks" lua "$CFG/tests/test_unit.lua"
run "Static regressions" bash "$CFG/tests/test_static.sh"
run "Keymap regressions" timeout 60 nvim --headless --noplugin -u NONE \
  --cmd "lua vim.opt.rtp:append(vim.env.NVIM_CONFIG_DIR)" \
  -c 'lua dofile(vim.env.NVIM_CONFIG_DIR .. "/tests/test_headless.lua")'
run "Full configuration regressions" timeout 90 nvim --headless -u "$CFG/init.lua" \
  -c 'lua dofile(vim.env.NVIM_CONFIG_DIR .. "/tests/test_config.lua")'
run "Terminal input regressions" timeout 30 nvim --headless -u "$CFG/init.lua" \
  -l "$CFG/tests/test_terminal_keymaps.lua"
if [[ "${NVIM_TEST_JAVA_LSP:-0}" == 1 ]]; then
  run "Java LSP integration" timeout 120 nvim --headless -u "$CFG/init.lua" \
    -c 'lua dofile(vim.env.NVIM_CONFIG_DIR .. "/tests/test_java_lsp.lua")'
  run "Standalone Java LSP integration" env NVIM_TEST_JAVA_SINGLE=1 timeout 120 nvim --headless -u "$CFG/init.lua" \
    -c 'lua dofile(vim.env.NVIM_CONFIG_DIR .. "/tests/test_java_lsp.lua")'
fi

echo ""
echo "RESULT: $pass suites passed, $fail failed"
exit "$((fail > 0))"
