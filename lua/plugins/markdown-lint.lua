return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          condition = function(ctx)
            local name = vim.fs.basename(ctx.filename):lower()
            return name ~= "readme" and not name:match("^readme%.")
          end,
        },
      },
    },
  },
}
