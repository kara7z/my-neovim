-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- CachyOS/Sway + Wayland: system clipboard via wl-copy/wl-paste
vim.opt.clipboard = "unnamedplus"
-- Explicit wl-clipboard provider for Wayland (fallback if LazyVim doesn't detect)
if vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1 then
  vim.g.clipboard = {
    name = "wl-clipboard",
    copy = {
      ["+"] = "wl-copy --foreground --type text/plain",
      ["*"] = "wl-copy --foreground --type text/plain --primary",
    },
    paste = {
      ["+"] = function()
        return vim.fn.systemlist('wl-paste --no-newline 2>/dev/null | tr -d "\r"')
      end,
      ["*"] = function()
        return vim.fn.systemlist('wl-paste --primary --no-newline 2>/dev/null | tr -d "\r"')
      end,
    },
    cache_enabled = 1,
  }
end

-- Editor prefs for C++ / web full stack
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.conceallevel = 0
vim.opt.spelllang = { "en" }

-- Disable unused providers to silence checkhealth warnings (perl optional, python/ruby installed)
vim.g.loaded_perl_provider = 0
-- Sway/kitty: faster escape, true colors already via LazyVim
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 10

-- Ensure clipboard stays unnamedplus after LazyVim/OSC52 handling (nvim 0.12+)
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    vim.schedule(function()
      if vim.opt.clipboard:get()[1] ~= "unnamedplus" then
        vim.opt.clipboard = "unnamedplus"
      end
    end)
  end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    vim.schedule(function()
      vim.opt.clipboard = "unnamedplus"
    end)
  end,
})
