return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.routes = opts.routes or {}
      table.insert(opts.routes, 1, {
        filter = {
          event = "notify",
          find = "^Spring Boot LS is not ready, waiting for start$",
        },
        opts = { skip = true },
      })
      table.insert(opts.routes, 1, {
        filter = {
          event = "lsp",
          kind = "progress",
          cond = function(message)
            local progress = message.opts and message.opts.progress
            return progress and progress.client == "jdtls" or false
          end,
        },
        opts = { skip = true },
      })
    end,
  },
}
