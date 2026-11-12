-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Alt-j/k to move lines (works for single line in Normal/Insert and multi-line in Visual)
-- E16 guarded at buffer boundaries, count support, silent handling.
-- Undo grouping: :move creates a block, :undojoin joins the following == reindent
-- into the same block (per :h undojoin "join further changes with previous").

local function move_line_down()
  if not vim.bo.modifiable or vim.bo.readonly then
    return
  end
  local count = vim.v.count1
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local last = vim.api.nvim_buf_line_count(0)
  if cur + count > last then
    return
  end
  local view = vim.fn.winsaveview()
  vim.cmd("silent! keepjumps execute 'move .+" .. count .. "'")
  pcall(vim.cmd, "undojoin")
  vim.cmd("noautocmd silent! normal! ==")
  local new_lnum = cur + count
  local lines = vim.api.nvim_buf_get_lines(0, new_lnum - 1, new_lnum, false)
  local line_len = #(lines[1] or "")
  if col > line_len then
    col = line_len
  end
  view.lnum = new_lnum
  view.col = col
  pcall(vim.fn.winrestview, view)
end

local function move_line_up()
  if not vim.bo.modifiable or vim.bo.readonly then
    return
  end
  local count = vim.v.count1
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if cur - count < 1 then
    return
  end
  local view = vim.fn.winsaveview()
  vim.cmd("silent! keepjumps execute 'move .-" .. (count + 1) .. "'")
  pcall(vim.cmd, "undojoin")
  vim.cmd("noautocmd silent! normal! ==")
  local new_lnum = cur - count
  local lines = vim.api.nvim_buf_get_lines(0, new_lnum - 1, new_lnum, false)
  local line_len = #(lines[1] or "")
  if col > line_len then
    col = line_len
  end
  view.lnum = new_lnum
  view.col = col
  pcall(vim.fn.winrestview, view)
end

-- Normal: single line (supports v:count, e.g. 3 Alt-j to move 3 lines down) — <A-j> == <M-j> in nvim
vim.keymap.set("n", "<A-j>", move_line_down, { desc = "Move line down", silent = true })
vim.keymap.set("n", "<A-k>", move_line_up, { desc = "Move line up", silent = true })

-- Insert: reuse the same boundary/readonly guards without leaving Insert mode.
vim.keymap.set("i", "<A-j>", move_line_down, { desc = "Move line down", silent = true })
vim.keymap.set("i", "<A-k>", move_line_up, { desc = "Move line up", silent = true })

-- Visual: guard before leaving the selection, then move/reindent as one undo.
-- :<C-u> sets '<,'> marks; counts move the entire selection by that many lines.
local function move_selection(down)
  if not vim.bo.modifiable or vim.bo.readonly then
    return ""
  end
  local anchor = vim.fn.line("v")
  local cursor = vim.fn.line(".")
  local first, last = math.min(anchor, cursor), math.max(anchor, cursor)
  local count = vim.v.count1
  if (down and last + count > vim.api.nvim_buf_line_count(0)) or (not down and first - count < 1) then
    return ""
  end
  local target = down and last + count or first - count - 1
  return ":<C-u>silent keepjumps '<,'>move " .. target .. "<cr>:undojoin<cr>:noautocmd normal! gv=gv<cr>"
end
vim.keymap.set("x", "<A-j>", function()
  return move_selection(true)
end, { expr = true, desc = "Move selection down", silent = true })
vim.keymap.set("x", "<A-k>", function()
  return move_selection(false)
end, { expr = true, desc = "Move selection up", silent = true })

-- Ctrl-z Undo / Ctrl-y Redo
-- NOTE: insert-mode <C-y> is reserved for blink.cmp select_and_accept
-- (see lua/plugins/blink.lua). Mapping it to redo here would shadow
-- completion confirm and break Enter/Tab flow after VeryLazy loads.
vim.keymap.set("n", "<C-z>", "u", { desc = "Undo", silent = true })
vim.keymap.set("x", "<C-z>", "<Esc>u", { desc = "Undo", silent = true })
vim.keymap.set("i", "<C-z>", "<C-o>u", { desc = "Undo", silent = true })
vim.keymap.set("n", "<C-y>", "<C-r>", { desc = "Redo", silent = true })
vim.keymap.set("x", "<C-y>", "<Esc><C-r>", { desc = "Redo", silent = true })
-- insert redo moved to <C-S-z> so <C-y> stays free for blink
vim.keymap.set("i", "<C-S-z>", "<C-o><C-r>", { desc = "Redo", silent = true })
