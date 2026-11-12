-- Isolated real-module tests: intercept saves/tasks rather than writing files.
local cfg = vim.env.NVIM_CONFIG_DIR or vim.fn.stdpath("config")
vim.opt.rtp:append(cfg)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/auto-save.nvim")
local failures = 0
local function check(condition, label)
  print((condition and "PASS " or "FAIL ") .. label)
  if not condition then
    failures = failures + 1
  end
end

local ok, err = xpcall(function()
  local linter = dofile(cfg .. "/lua/plugins/lint.lua").opts.linters.selene
  check(linter.condition(), "first lint snapshot runs")
  check(not linter.condition(), "duplicate autosave lint snapshot is skipped")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "new snapshot" })
  check(linter.condition(), "editing invalidates lint snapshot immediately")

  -- Autosave uses the installed plugin with its write command intercepted.
  vim.api.nvim_buf_set_name(0, "/virtual/project/Audit.java")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "audit" })
  local actual_cmd, writes = vim.cmd, 0
  vim.cmd = function(command)
    assert(command:find("write"), "unexpected autosave command: " .. command)
    writes = writes + 1
  end
  local spec = dofile(cfg .. "/lua/plugins/autosave.lua")
  spec.config(nil, spec.opts)
  local autosave = require("auto-save")
  vim.api.nvim_exec_autocmds("TextChanged", {})
  autosave.off()
  vim.wait(400, function()
    return writes > 0
  end, 10)
  check(writes == 0, "disabling autosave cancels pending writes")
  autosave.on()
  vim.api.nvim_exec_autocmds("TextChanged", {})
  vim.wait(400, function()
    return writes > 0
  end, 10)
  check(writes == 1, "enabled autosave still writes after debounce")
  vim.api.nvim_exec_autocmds("TextChanged", {})
  vim.api.nvim_exec_autocmds("InsertEnter", {})
  vim.wait(400, function()
    return writes > 1
  end, 10)
  check(writes == 1, "reentering Insert mode cancels pending autosave")
  autosave.off()
  vim.cmd = actual_cmd

  -- YAML setup must provide the dispatcher before Spring tries loading Java.
  local dispatcher = function() end
  package.loaded.spring_boot = {
    execute_client_command = dispatcher,
    setup = function()
      check(
        vim.lsp.handlers["workspace/executeClientCommand"] == dispatcher,
        "Spring installs its dispatcher without JDTLS"
      )
    end,
  }
  vim.lsp.handlers["workspace/executeClientCommand"] = nil
  local spring_spec = dofile(cfg .. "/lua/plugins/spring-boot.lua")[1]
  check(spring_spec.dependencies == nil, "YAML does not eagerly load Java dependency")
  spring_spec.config(nil, {})

  local clients, requests = {}, {}
  local spring = {
    id = 100,
    config = { root_dir = "/virtual/project" },
    is_stopped = function()
      return false
    end,
  }
  vim.lsp.get_client_by_id = function()
    return spring
  end
  vim.lsp.get_clients = function()
    return clients
  end
  local handlers = require("config.spring").handlers
  handlers["sts/addClasspathListener"](nil, { callbackCommandId = "audit.listener" }, { client_id = 100 })
  check(#requests == 0, "Spring listener safely waits for JDTLS")
  clients = {
    {
      config = { root_dir = "/virtual/project" },
      request = function(_, _, params)
        requests[#requests + 1] = params
      end,
    },
  }
  vim.api.nvim_exec_autocmds("LspAttach", { data = { client_id = 101 } })
  vim.api.nvim_exec_autocmds("LspAttach", { data = { client_id = 101 } })
  check(#requests == 1, "late JDTLS attachment registers each pending listener once")
  handlers["sts/removeClasspathListener"](nil, { callbackCommandId = "audit.listener" }, { client_id = 100 })
  check(#requests == 2 and vim.lsp.commands["audit.listener"] == nil, "Spring listener cleanup still works")
  clients = {}
  handlers["sts/addClasspathListener"](nil, { callbackCommandId = "audit.cancelled" }, { client_id = 100 })
  handlers["sts/removeClasspathListener"](nil, { callbackCommandId = "audit.cancelled" }, { client_id = 100 })
  check(vim.lsp.commands["audit.cancelled"] == nil, "removed pending listener is cancelled")

  -- Session saving is counted, never written, including on exit.
  local saves = 0
  package.loaded.persistence = {
    setup = function() end,
    active = function()
      return true
    end,
    save = function()
      saves = saves + 1
    end,
  }
  vim.api.nvim_list_uis = function()
    return { {} }
  end
  dofile(cfg .. "/lua/plugins/session-resume.lua").config(nil, {})
  vim.api.nvim_exec_autocmds("VimEnter", {})
  local before = saves
  for _, event in ipairs({ "BufEnter", "WinEnter", "TabEnter" }) do
    vim.api.nvim_exec_autocmds(event, {})
  end
  vim.wait(650, function()
    return saves > before
  end, 10)
  check(saves == before + 1, "session event burst causes only one save")

  package.loaded.compiler = { setup = function() end }
  package.loaded["compiler.languages.cpp"] = { action = function() end }
  package.loaded["compiler.languages.c"] = { action = function() end }
  local tasks = {}
  package.loaded.overseer = {
    new_task = function(definition)
      tasks[#tasks + 1] = definition
      return { start = function() end }
    end,
    open = function() end,
  }
  dofile(cfg .. "/lua/plugins/compiler.lua")[1].config(nil, {})
  vim.bo.modified = false
  for _, lang in ipairs({ "c", "cpp" }) do
    for _, option in ipairs({ "option1", "option2", "option3" }) do
      require("compiler.languages." .. lang).action(option)
      check(tasks[#tasks].cwd == "/virtual/project", lang .. " " .. option .. " uses source project cwd")
    end
  end
end, debug.traceback)
if not ok then
  failures = failures + 1
  print(err)
end
vim.bo.modified = false
if failures > 0 then
  vim.cmd("cquit 1")
else
  print("ALL BACKGROUND REGRESSIONS PASS")
  vim.cmd("qa!")
end
