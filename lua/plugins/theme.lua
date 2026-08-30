return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      transparent = false,
      styles = {
        sidebars = "dark",
        floats = "dark",
      },
      on_colors = function(colors)
        colors.bg = "#000000"
        colors.bg_dark = "#000000"
        colors.bg_highlight = "#0a0a0a"
        colors.bg_visual = "#1a1a1a"
        colors.bg_sidebar = "#000000"
        colors.bg_float = "#000000"
      end,
      on_highlights = function(hl, c)
        hl.Normal = { bg = "#000000", fg = c.fg }
        hl.NormalNC = { bg = "#000000", fg = c.fg }
        hl.NormalFloat = { bg = "#000000" }
        hl.FloatBorder = { bg = "#000000", fg = c.border_highlight }
        hl.TelescopeNormal = { bg = "#000000" }
        hl.TelescopeBorder = { bg = "#000000" }
        hl.NeoTreeNormal = { bg = "#000000" }
        hl.NeoTreeNormalNC = { bg = "#000000" }
        hl.WhichKeyNormal = { bg = "#000000" }
        hl.SnacksNormal = { bg = "#000000" }
        hl.SnacksWinBar = { bg = "#000000" }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
