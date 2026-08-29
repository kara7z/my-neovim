return {
  "okuuva/auto-save.nvim",
  version = "^1.0.0",
  event = { "InsertLeave", "TextChanged" },
  cmd = "ASToggle",
  opts = {
    enabled = true,
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost" },
      defer_save = { "InsertLeave", "TextChanged" },
      cancel_deferred_save = { "InsertEnter" },
    },
    condition = function(buf)
      if buf == 0 then
        buf = vim.api.nvim_get_current_buf()
      end
      return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable and not vim.bo[buf].readonly
    end,
    write_all_buffers = false,
    debounce_delay = 1000,
  },
}
