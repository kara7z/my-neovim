-- Exercise actual mappings, including Visual and blockwise selections.
local failures = 0
local function check(condition, name)
  print((condition and "PASS " or "FAIL ") .. name)
  if not condition then
    failures = failures + 1
  end
end
local function keys(value)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(value, true, false, true), "xt", false)
end
local function reset(lines)
  if vim.b.VM_Selection and vim.b.VM_Selection.Regions then
    vim.fn["vm#reset"]()
  end
  vim.cmd("noautocmd enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end
local function contents()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end
local function regions()
  local selection = vim.b.VM_Selection
  return selection and selection.Regions or {}
end

local ok, err = xpcall(function()
  vim.cmd("doautocmd User VeryLazy")
  if vim.g.clipboard and vim.g.clipboard.name == "wl-clipboard" then
    check(type(vim.g.clipboard.paste["+"]) == "string", "clipboard paste does not recursively read register type")
    check(type(vim.g.clipboard.paste["*"]) == "string", "primary selection uses native clipboard provider")
  end
  -- No dependence on a running Wayland compositor for editing regressions.
  vim.opt.clipboard = ""

  for _, key in ipairs({ "<A-j>", "<A-k>" }) do
    reset({ "    keep_indent" })
    vim.bo.indentexpr = "0"
    keys("i" .. key .. "<Esc>")
    check(vim.deep_equal(contents(), { "    keep_indent" }), "Insert " .. key .. " at boundary preserves indentation")

    reset({ "one", "two" })
    vim.api.nvim_win_set_cursor(0, { key == "<A-j>" and 1 or 2, 0 })
    vim.bo.readonly = true
    keys("i" .. key .. "<Esc>")
    check(vim.deep_equal(contents(), { "one", "two" }), "Insert " .. key .. " does not move readonly lines")
    vim.bo.readonly = false
  end
  reset({ "one", "two", "three" })
  keys("i<A-j>X<Esc>")
  check(vim.deep_equal(contents(), { "two", "Xone", "three" }), "Insert Alt+j moves line and keeps insertion position")
  keys("i<A-k><Esc>")
  check(vim.deep_equal(contents(), { "Xone", "two", "three" }), "Insert Alt+k moves line back")

  for _, key in ipairs({ "<A-j>", "<A-k>" }) do
    reset({ "    keep_indent" })
    vim.bo.indentexpr = "0"
    keys("V" .. key .. "<Esc>")
    check(vim.deep_equal(contents(), { "    keep_indent" }), "Visual " .. key .. " at boundary preserves indentation")
    reset({ "one", "two" })
    vim.api.nvim_win_set_cursor(0, { key == "<A-j>" and 1 or 2, 0 })
    vim.bo.readonly = true
    keys("V" .. key .. "<Esc>")
    check(vim.deep_equal(contents(), { "one", "two" }), "Visual " .. key .. " does not move readonly selections")
    vim.bo.readonly = false
  end
  reset({ "one", "two", "three" })
  keys("Vj<A-j><Esc>")
  check(vim.deep_equal(contents(), { "three", "one", "two" }), "Visual Alt+j moves the entire selection")
  keys("gv<A-k><Esc>")
  check(vim.deep_equal(contents(), { "one", "two", "three" }), "Visual Alt+k moves the selection back")

  reset({ "ABC DEF" })
  keys("A!<Esc>")
  keys("0viw<C-z>")
  check(vim.deep_equal(contents(), { "ABC DEF" }), "Visual Ctrl+Z undoes instead of lowercasing")
  keys("viw<C-y>")
  check(vim.deep_equal(contents(), { "ABC DEF!" }), "Visual Ctrl+Y redoes after leaving selection")

  reset({ "foo   foo", "   ", "foo bar foo" })
  for _ = 1, 12 do
    keys("<C-d>")
  end
  check(#regions() == 4, "held Ctrl+D only selects original matches")
  check(
    vim.iter(regions()):all(function(region)
      return region.txt == "foo"
    end),
    "repeated Ctrl+D does not select whitespace"
  )
  keys("cX<Esc>")
  check(
    vim.deep_equal(contents(), { "X   X", "   ", "X bar X" }),
    "multi-cursor replacement preserves surrounding text"
  )

  reset({ "   " })
  keys("<C-d>")
  check(#regions() == 0, "Ctrl+D on whitespace is a no-op")

  reset({ "foo bar / foo bar / foo bar" })
  keys("v6l<C-d>")
  check(#regions() == 2, "Visual Ctrl+D immediately adds the next phrase")
  keys("<C-d>")
  check(#regions() == 3, "Visual phrase selection supports repeated Ctrl+D")

  reset({ "foobar foobar foobar" })
  keys("v2l<C-d>")
  check(#regions() == 2 and regions()[2].txt == "foo", "Visual Ctrl+D preserves partial-word selections")

  reset({ "foo a", "foo b", "foo c" })
  keys("<C-v>j2l<C-d>")
  check(#regions() == 2, "blockwise Ctrl+D creates separate regions per line")
  keys("cX<Esc>")
  check(
    vim.deep_equal(contents(), { "X a", "X b", "foo c" }),
    "block replacement preserves suffixes and unselected lines"
  )

  reset({ "foo foo foo" })
  keys("<C-d><C-d><C-d>")
  keys("<Plug>(VM-Goto-Prev)")
  keys("<C-S-d>")
  check(
    #regions() == 2 and regions()[1].a == 1 and regions()[2].a == 5,
    "Ctrl+Shift+D removes last-added region after navigation"
  )
end, debug.traceback)
if not ok then
  failures = failures + 1
  print(err)
end
if failures > 0 then
  vim.cmd("cquit 1")
else
  print("ALL EDITING REGRESSIONS PASS")
  vim.cmd("qa!")
end
