-- Run with: nvim --headless -u init.lua -l tests/test_terminal_keymaps.lua
-- Wait for LazyVim's VeryLazy keymaps before checking the actual mappings.
vim.defer_fn(function()
  local ok, err = pcall(function()
    local leader = vim.g.mapleader or "\\"
    for _, mapping in ipairs(vim.api.nvim_get_keymap("t")) do
      assert(mapping.lhs:sub(1, #leader) ~= leader, "Terminal leader mapping delays shell input: " .. mapping.lhs)
    end
    local mapping = vim.fn.maparg(leader .. "at", "n", false, true)
    assert(mapping.desc == "Toggle OpenCode terminal", "Normal-mode OpenCode shortcut must remain available")
  end)
  if not ok then
    vim.api.nvim_err_writeln(tostring(err))
    vim.cmd("cquit 1")
    return
  end
  print("PASS: no terminal leader timeout; normal-mode OpenCode shortcut preserved")
  vim.cmd("qa!")
end, 100)
vim.wait(10000, function()
  return false
end)
