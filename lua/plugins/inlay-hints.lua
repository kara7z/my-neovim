return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
    init = function()
      vim.lsp.inlay_hint.enable(false)
    end,
  },
}
