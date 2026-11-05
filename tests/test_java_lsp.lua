-- Optional integration test: requires installed JDTLS and its Java 25+ runner.
local temp = vim.fn.tempname()
local single = vim.env.NVIM_TEST_JAVA_SINGLE == "1"
local source_dir = single and temp or (temp .. "/src")
vim.fn.mkdir(source_dir, "p")
local source = source_dir .. "/CompletionCheck.java"
if single then
  vim.fn.mkdir(temp .. "/unrelated", "p")
  vim.fn.writefile({ "<project><groupId>org.springframework.boot</groupId></project>" }, temp .. "/unrelated/pom.xml")
end
vim.fn.writefile({
  "public class CompletionCheck {",
  "  public static void main(String[] args) {",
  "    System.out.pr",
  "  }",
  "}",
}, source)

local client
local ok, err = xpcall(function()
  local started = vim.uv.hrtime()
  vim.cmd.edit(source)
  local edit_ms = (vim.uv.hrtime() - started) / 1e6
  assert(edit_ms < 2000, "Opening the Java buffer blocked Neovim for " .. edit_ms .. "ms")
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
  if single then
    assert(client.config.settings.java.import.maven.enabled == false, "Standalone file imports nested Maven projects")
    assert(#vim.lsp.get_clients({ name = "spring-boot" }) == 0, "Spring started for an unrelated nested project")
  end
  local seen = {}
  for _, bundle in ipairs(client.config.init_options.bundles or {}) do
    local path = vim.uv.fs_realpath(bundle) or bundle
    assert(not seen[path], "Duplicate Java extension bundle: " .. path)
    assert(
      not path:match("jacocoagent%.jar$") and not path:match("runner%-jar%-with%-dependencies%.jar$"),
      "Non-OSGi artifact passed as a bundle: " .. path
    )
    seen[path] = true
  end
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
  print(
    ("PASS %s Java startup, completion, diagnostics and nonblocking buffer open (%.0fms)"):format(
      single and "standalone" or "project",
      edit_ms
    )
  )
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
