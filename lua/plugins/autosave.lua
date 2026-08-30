return {
  "okuuva/auto-save.nvim",
  version = "^1.0.0", -- overrides LazyVim global version=false to pin stable tag
  event = { "InsertLeave", "TextChanged" },
  cmd = "ASToggle",
  opts = {
    enabled = true,
    -- no autosave while in insert mode: only TextChanged in normal, immediate after InsertLeave
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost", "InsertLeave" },
      defer_save = { "TextChanged" },
      cancel_deferred_save = { "InsertEnter" },
    },
    condition = function(buf)
      if buf == 0 then
        buf = vim.api.nvim_get_current_buf()
      end
      if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
        return false
      end
      if vim.bo[buf].buftype ~= "" then
        return false
      end
      if vim.api.nvim_buf_get_name(buf) == "" then
        return false
      end
      return vim.bo[buf].modifiable and not vim.bo[buf].readonly
    end,
    write_all_buffers = false,
    debounce_delay = 300,
  },
}
