-- Exercise real plugin specs and commands, not copies of their implementation.
local failures = 0
local function check(condition, name)
  if condition then
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name)
  end
end

local config_dir = vim.env.NVIM_CONFIG_DIR or vim.fn.stdpath("config")
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local original_cwd = vim.fn.getcwd()
local old_notify = vim.notify
local notifications = {}
vim.notify = function(message, level, ...)
  notifications[#notifications + 1] = { message = tostring(message), level = level }
  return old_notify(message, level, ...)
end

local function edit(path, ft)
  vim.cmd("noautocmd edit! " .. vim.fn.fnameescape(path))
  if ft then
    vim.cmd("noautocmd setlocal filetype=" .. ft)
  end
end

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end

local ok, err = xpcall(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  require("lazy").load({ plugins = { "bufferline.nvim", "compiler.nvim", "blink.cmp", "nvim-dap-ui", "nvim-lint" } })
  vim.wait(100)
  check(vim.fn.exists(":JavaProject") == 2, "JavaProject survives plugin spec merging")
  check(vim.fn.exists(":JavaClass") == 2, "JavaClass survives plugin spec merging")
  check(vim.filetype.match({ filename = "index.blade.php" }) == "blade", "Blade filetype is preserved")
  check(vim.filetype.match({ filename = ".env.production" }) == "sh", "dotenv filetype is preserved")
  check(
    vim.filetype.match({ filename = "example.environment.lua" }) ~= "sh",
    "dotenv pattern does not capture unrelated files"
  )

  for _, group in ipairs({
    "Normal",
    "NormalFloat",
    "BufferLineFill",
    "BufferLineBufferSelected",
    "SnacksPickerDirectory",
  }) do
    check(vim.api.nvim_get_hl(0, { name = group, link = false }).bg == nil, group .. " stays transparent")
  end
  for _, notice in ipairs(notifications) do
    check(not notice.message:find("not a valid highlight"), "no invalid Bufferline highlight: " .. notice.message)
  end

  local registry = require("blink.cmp.sources.snippets.default.registry").new({})
  local snippets = registry:get_snippets_for_ft("java")
  for _, prefix in ipairs({ "enum", "record", "abstract", "annotation", "method", "interface", "class", "main", "ctor" }) do
    check(
      vim.iter(snippets):any(function(s)
        return s.prefix == prefix
      end),
      "Java snippet available: " .. prefix
    )
  end
  edit(temp .. "/Status.java")
  for _, snippet in ipairs(snippets) do
    if snippet.prefix == "enum" then
      local body = type(snippet.body) == "table" and table.concat(snippet.body, "\n") or snippet.body
      vim.snippet.expand(registry:expand_vars(body, 1))
      check(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "public enum Status {", "enum expands with filename")
      vim.snippet.stop()
      vim.bo.modified = false
      break
    end
  end

  -- Use the real scaffolding commands in a disposable project.
  vim.cmd.cd(temp)
  vim.cmd("JavaProject sample")
  edit(temp .. "/sample/src/Main.java")
  vim.cmd("noautocmd JavaClass User models")
  local user = temp .. "/sample/src/models/User.java"
  check(vim.fn.filereadable(user) == 1, "JavaClass uses the buffer's project root, not cwd")
  check(vim.fn.readfile(user)[1] == "package models;", "generated classes declare their folder package")
  vim.cmd("noautocmd JavaClass Status enums")
  local status = table.concat(vim.fn.readfile(temp .. "/sample/src/enums/Status.java"), "\n")
  check(
    status:find("package enums;", 1, true) ~= nil and status:find("public enum Status", 1, true) ~= nil,
    "generated enums have an importable package"
  )
  vim.cmd("JavaProject com..broken invalid")
  check(vim.fn.isdirectory(temp .. "/invalid") == 0, "empty Java package segments are rejected")
  vim.cmd("JavaProject com.example maven-sample")
  local pom = table.concat(vim.fn.readfile(temp .. "/maven-sample/pom.xml"), "\n")
  check(pom:find("maven-compiler-plugin", 1, true) ~= nil, "generated Maven projects support compiler.release")
  if vim.fn.executable("javac") == 1 then
    vim.fn.mkdir(temp .. "/classes", "p")
    local output = vim.fn.system({
      "javac",
      "-d",
      temp .. "/classes",
      temp .. "/sample/src/Main.java",
      user,
      temp .. "/sample/src/enums/Status.java",
    })
    check(vim.v.shell_error == 0, "generated Java sources compile: " .. output)
  end

  local java_opts = dofile(config_dir .. "/lua/plugins/java-fix.lua")[2].opts(nil, {})
  check(
    java_opts.project_name(temp .. "/one/demo") ~= java_opts.project_name(temp .. "/two/demo"),
    "same-named Java projects use separate workspaces"
  )

  -- Capture task definitions without running a compiler or stopping real jobs.
  local overseer = require("overseer")
  local tasks = {}
  overseer.new_task = function(definition)
    local task = { definition = definition, status = "PENDING" }
    function task:start()
      self.status = "RUNNING"
    end
    function task:stop()
      self.stopped = true
      self.status = "CANCELED"
    end
    tasks[#tasks + 1] = task
    return task
  end
  overseer.open = function() end
  local unrelated_stopped = false
  overseer.list_tasks = function()
    return { {
      status = "RUNNING",
      stop = function()
        unrelated_stopped = true
      end,
    } }
  end
  local run = vim.fn.maparg("<F5>", "n", false, true).callback
  check(type(run) == "function", "F5 runner loads")
  edit(user, "java")
  run()
  check(tasks[1].definition.cmd:find("find src", 1, true) ~= nil, "simple Java project compiles all source files")
  check(tasks[1].definition.cwd == temp .. "/sample", "F5 task uses the source project directory")
  check(
    tasks[1].definition.cmd:find(vim.fn.shellescape("models.User"), 1, true) ~= nil,
    "Java runner uses qualified class name"
  )
  local single = temp .. "/single/Single.java"
  write(single, { "package demo.pkg;", "public class Single {}" })
  edit(single, "java")
  run()
  check(
    tasks[2].definition.cmd:find(vim.fn.shellescape("demo.pkg.Single"), 1, true) ~= nil,
    "packaged single Java files run with the qualified name"
  )
  check(tasks[1].stopped and not unrelated_stopped, "F5 replaces only its own previous task")

  local cpp_file = temp .. "/C++ quotes/$cash's.cpp"
  write(cpp_file, { "int main() { return 0; }" })
  edit(cpp_file, "cpp")
  require("compiler.languages.cpp").action("option2")
  local cpp_task = tasks[#tasks].definition
  check(
    cpp_task.cmd:find(vim.fn.shellescape(cpp_file), 1, true) ~= nil,
    "C++ compiler quotes special characters in source paths"
  )
  check(
    cpp_task.cmd:find(vim.fn.shellescape("Build OK: " .. temp .. "/C++ quotes/bin/$cash's"), 1, true) ~= nil,
    "build success message cannot expand shell characters"
  )

  -- Bound the Spring detector even when a tree contains no build files.
  local filter = dofile(config_dir .. "/lua/plugins/spring-boot.lua")[1].opts.project_filter
  check(filter(nil) == false, "Spring detector handles missing roots")
  local scan, next_entry, readfile = vim.uv.fs_scandir, vim.uv.fs_scandir_next, vim.fn.readfile
  local scans = 0
  vim.uv.fs_scandir = function()
    scans = scans + 1
    return { done = false }
  end
  vim.uv.fs_scandir_next = function(handle)
    if not handle.done then
      handle.done = true
      return "nested", "directory"
    end
  end
  vim.fn.readfile = function()
    error("no build file")
  end
  local filter_ok, result = pcall(filter, temp)
  vim.uv.fs_scandir, vim.uv.fs_scandir_next, vim.fn.readfile = scan, next_entry, readfile
  check(filter_ok and result == false and scans <= 200, "Spring detector has a finite directory budget")

  local messages = vim.api.nvim_exec2("messages", { output = true }).output
  check(
    not messages:find("Failed to run", 1, true) and not messages:find("Error detected", 1, true),
    "no plugin startup errors"
  )
end, debug.traceback)

if not ok then
  failures = failures + 1
  print(err)
end
vim.notify = old_notify
vim.cmd("noautocmd enew!")
vim.cmd.cd(original_cwd)
vim.fn.delete(temp, "rf")
if failures > 0 then
  print(failures .. " configuration regression(s) failed")
  vim.cmd("cquit 1")
else
  print("ALL CONFIGURATION REGRESSIONS PASS")
  vim.cmd("qa!")
end
