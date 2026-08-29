-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Alt-j/k to move lines (works for single line in Normal/Insert and multi-line in Visual)
-- Fixed: E16 Invalid range at buffer boundaries, count support, silent handling

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

-- Insert: move current line, stay in insert (supports v:count, noautocmd suppresses brace match flash)
vim.keymap.set(
  "i",
  "<A-j>",
  "<esc><cmd>silent! keepjumps execute 'm .+' . v:count1<cr><cmd>noautocmd silent! normal! ==<cr>gi",
  { desc = "Move line down", silent = true }
)
vim.keymap.set(
  "i",
  "<A-k>",
  "<esc><cmd>silent! keepjumps execute 'm .-' . (v:count1+1)<cr><cmd>noautocmd silent! normal! ==<cr>gi",
  { desc = "Move line up", silent = true }
)

-- Visual: move block (1 line or more) — string mapping uses '<,'> marks set on leaving Visual
-- via :<C-u>, so multi-line selections (e.g. V2j selects 3 lines) move as a whole;
-- v:count1 handles "2 Alt-j" to move block by 2, silent!+keepjumps suppresses E16, noautocmd suppresses brace flash
vim.keymap.set(
  "v",
  "<A-j>",
  ":<C-u>silent! keepjumps execute \"'<,'>move '>+\" . v:count1<cr>:noautocmd silent! normal! gv=gv<cr>",
  { desc = "Move selection down", silent = true }
)
vim.keymap.set(
  "v",
  "<A-k>",
  ":<C-u>silent! keepjumps execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>:noautocmd silent! normal! gv=gv<cr>",
  { desc = "Move selection up", silent = true }
)

-- Ctrl-z Undo / Ctrl-y Redo (GUI style) — v covers visual+select, no need for separate x
-- Note: <C-y> overrides Vim default scroll-up-line (use <C-e> or <C-b> fallback), <C-z> overrides :stop suspend
vim.keymap.set({ "n", "v" }, "<C-z>", "u", { desc = "Undo", silent = true })
vim.keymap.set("i", "<C-z>", "<C-o>u", { desc = "Undo", silent = true })
vim.keymap.set({ "n", "v" }, "<C-y>", "<C-r>", { desc = "Redo", silent = true })
vim.keymap.set("i", "<C-y>", "<C-o><C-r>", { desc = "Redo", silent = true })
