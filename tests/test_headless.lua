-- Headless regression test for lua/config/keymaps.lua move logic.
-- Run with:
--   nvim --headless --noplugin -u NONE --cmd "set rtp+=~/.config/nvim" -c "luafile ~/.config/nvim/tests/test_headless.lua"
-- Exits 0 on pass, non-zero on fail (uses cquit on failure).

local failures = 0
local function ok(cond, name, extra)
  if cond then
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. (extra and (" | " .. tostring(extra)) or ""))
  end
end

local ok_req, err = pcall(require, "config.keymaps")
ok(ok_req, "require config.keymaps", err)

local function hasmap(lhs, mode)
  local m = vim.fn.maparg(lhs, mode, false, true)
  return type(m) == "table" and not vim.tbl_isempty(m)
end

ok(hasmap("<A-j>", "n"), "normal <A-j> mapped")
ok(hasmap("<A-k>", "n"), "normal <A-k> mapped")
ok(hasmap("<A-j>", "i"), "insert <A-j> mapped")
ok(hasmap("<A-k>", "i"), "insert <A-k> mapped")
ok(hasmap("<A-j>", "x"), "visual <A-j> mapped")
ok(hasmap("<C-z>", "n"), "normal <C-z> undo mapped")
ok(hasmap("<C-y>", "n"), "normal <C-y> redo mapped")

-- Boundary safety: single-line buffer, Alt-j/k must be no-ops, no E16
vim.cmd("enew!")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "only" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local before = vim.api.nvim_buf_get_lines(0, 0, -1, false)
-- feed the lua functions via normal-mode keypress using the mapped callback:
-- use vim.fn.maparg callback indirectly: just press keys and ensure no error + no change
local ok_down = pcall(function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<A-j>", true, false, true), "x!", false)
end)
local after_down = vim.api.nvim_buf_get_lines(0, 0, -1, false)
ok(ok_down, "Alt-j on last line does not error")
ok(vim.deep_equal(before, after_down), "Alt-j on single line is no-op")

local ok_up = pcall(function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<A-k>", true, false, true), "x!", false)
end)
local after_up = vim.api.nvim_buf_get_lines(0, 0, -1, false)
ok(ok_up, "Alt-k on first line does not error")
ok(vim.deep_equal(before, after_up), "Alt-k on single line is no-op")

-- Multi-line move down then up round-trips
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
pcall(function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<A-j>", true, false, true), "x!", false)
end)
vim.wait(50)
local moved = vim.api.nvim_buf_get_lines(0, 0, -1, false)
ok(moved[1] == "b" and moved[2] == "a", "Alt-j moves line down", vim.inspect(moved))

-- Readonly guard must not error
vim.bo.readonly = true
local ok_ro = pcall(function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<A-j>", true, false, true), "x!", false)
end)
ok(ok_ro, "Alt-j on readonly does not error")
vim.bo.readonly = false

-- Undo grouping check: move then undojoin then == is CORRECT per :h undojoin
-- ("join further changes with previous"): indent joins the move block.
local f = io.open(vim.fn.expand("~/.config/nvim/lua/config/keymaps.lua"), "r")
local src = f and f:read("*a") or ""
if f then
  f:close()
end
local move_pos = src:find("execute 'move")
local undo_pos = src:find('pcall%(vim.cmd, "undojoin"%)')
local indent_pos = src:find("normal! ==")
ok(move_pos ~= nil and undo_pos ~= nil and move_pos < undo_pos and undo_pos < (indent_pos or 1e9),
  "undojoin groups indent with move (correct order)")

if failures > 0 then
  print(string.format("%d FAILURES", failures))
  vim.cmd("cquit 1")
else
  print("ALL HEADLESS PASS")
  vim.cmd("qa!")
end
