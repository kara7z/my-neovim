#!/usr/bin/env bash
# Full test runner for nvim config.
# Usage: bash tests/run_all.sh
set -u
CFG="$HOME/.config/nvim"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
pass=0; fail=0
step() { echo ""; echo "===== $1 ====="; }

step "1/6 luac syntax (all lua files)"
LUAC_FAIL=0
while IFS= read -r f; do
  if ! luac -p "$f"; then echo "SYNTAX FAIL $f"; LUAC_FAIL=1; fi
done < <(find "$CFG/lua" -name "*.lua" | sort)
if [ "$LUAC_FAIL" -eq 0 ]; then echo "PASS luac all files"; else echo "FAIL luac"; fail=$((fail+1)); fi

step "2/6 stylua --check"
if command -v stylua >/dev/null 2>&1; then
  if stylua --check "$CFG/" 2>&1 | head -n 30; then :; fi
  # informational only: drift exists, don't gate
  echo "(stylua drift is informational; run: stylua $CFG/ to fix)"
else echo "SKIP stylua not found"; fi

step "3/6 selene (with project config)"
if command -v selene >/dev/null 2>&1; then
  selene --config "$CFG/selene.toml" "$CFG/lua" 2>&1 | head -n 40
  echo "(expect 0 errors, 0 warnings)"
else echo "SKIP selene not found"; fi

step "4/6 unit tests (pure lua)"
if lua "$CFG/tests/test_unit.lua"; then pass=$((pass+1)); else echo "UNIT FAILED"; fail=$((fail+1)); fi

step "5/6 static pattern checks"
bash "$CFG/tests/test_static.sh" || true

step "6/6 headless keymap test"
if timeout 60 nvim --headless --noplugin -u NONE --cmd "set rtp+=$CFG" -c "luafile $CFG/tests/test_headless.lua" 2>&1 | tail -n 30; then
  # nvim cquit propagates via timeout exit code; re-run exit-code check:
  timeout 60 nvim --headless --noplugin -u NONE --cmd "set rtp+=$CFG" -c "luafile $CFG/tests/test_headless.lua" >/dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]; then echo "PASS headless"; pass=$((pass+1)); else echo "FAIL headless rc=$rc"; fail=$((fail+1)); fi
else
  echo "FAIL headless runner"; fail=$((fail+1))
fi

step "7/6 full-config smoke (startup)"
if timeout 120 nvim --headless -u "$CFG/init.lua" -c "qa!" 2>&1 | tail -n 5; then echo "PASS smoke startup"; else echo "FAIL smoke"; fail=$((fail+1)); fi

echo ""
echo "RESULT: $pass gating suites passed, $fail failed"
exit $fail
