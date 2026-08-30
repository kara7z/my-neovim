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
        -- unused variable with cyan (LazyVim tokyonight cyan #7dcfff) - DiagnosticUnnecessary is used for unused
        hl.DiagnosticUnnecessary = { fg = c.cyan, bg = "#000000" }
        hl.DiagnosticHint = { fg = c.cyan, bg = "#000000" }
        hl.DiagnosticWarn = { fg = c.yellow, bg = "#000000" }
        -- also set LspInlayHint and unnecessary for treesitter
        hl.LspInlayHint = { fg = c.cyan, bg = "#1a1a1a" }
        hl["@variable"] = { fg = c.fg }
        hl["@lsp.type.variable"] = { fg = c.fg }
        hl["@lsp.typemod.variable.readonly"] = { fg = c.cyan }
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
