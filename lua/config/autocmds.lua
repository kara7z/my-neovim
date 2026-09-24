-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Terminal performance: :terminal typing delay fix.
-- Root cause: global cursorline/scrolloff/sidescrolloff/foldmethod=indent leak into
-- terminal windows and force full redraw + fold recompute on every keystroke.
-- Neovim core TermOpen only clears number/rel/signcolumn/wrap/list, so clear the rest here.
local term_perf = vim.api.nvim_create_augroup("user_terminal_perf", { clear = true })
vim.api.nvim_create_autocmd({ "TermOpen", "BufWinEnter" }, {
  group = term_perf,
  pattern = { "term://*" },
  callback = function(ev)
    vim.opt_local.cursorline = false
    vim.opt_local.cursorcolumn = false
    vim.opt_local.scrolloff = 0
    vim.opt_local.sidescrolloff = 0
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.foldexpr = "0"
    vim.opt_local.foldenable = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.spell = false
    vim.opt_local.list = false
    vim.opt_local.wrap = false
    -- belt-and-braces: keep snacks/indent animations off in terminals
    -- (scroll/indent/scope already filter buftype=terminal, but custom toggles may re-enable)
    vim.b[ev.buf].snacks_animate = false
    vim.b[ev.buf].snacks_indent = false
    vim.b[ev.buf].snacks_scope = false
    vim.b[ev.buf].snacks_scroll = false
    vim.b[ev.buf].miniindentscope_disable = true
  end,
})
-- Snacks.terminal sets filetype=snacks_terminal; cover it even if buftype pattern misses
vim.api.nvim_create_autocmd("FileType", {
  group = term_perf,
  pattern = { "snacks_terminal" },
  callback = function(ev)
    vim.opt_local.cursorline = false
    vim.opt_local.cursorcolumn = false
    vim.opt_local.scrolloff = 0
    vim.opt_local.sidescrolloff = 0
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.foldenable = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.spell = false
    vim.b[ev.buf].snacks_animate = false
    vim.b[ev.buf].miniindentscope_disable = true
  end,
})

-- Blink completion debug: run :BlinkDebug WHEN Enter stops accepting
-- (do NOT restart first). It writes /tmp/blink_debug.txt for diagnosis.
vim.api.nvim_create_user_command("BlinkDebug", function()
  local lines = {}
  local function add(s)
    lines[#lines + 1] = s
  end
  add("filetype=" .. vim.bo.filetype .. " mode=" .. vim.api.nvim_get_mode().mode)
  add("imap<CR>=" .. vim.inspect(vim.fn.maparg("<CR>", "i", false, true)):sub(1, 300))
  local ok_blink, blink = pcall(require, "blink.cmp")
  add("blink_loaded=" .. tostring(ok_blink))
  if ok_blink then
    add("menu_visible=" .. tostring(blink.is_menu_visible()))
    add("visible(any)=" .. tostring(blink.is_visible()))
    local ok_list, list = pcall(require, "blink.cmp.completion.list")
    if ok_list then
      add("list_items=" .. tostring(list.items and #list.items or -1))
      add("list_context=" .. tostring(list.context ~= nil))
    end
  end
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    add("lsp_clients=none")
  else
    for _, c in ipairs(clients) do
      add("lsp=" .. c.name .. " id=" .. c.id)
    end
  end
  vim.fn.writefile(lines, "/tmp/blink_debug.txt")
  vim.notify("BlinkDebug written to /tmp/blink_debug.txt", vim.log.levels.INFO)
end, { desc = "Dump blink/LSP state when Enter stops working" })

-- Blink <CR> guard: blink applies buffer-local insert mappings once per
-- buffer on InsertEnter and skips re-apply if ANY blink mapping exists
-- (see blink.cmp/keymap/apply.lua). If another plugin overwrites buffer
-- <CR> afterwards (LspAttach, multicursor exit, etc.), blink never restores
-- it until restart -> Enter does newline despite visible menu.
-- Re-apply on every InsertEnter when <CR> is no longer blink's.
vim.api.nvim_create_autocmd("InsertEnter", {
  desc = "Restore blink <CR> if overwritten",
  callback = function()
    local ok_cfg, cfg = pcall(require, "blink.cmp.config")
    local ok_km, km = pcall(require, "blink.cmp.keymap")
    local ok_apply, apply = pcall(require, "blink.cmp.keymap.apply")
    if not (ok_cfg and ok_km and ok_apply) then
      return
    end
    if not cfg.enabled() then
      return
    end
    local buf_maps = vim.api.nvim_buf_get_keymap(0, "i")
    local has_blink = false
    local cr_is_blink = false
    for _, m in ipairs(buf_maps) do
      if m.desc and m.desc:find("^blink%.cmp") then
        has_blink = true
        -- lhs can be "<CR>" or raw "\r"
        if m.lhs == "<CR>" or m.lhs == "\r" or (m.lhsraw or "") == "\r" then
          cr_is_blink = true
          break
        end
      end
    end
    if has_blink and not cr_is_blink then
      -- Clear stale blink buffer mappings so apply doesn't early-return,
      -- then re-apply current config mappings to this buffer.
      for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, "i")) do
        if m.desc and m.desc:find("^blink%.cmp") then
          pcall(vim.api.nvim_buf_del_keymap, 0, "i", m.lhs)
        end
      end
      local mappings = km.get_mappings(cfg.keymap, "default")
      apply.keymap_to_current_buffer(mappings)
    end
  end,
})
