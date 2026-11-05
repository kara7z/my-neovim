return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    opts = {
      variant = "main",
      dark_variant = "main",
      dim_inactive_windows = false,
      styles = {
        transparency = true,
      },
      highlight_groups = {
        Normal = { bg = "NONE" },
        NormalNC = { bg = "NONE" },
        NormalFloat = { bg = "NONE" },
        FloatBorder = { fg = "iris", bg = "NONE" },
        TelescopeNormal = { bg = "NONE" },
        TelescopeBorder = { fg = "iris", bg = "NONE" },
        NeoTreeNormal = { bg = "NONE" },
        NeoTreeNormalNC = { bg = "NONE" },
        WhichKeyNormal = { bg = "NONE" },
        SnacksNormal = { bg = "NONE" },
        SnacksWinBar = { bg = "NONE" },
        LspInlayHint = { fg = "muted", bg = "NONE", italic = true },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine",
    },
  },
}
