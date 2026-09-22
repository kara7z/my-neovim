#!/usr/bin/env bash
# Static regression checks: pass when fixed patterns are present.
# Run: bash tests/test_static.sh
set -u
CFG="$HOME/.config/nvim"
fail=0
pass=0
check() { # $1=name $2=condition(true=pass) $3=detail
  if eval "$2"; then echo "PASS $1"; pass=$((pass+1)); else echo "FAIL $1${3:+ | $3}"; fail=$((fail+1)); fi
}

echo "== static: lazy/cmd (fixed) =="
check "CompilerStop key exists" "grep -q CompilerStop $CFG/lua/plugins/compiler.lua"
check "CompilerStop in cmd lists" "grep -q 'cmd = .*CompilerStop' $CFG/lua/plugins/compiler.lua"

echo "== static: maven (fixed) =="
check "no hidden .mvnw check" "! grep -q 'filereadable(\".mvnw\")' $CFG/lua/plugins/java-maven.lua"
check "maven uses project_root" "grep -q 'project_root' $CFG/lua/plugins/java-maven.lua"

echo "== static: fs.find anchored (fixed) =="
check "compiler pom find has path" "grep -q 'vim.fs.find(\"pom.xml\", { path =' $CFG/lua/plugins/compiler.lua"
check "scaffold pom find has path" "grep -q 'vim.fs.find(\"pom.xml\", { path =' $CFG/lua/plugins/java-scaffold.lua"

echo "== static: jvm portable (fixed) =="
check "jvm portable helper" "grep -q 'jvm_search_dirs' $CFG/lua/plugins/java-fix.lua"

echo "== static: keymaps undojoin grouping (correct: move,undojoin,indent) =="
check "undojoin joins indent with move" "awk '/execute .move/{m=NR} /undojoin/{u=NR} END{exit !(m<u)}' $CFG/lua/config/keymaps.lua"

echo "== static: scaffold (fixed) =="
check "slash mode handled" "grep -q 'slash_pkg' $CFG/lua/plugins/java-scaffold.lua"
check "valid_ident allows dollar" "grep -q '\\$' $CFG/lua/plugins/java-scaffold.lua"
check "write uses pcall-safe notify" "grep -q 'cannot write' $CFG/lua/plugins/java-scaffold.lua"
check "is_simple_project takes base" "grep -q 'is_simple_project(base' $CFG/lua/plugins/java-scaffold.lua"
check "folder traversal guard" "grep -q 'invalid folder' $CFG/lua/plugins/java-scaffold.lua"

echo "== static: plenary/conform (fixed) =="
check "plenary init not config in stack" "grep -A2 'nvim-lua/plenary' $CFG/lua/plugins/stack.lua | grep -q 'init = function'"
check "blade_formatter scoped to blade" "grep -q 'blade = { \"blade_formatter\"' $CFG/lua/plugins/stack.lua"
check "css_variables disabled (EACCES crash)" "grep -A1 'css_variables' $CFG/lua/plugins/stack.lua | grep -q 'enabled = false'"
check "cssls unknownAtRules error" "grep -q 'unknownAtRules' $CFG/lua/plugins/stack.lua"

echo "== static: round2 shell/clipboard/python (fixed) =="
check "shellescape helper" "grep -q 'shellescape' $CFG/lua/plugins/compiler.lua"
check "no raw double-quoted bufname in F5" "! grep -q '\" .. bufname .. \"' $CFG/lua/plugins/compiler.lua"
check "python prefers python3" "grep -q 'executable(\"python3\")' $CFG/lua/plugins/compiler.lua"
check "clipboard paste returns regtype" "grep -q 'getregtype' $CFG/lua/config/options.lua"
check "clipboard VeryLazy conditional" "grep -A6 'pattern = \"VeryLazy\"' $CFG/lua/config/options.lua | grep -q 'executable(\"wl-copy\")'"

echo ""
echo "$pass passed, $fail failed"
exit $fail
