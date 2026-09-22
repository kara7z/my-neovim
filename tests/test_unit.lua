-- Unit tests for pure logic extracted from nvim config (post-fix expectations).
-- Run with: lua tests/test_unit.lua  (no vim dependency)
-- Exit 0 on pass, 1 on fail.

local failures = 0
local passes = 0

local function ok(cond, name, extra)
  if cond then
    passes = passes + 1
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. (extra and (" | " .. extra) or ""))
  end
end

-- ── mirrors lua/plugins/java-scaffold.lua (fixed) ──
local function has_dots(name)
  return name:find("%.") ~= nil
end

local function valid_ident(name)
  return name:match("^[%a_$][%w_$]*$") ~= nil
end

-- fixed slash parsing: "com.example/myapp" -> pkg="com.example", dir="myapp"
local function parse_project_arg(name, arg2)
  local slash_pkg, slash_dir = name:match("^([^/]+)/([^/]+)$")
  if slash_pkg and slash_dir then
    return slash_pkg, slash_dir
  elseif has_dots(name) then
    return name, arg2 or "myapp"
  else
    return nil, name
  end
end

-- replicated from compiler.lua / java-maven.lua
local function java_fqcn(lines, stem)
  local pkg = nil
  for _, line in ipairs(lines) do
    pkg = line:match("^%s*package%s+([%w%.]+)%s*;")
    if pkg then
      break
    end
  end
  return (pkg and pkg .. "." or "") .. stem
end

-- replicated describe_jvm dirname parsing from java-fix.lua
local function describe_ver(base)
  local ver = base:match("^java%-(%d+%.?%d*)")
    or base:match("^jdk%-(%d+%.?%d*)")
    or base:match("^(%d+%.?%d*)")
  if ver and ver:find("^1%.8") then
    ver = "8"
  end
  return ver
end

print("== java-scaffold ==")
ok(has_dots("com.example") == true, "has_dots detects maven pkg")
ok(has_dots("myproject") == false, "has_dots simple name has no dots")
local pkg, dir = parse_project_arg("com.example/myapp", nil)
ok(pkg == "com.example" and dir == "myapp", "slash mode splits pkg/dir (fixed)", pkg .. "/" .. dir)
local pkg2, dir2 = parse_project_arg("com.example", "myapp")
ok(pkg2 == "com.example" and dir2 == "myapp", "space mode pkg/dir")
ok(valid_ident("User") == true, "valid_ident accepts User")
ok(valid_ident("UserDAO") == true, "valid_ident accepts UserDAO")
ok(valid_ident("$Helper") == true, "valid_ident accepts $Helper (fixed)")
ok(valid_ident("OrderStatus") == true, "valid_ident accepts enum name")

print("== java_fqcn ==")
ok(java_fqcn({ "package com.example;", "", "public class Main {}" }, "Main") == "com.example.Main", "fqcn with package")
ok(java_fqcn({ "public class Main {}" }, "Main") == "Main", "fqcn without package")
ok(java_fqcn({ "  package   com.foo.bar  ;" }, "Svc") == "com.foo.bar.Svc", "fqcn extra whitespace")
ok(java_fqcn({ "// package com.fake;", "package real.pkg;" }, "A") == "real.pkg.A", "fqcn skips comment line")

print("== describe_jvm ==")
ok(describe_ver("java-8-openjdk") == "8", "java-8 dirname")
ok(describe_ver("java-26-openjdk") == "26", "java-26 dirname")
ok(describe_ver("java-21-openjdk") == "21", "java-21 dirname")

print("== java-maven mvnw path (fixed) ==")
local maven_lua = io.open(os.getenv("HOME") .. "/.config/nvim/lua/plugins/java-maven.lua", "r")
if maven_lua then
  local src = maven_lua:read("*a")
  maven_lua:close()
  ok(src:find('%.mvnw') == nil, "no hidden .mvnw check remains")
  ok(src:find('/mvnw') ~= nil, "checks root/mvnw wrapper")
  ok(src:find('project_root') ~= nil, "uses project_root not cwd")
  ok(src:find('vim%.fs%.find%("pom%.xml", { path =') ~= nil, "pom search anchored at buffer path")
