-- Optional integration test: requires installed JDTLS and its Java 25+ runner.
local temp = vim.fn.tempname()
vim.fn.mkdir(temp .. "/src", "p")
local source = temp .. "/src/CompletionCheck.java"
vim.fn.writefile({
  "public class CompletionCheck {",
  "  public static void main(String[] args) {",
  "    System.out.pr",
  "  }",
  "}",
}, source)

local client
local ok, err = xpcall(function()
  vim.cmd.edit(source)
  assert(
    vim.wait(60000, function()
      for _, candidate in ipairs(vim.lsp.get_clients({ name = "jdtls", bufnr = 0 })) do
        if candidate.initialized then
          client = candidate
          return true
        end
      end
      return false
    end, 200),
    "JDTLS did not initialize"
  )
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(0) },
    position = { line = 2, character = #"    System.out.pr" },
    context = { triggerKind = 1 },
  }
  local response = client:request_sync("textDocument/completion", params, 30000, 0)
  assert(response and not response.err, "Java completion request failed")
  local items = response.result and (response.result.items or response.result) or {}
  assert(
    vim.iter(items):any(function(item)
      return item.label and item.label:match("^println")
    end),
    "Java method completions did not include println"
  )
  assert(
    client.config.capabilities.textDocument.completion.completionItem.snippetSupport,
    "JDTLS is not receiving snippet capabilities"
  )
  assert(
    vim.wait(20000, function()
      return #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR }) > 0
    end, 200),
    "Invalid Java code did not produce error diagnostics"
  )
  print("PASS JDTLS Java 25 startup, method completion, snippet support and error diagnostics")
end, debug.traceback)

if client then
  client:stop(true)
end
vim.cmd("noautocmd enew!")
vim.fn.delete(temp, "rf")
if ok then
  vim.cmd("qa!")
else
  print(err)
  vim.cmd("cquit 1")
end
