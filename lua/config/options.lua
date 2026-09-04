-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- PHP LSP: use intelephense for stricter diagnostics (undefined vars/constants) instead of phpactor default
vim.g.lazyvim_php_lsp = "intelephense"

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

-- Undo/redo history for 200+ steps (default 10000, keep high for 200 redo via 200Ctrl-Shift-z)
vim.opt.undolevels = 10000
vim.opt.undoreload = 10000
-- Disable unused providers to silence checkhealth warnings (perl optional, python/ruby installed)
vim.g.loaded_perl_provider = 0
-- LSP/Java: don't validate on every keystroke (fixes "validate document" spam)
vim.diagnostic.config({ update_in_insert = false })
vim.opt.updatetime = 500
-- re-apply after LazyVim overwrites diagnostics in lsp/init.lua
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    vim.schedule(function()
      vim.diagnostic.config({ update_in_insert = false })
      -- hide jdtls "Validate documents" / "Publish Diagnostics" progress popup (keep validation, just no UI) - global handler
      if vim.lsp.handlers["$/progress"] and vim.lsp.handlers["$/progress"]._filtered then
        return
      end
      local orig_progress = vim.lsp.handlers["$/progress"]
      local wrapped = function(err, result, ctx, config)
        if result and result.value then
          local title = result.value.title or ""
          local message = result.value.message or ""
          local t = title:lower()
          local m = message:lower()
          if
            title:match("Validate")
            or message:match("Validate")
            or t:match("publish")
            or m:match("publish")
            or t:match("diagnostics")
            or m:match("diagnostics")
          then
            return
          end
        end
        if orig_progress then
          return orig_progress(err, result, ctx, config)
        end
      end
      wrapped._filtered = true
      vim.lsp.handlers["$/progress"] = wrapped
    end)
  end,
})

-- Per-client filter: hide only Validate progress for jdtls (keep other progress / fix _java.reloadBundles error)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "jdtls" then
      -- keep language/status hidden (already via jdtls opts), ensure diagnostics hidden in insert
      vim.diagnostic.config({ update_in_insert = false })
      -- wrap $/progress to filter Validate / Publish messages so lualine/snacks don't spam (avoid double patch)
      local existing = client.handlers["$/progress"]
      if existing and existing._filtered then
        return
      end
      local orig = existing or vim.lsp.handlers["$/progress"]
      local wrapped = function(err, result, ctx, config)
        if result and result.value then
          local title = result.value.title or ""
          local message = result.value.message or ""
          local t = title:lower()
          local m = message:lower()
          if
            title:match("Validate")
            or message:match("Validate")
            or t:match("publish")
            or m:match("publish")
            or t:match("diagnostics")
            or m:match("diagnostics")
          then
            return
          end
        end
        if orig then
          return orig(err, result, ctx, config)
        end
      end
      wrapped._filtered = true
      client.handlers["$/progress"] = wrapped
    end
  end,
})

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