else
  ok(false, "can open java-maven.lua")
end

print("== compiler lazy cmd (fixed) ==")
local comp = io.open(os.getenv("HOME") .. "/.config/nvim/lua/plugins/compiler.lua", "r")
if comp then
  local src = comp:read("*a")
  comp:close()
  ok(src:find("CompilerStop") ~= nil, "CompilerStop referenced")
  ok(src:find('cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo", "CompilerStop"') ~= nil,
    "CompilerStop present in cmd lazy lists (fixed)")
  ok(src:find('vim%.fs%.find%("pom%.xml", { path =') ~= nil, "pom search anchored at file dir (fixed)")
  ok(src:find('project_root_for') ~= nil, "uses project_root_for not getcwd (fixed)")
else
  ok(false, "can open compiler.lua")
end

print("== java-fix portable (fixed) ==")
local jf = io.open(os.getenv("HOME") .. "/.config/nvim/lua/plugins/java-fix.lua", "r")
if jf then
  local src = jf:read("*a")
  jf:close()
  ok(src:find("jvm_search_dirs") ~= nil, "portable jvm_search_dirs helper")
  ok(src:find("/Library/Java/JavaVirtualMachines") ~= nil, "macOS JVM path covered")
  ok(src:find("vim%.env%.MASON") ~= nil, "$MASON via vim.env (fixed)")
  ok(src:find('expand%("%$MASON') == nil, "no legacy expand($MASON) remains")
else
  ok(false, "can open java-fix.lua")
end

print("== stack conform/plenary (fixed) ==")
local st = io.open(os.getenv("HOME") .. "/.config/nvim/lua/plugins/stack.lua", "r")
if st then
  local src = st:read("*a")
  st:close()
  ok(src:find('php = { "pint" }') ~= nil, "php uses pint only (fixed)")
  ok(src:find('blade = { "blade_formatter" }') ~= nil, "blade_formatter scoped to blade ft (fixed)")
  ok(src:find('"nvim%-lua/plenary%.nvim",%s*init = function') ~= nil, "plenary uses init (fixed merge)")
  ok(src:find("css_variables = { enabled = false }") ~= nil, "css_variables disabled (EACCES crash fixed)")
  ok(src:find("unknownAtRules") ~= nil, "cssls flags unknown at-rules (fixed)")
else
  ok(false, "can open stack.lua")
end

print("== round2 shell/python/clipboard/scaffold (fixed) ==")
local comp2 = io.open(os.getenv("HOME") .. "/.config/nvim/lua/plugins/compiler.lua", "r")
if comp2 then
  local src = comp2:read("*a")
  comp2:close()
  ok(src:find("shellescape") ~= nil, "shellescape helper present")
  ok(src:find('" .. bufname .. "') == nil, "no raw double-quoted bufname")
  ok(src:find('executable%("python3"%)') ~= nil, "python prefers python3")
else
  ok(false, "can open compiler.lua round2")
end
local optf = io.open(os.getenv("HOME") .. "/.config/nvim/lua/config/options.lua", "r")
if optf then
  local src = optf:read("*a")
  optf:close()
  ok(src:find("getregtype") ~= nil, "clipboard paste returns regtype")
else
  ok(false, "can open options.lua")
end
local scaf = io.open(os.getenv("HOME") .. "/.config/nvim/lua/plugins/java-scaffold.lua", "r")
if scaf then
  local src = scaf:read("*a")
  scaf:close()
  ok(src:find("is_simple_project%(base") ~= nil, "is_simple_project takes base")
  ok(src:find("invalid folder") ~= nil, "folder traversal guard")
else
  ok(false, "can open java-scaffold.lua")
end

print(string.format("\n%d passed, %d failed", passes, failures))
os.exit(failures == 0 and 0 or 1)
