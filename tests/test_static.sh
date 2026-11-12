#!/usr/bin/env bash
# Supplement the behavioral tests with inexpensive source regressions.
set -uo pipefail
CFG="${NVIM_CONFIG_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
fail=0
pass=0
check() {
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
# Passed to check() as a callback.
# shellcheck disable=SC2329
absent() { ! grep -q -- "$1" "$2"; }
compiler="$CFG/lua/plugins/compiler.lua"
scaffold="$CFG/lua/plugins/java-scaffold.lua"
stack="$CFG/lua/plugins/stack.lua"
options="$CFG/lua/config/options.lua"

check "CompilerStop key exists" grep -q CompilerStop "$compiler"
check "CompilerStop in lazy command lists" grep -q 'cmd = .*CompilerStop' "$compiler"
check "no hidden .mvnw check" absent 'filereadable(".mvnw")' "$CFG/lua/plugins/java-maven.lua"
check "Maven uses project_root" grep -q project_root "$CFG/lua/plugins/java-maven.lua"
check "compiler pom search is anchored" grep -q 'vim.fs.find("pom.xml", { path =' "$compiler"
check "scaffold pom search is anchored" grep -q 'vim.fs.find("pom.xml", { path =' "$scaffold"
check "portable JVM discovery" grep -q jvm_search_dirs "$CFG/lua/plugins/java-fix.lua"
check "undojoin follows the move" awk '/execute .move/{m=NR} /undojoin/{u=NR} END{exit !(m<u)}' "$CFG/lua/config/keymaps.lua"
check "slash project arguments supported" grep -q slash_pkg "$scaffold"
check "scaffold reports write errors" grep -q 'cannot write' "$scaffold"
check "simple project lookup takes a root" grep -q 'is_simple_project(base' "$scaffold"
check "folder traversal guard" grep -q 'invalid folder' "$scaffold"
check "filetypes independent of plenary init" grep -q 'vim.filetype.add' "$options"
check "Blade formatter scoped to Blade" grep -q 'blade = { "blade_formatter"' "$stack"
check "crashing CSS variables server disabled" grep -q 'css_variables = { enabled = false }' "$stack"
check "unknown CSS at-rules checked" grep -q unknownAtRules "$stack"
check "shell escaping in runners" grep -q shellescape "$compiler"
check "no raw double-quoted buffer paths" absent '" .. bufname .. "' "$compiler"
check "Python prefers python3" grep -q 'executable("python3")' "$compiler"
check "clipboard uses native paste command" grep -q '"wl-paste --no-newline"' "$options"

echo "$pass passed, $fail failed"
exit "$((fail > 0))"
