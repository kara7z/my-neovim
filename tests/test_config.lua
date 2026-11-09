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
  check(java_opts.dap_main == false, "debug main-class discovery does not run during LSP attachment")
  local standalone = java_opts.jdtls({ root_dir = temp, settings = {} })
  check(
    standalone.settings.java.import.maven.enabled == false and standalone.settings.java.import.gradle.enabled == false,
    "standalone files do not import nested build projects"
  )
  check(
    vim.tbl_isempty(standalone.settings.java.project.referencedLibraries),
    "standalone files do not search recursively for dependency jars"
  )
  check(
    vim.deep_equal(standalone.init_options.settings, standalone.settings),
    "Java settings are sent during initialization before project discovery"
  )

  local java = require("config.java")
  local plugins, extensions = temp .. "/plugins", temp .. "/extensions"
  write(plugins .. "/org.objectweb.asm_9.10.1.jar", {})
  write(extensions .. "/org.objectweb.asm_9.9.jar", {})
  write(extensions .. "/jacocoagent.jar", {})
  write(extensions .. "/com.microsoft.java.test.runner-jar-with-dependencies.jar", {})
  write(extensions .. "/com.microsoft.java.test.plugin.jar", {})
  assert(vim.uv.fs_symlink(extensions .. "/com.microsoft.java.test.plugin.jar", extensions .. "/alias.jar"))
  local filtered = java.filter_bundles(vim.fn.glob(extensions .. "/*.jar", false, true), plugins)
  check(
    #filtered == 1 and vim.uv.fs_realpath(filtered[1]) == extensions .. "/com.microsoft.java.test.plugin.jar",
    "extension bundles exclude launchers, built-in dependencies and symlink duplicates"
  )

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

  -- Nested unrelated projects must not enable Spring for a standalone file.
  local filter = dofile(config_dir .. "/lua/plugins/spring-boot.lua")[1].opts.project_filter
  check(filter(nil) == false, "Spring detector handles missing roots")
  write(temp .. "/unrelated/pom.xml", { "<project><groupId>org.springframework.boot</groupId></project>" })
  check(filter(temp) == false, "Spring ignores unrelated descendant projects")
  check(filter(temp .. "/unrelated") == true, "actual Spring projects still enable Spring tooling")
  local budget_root = temp .. "/scan-budget"
  write(budget_root .. "/pom.xml", { "<project/>" })
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
  vim.fn.readfile = function(path)
    if path == budget_root .. "/pom.xml" then
      return { "<project/>" }
    end
    error("no build file")
  end
  local filter_ok, result = pcall(filter, budget_root)
  vim.uv.fs_scandir, vim.uv.fs_scandir_next, vim.fn.readfile = scan, next_entry, readfile
  check(filter_ok and result == false and scans == 200, "Spring detector has a finite directory budget")

  -- A slow JDTLS must not turn Spring's server requests into vim.wait calls.
  local spring_config = require("config.spring")
  local spring_file = temp .. "/unrelated/src/RootCheck.java"
  write(spring_file, { "class RootCheck {}" })
  edit(spring_file, "java")
  local spring_root
  spring_config.root_dir(vim.api.nvim_get_current_buf(), function(root)
    spring_root = root
  end)
  check(spring_root == temp .. "/unrelated", "Spring finds Maven roots independently of cwd and wrapper scripts")
  edit(single, "java")
  spring_root = nil
  spring_config.root_dir(vim.api.nvim_get_current_buf(), function(root)
    spring_root = root
  end)
  check(spring_root == nil, "Spring does not fall back to the current directory for standalone files")
  local handlers = require("config.spring").handlers
  local get_clients, get_client, wait = vim.lsp.get_clients, vim.lsp.get_client_by_id, vim.wait
  local forwarded, callbacks = {}, {}
  local spring = {
    id = -1,
    config = { root_dir = "/spring/project" },
    is_stopped = function()
      return false
    end,
    request = function(_, _, params)
      callbacks[#callbacks + 1] = params
    end,
  }
  vim.lsp.get_client_by_id = function()
    return spring
  end
  vim.lsp.get_clients = function()
    return {
      {
        config = { root_dir = "/other/project" },
        request = function()
          error("wrong Java workspace")
        end,
      },
      {
        config = { root_dir = "/spring/project" },
        request = function(_, _, params)
          forwarded[#forwarded + 1] = params
        end,
      },
    }
  end
  vim.wait = function()
    error("blocking wait in Spring LSP handler")
  end
  local add_ok, add_result = pcall(
    handlers["sts/addClasspathListener"],
    nil,
    { callbackCommandId = "test.classpath" },
    { client_id = -1 }
  )
  local callback_ok = add_ok and pcall(vim.lsp.commands["test.classpath"], { "classpath" })
  local remove_ok, remove_result = pcall(
    handlers["sts/removeClasspathListener"],
    nil,
    { callbackCommandId = "test.classpath" },
    { client_id = -1 }
  )
  vim.lsp.get_clients, vim.lsp.get_client_by_id, vim.wait = get_clients, get_client, wait
  check(
    add_ok and add_result == vim.NIL and remove_ok and remove_result == vim.NIL,
    "Spring startup handlers return immediately even if JDTLS never replies"
  )
  check(
    #forwarded == 2
      and forwarded[1].command == "sts.java.addClasspathListener"
      and forwarded[2].command == "sts.java.removeClasspathListener",
    "Spring requests go to the matching Java workspace"
  )
  check(
    callback_ok and #callbacks == 1 and vim.lsp.commands["test.classpath"] == nil,
    "asynchronous Spring classpath callbacks are forwarded and cleaned up"
  )

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
