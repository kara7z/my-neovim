-- InsertLeave and autosave's BufWritePost can lint the same snapshot twice.
local last_lint = {}
local function changed_snapshot()
  local buf = vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local now = vim.uv.hrtime()
  local last = last_lint[buf]
  if last and last.tick == tick and now - last.time < 750000000 then
    return false
  end
  last_lint[buf] = { tick = tick, time = now }
  return true
end
vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("user_lint_snapshots", { clear = true }),
  callback = function(ev)
    last_lint[ev.buf] = nil
  end,
})

return {
  "mfussenegger/nvim-lint",
  opts = {
    linters = {
      selene = {
        condition = changed_snapshot,
        -- fix: nvim-lint runs selene via stdin (cwd = project), so it wouldn't find selene.toml in ~/.config/nvim
        -- pass explicit config so vim/LazyVim globals are recognized for nvim config files
        args = {
          "--display-style",
          "json",
          "--config",
          vim.fn.expand("~/.config/nvim/selene.toml"),
          "-",
        },
      },
      php = { condition = changed_snapshot },
    },
    linters_by_ft = {
      -- php: php -l for syntax only (intelephense handles undefined + unused inside functions via LSP, global unused not flagged by design)
      -- phpcs/psalm/phpstan disabled (too noisy or needs config, global unused rarely needed)
      php = { "php" },
      -- lua: selene for unused variable (luacheck broken on lua5.5, lua_ls single-file often misses)
      lua = { "selene" },
    },
  },
}
