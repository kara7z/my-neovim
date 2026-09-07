return {
  "mg979/vim-visual-multi",
  branch = "master",
  event = "VeryLazy",
  init = function()
    vim.g.VM_maps = {
      ["Find Under"] = "<C-d>",
      ["Find Subword Under"] = "<C-d>",
      ["Skip Region"] = "q",
      ["Remove Region"] = "Q",
    }
    vim.g.VM_theme = "iceblue"
    vim.g.VM_highlight_matches = "underline"
    vim.g.VM_case_setting = "sensitive"
    vim.g.VM_silent_exit = 1
    vim.g.VM_show_warnings = 0
  end,
  config = function()
    -- Ctrl+Shift+d to return to last cursor (VSCode style) — v covers visual+select
    -- keep Q (Remove Region) as fallback for terminals where Ctrl+Shift+d folds to Ctrl-d
    -- requires kitty_keyboard_mode 3 for distinct Ctrl+Shift+d (optional)
    pcall(vim.keymap.set, "n", "<C-S-d>", "<Plug>(VM-Remove-Region)", { silent = true, desc = "VM Remove last" })
    pcall(vim.keymap.set, "v", "<C-S-d>", "<Plug>(VM-Remove-Region)", { silent = true, desc = "VM Remove last" })
  end,
}
