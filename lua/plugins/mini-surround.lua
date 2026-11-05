return {
  {
    "nvim-mini/mini.surround",
    version = "*",
    opts = {
      silent = true,
      mappings = {
        add = "sa",
        delete = "sd",
        find = "sf",
        find_left = "sF",
        highlight = "sh",
        replace = "sr",
        update_n_lines = "sn",
      },
    },
  },
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        char = { autohide = false },
      },
    },
    config = function(_, opts)
      require("flash").setup(opts)

      -- Keep character navigation active across ordinary cursor movements.
      -- Flash still handles Escape, InsertEnter, and BufLeave normally.
      local char = require("flash.plugins.char")
      vim.api.nvim_clear_autocmds({ group = "flash_char", event = "CursorMoved" })
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = "flash_char",
        callback = function()
          if char.visible() and not char.jumping then
            char.state:update({ force = true })
          end
        end,
      })
    end,
    keys = {
      { "s", mode = { "n", "x", "o" }, false },
    },
  },
}
