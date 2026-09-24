-- Snacks explorer: stop the brief cursor jump on open/refresh.
-- Cause: follow_file re-finds current buffer after first render, then async
-- git_status/diagnostics + watch refresh the list again, moving the cursor.
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            focus = "list",
            follow_file = false,
            watch = false,
            git_status = false,
            diagnostics = false,
          },
        },
      },
    },
  },
}
