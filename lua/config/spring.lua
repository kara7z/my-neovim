local M = {}
local bursts = {}

function M.root_dir(buffer, on_dir)
  local name = vim.fs.basename(vim.api.nvim_buf_get_name(buffer))
  local ft = vim.bo[buffer].filetype
  if ft == "yaml" and not (name:match("^application.*%.ya?ml$") or name:match("^bootstrap.*%.ya?ml$")) then
    return
  end
  if
    ft == "jproperties" and not (name:match("^application.*%.properties$") or name:match("^bootstrap.*%.properties$"))
  then
    return
  end
  -- The plugin defaults to .git/mvnw/gradlew, then cwd, missing ordinary
  -- Maven projects opened from another directory. Never use cwd as a root.
  local root =
    vim.fs.root(buffer, { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" })
  if root and require("config.java").is_spring_project(root) then
    on_dir(root)
  end
end

local function settle(client)
  local burst = bursts[client.id] or { generation = 0, count = 0 }
  bursts[client.id] = burst
  if burst.count >= 2 then
    return
  end
  burst.generation = burst.generation + 1
  local generation = burst.generation
  vim.defer_fn(function()
    if client:is_stopped() or burst.generation ~= generation then
      return
    end
    burst.count = burst.count + 1
    require("spring_boot.settings").push(client)
  end, 1500)
end

local function forward(spring, command, arguments)
  -- Select the JDTLS belonging to this Spring workspace, not the first Java
  -- client in a multi-project session. Never wait for its reply in a handler.
  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    if client.config.root_dir == spring.config.root_dir then
      client:request("workspace/executeCommand", { command = command, arguments = arguments }, function() end)
      return
    end
  end
end

M.handlers = {
  ["sts/addClasspathListener"] = function(_, result, ctx)
    local spring = vim.lsp.get_client_by_id(ctx.client_id)
    if not spring or not result or type(result.callbackCommandId) ~= "string" then
      return vim.NIL
    end
    local command = result.callbackCommandId
    vim.lsp.commands[command] = function(arguments)
      if not spring:is_stopped() then
        spring:request("workspace/executeCommand", { command = command, arguments = arguments }, function()
          settle(spring)
        end)
      end
      return vim.NIL
    end
    forward(spring, "sts.java.addClasspathListener", { command })
    -- The listener is registered asynchronously. An immediate null response is
    -- valid and avoids the plugin's nested vim.wait(8000) blocking user input.
    return vim.NIL
  end,
  ["sts/removeClasspathListener"] = function(_, result, ctx)
    local spring = vim.lsp.get_client_by_id(ctx.client_id)
    if not spring or not result or type(result.callbackCommandId) ~= "string" then
      return vim.NIL
    end
    local command = result.callbackCommandId
    vim.lsp.commands[command] = nil
    forward(spring, "sts.java.removeClasspathListener", { command })
    return vim.NIL
  end,
}

return M
