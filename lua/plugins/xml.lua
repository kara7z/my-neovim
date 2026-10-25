return {
  -- XML diagnostics, completion, and formatting via LemMinX.
  -- LazyVim installs configured servers through Mason automatically.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lemminx = {},
      },
    },
  },

  -- LazyVim already provides the XML parser and mini.pairs.
  -- Its Conform configuration falls back to LemMinX for XML formatting.
}
