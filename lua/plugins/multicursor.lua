return {
  "mg979/vim-visual-multi",
  branch = "master",
  event = "VeryLazy",
  init = function()
    vim.g.VM_maps = {
      ["Find Under"] = "",
      ["Find Subword Under"] = "",
      ["Skip Region"] = "q",
      ["Remove Region"] = "Q",
    }
    -- Let the colorscheme define the VM highlights instead of a built-in palette.
    vim.g.VM_theme = ""
    vim.g.VM_highlight_matches = "underline"
    vim.g.VM_case_setting = "sensitive"
    vim.g.VM_silent_exit = 1
    vim.g.VM_show_warnings = 0
  end,
  config = function()
    vim.keymap.set("n", "<C-d>", function()
      -- Query a scalar in Vimscript instead of copying all regions into Lua.
      if vim.fn.eval("exists('b:VM_Selection.Regions') && !empty(b:VM_Selection.Regions)") == 1 then
        return "<Plug>(VM-Find-Next)"
      end

      -- Do not let key repeat start a new whitespace search between words.
      local char = vim.fn.strcharpart(vim.fn.getline("."), vim.fn.charcol(".") - 1, 1)
      if char == "" or char:match("%s") then
        return ""
      end
      return "<Plug>(VM-Find-Under)"
    end, { expr = true, silent = true, desc = "Select word or next matching occurrence" })

    -- Start with the exact visual selection and immediately add its next match.
    vim.keymap.set("x", "<C-d>", function()
      -- Blocks need one region per line, not a single multiline search.
      if vim.fn.mode() == "\22" then
        return "<Plug>(VM-Visual-Add)"
      end
      return "<Plug>(VM-Find-Subword-Under)<Plug>(VM-Find-Next)"
    end, {
      expr = true,
      silent = true,
      desc = "Select next occurrence of visual selection",
    })

    -- Ctrl+Shift+d to return to last cursor (VSCode style) — v covers visual+select
    -- keep Q (Remove Region) as fallback for terminals where Ctrl+Shift+d folds to Ctrl-d
    -- requires kitty_keyboard_mode 3 for distinct Ctrl+Shift+d (optional)
    pcall(vim.keymap.set, "n", "<C-S-d>", "<Plug>(VM-Remove-Last-Region)", { silent = true, desc = "VM Remove last" })
    pcall(vim.keymap.set, "v", "<C-S-d>", "<Plug>(VM-Remove-Last-Region)", { silent = true, desc = "VM Remove last" })
  end,
}
