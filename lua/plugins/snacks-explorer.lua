-- Keep the explorer from following the current buffer, but show live Git changes.
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            focus = "list",
            follow_file = false,
            watch = true,
            git_status = true,
            diagnostics = false,
          },
        },
      },
    },
  },
}
