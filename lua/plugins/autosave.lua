return {
  "okuuva/auto-save.nvim",
  version = "^1.0.0", -- overrides LazyVim global version=false to pin stable tag
  event = { "InsertLeave", "TextChanged", "BufLeave", "FocusLost" },
  cmd = "ASToggle",
  config = function(_, opts)
    local autosave = require("auto-save")
    local delay = opts.debounce_delay
    local deferred = opts.trigger_events.defer_save
    local cancel_events = opts.trigger_events.cancel_deferred_save
    local immediate = vim.deepcopy(opts.trigger_events.immediate_save)
    local pending = {}
    local function cancel(buf)
      if pending[buf] then
        pending[buf]:stop()
        pending[buf]:close()
        pending[buf] = nil
      end
    end
    -- Own the debounce timers so disabling autosave really cancels them.
    opts.trigger_events.defer_save = {}
    opts.trigger_events.cancel_deferred_save = {}
    table.insert(opts.trigger_events.immediate_save, { "User", pattern = "UserAutoSaveDeferred" })
    opts.debounce_delay = 0
    autosave.setup(opts)
    local group = vim.api.nvim_create_augroup("user_autosave_debounce", { clear = true })
    vim.api.nvim_create_autocmd(deferred, {
      group = group,
      callback = function(ev)
        cancel(ev.buf)
        if not autosave.enabled() or not opts.condition(ev.buf) then
          return
        end
        local timer = vim.uv.new_timer()
        pending[ev.buf] = timer
        timer:start(
          delay,
          0,
          vim.schedule_wrap(function()
            if pending[ev.buf] ~= timer then
              return
            end
            cancel(ev.buf)
            if autosave.enabled() and opts.condition(ev.buf) then
              vim.api.nvim_buf_call(ev.buf, function()
                vim.api.nvim_exec_autocmds("User", { pattern = "UserAutoSaveDeferred" })
              end)
            end
          end)
        )
      end,
    })
    vim.list_extend(cancel_events, immediate)
    table.insert(cancel_events, "BufWipeout")
    vim.api.nvim_create_autocmd(cancel_events, {
      group = group,
      callback = function(ev)
        cancel(ev.buf)
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "AutoSaveDisable",
      callback = function()
        for buf in pairs(pending) do
          cancel(buf)
        end
      end,
    })
  end,
  opts = {
    enabled = true,
    -- Coalesce quick insert/normal transitions before formatting and linting.
    -- Leaving the buffer, losing focus, or quitting still flushes the save.
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" },
      defer_save = { "InsertLeave", "TextChanged" },
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
      if not vim.bo[buf].modifiable or vim.bo[buf].readonly then
        return false
      end
      return true
    end,
    write_all_buffers = false,
    debounce_delay = 300,
  },
}
