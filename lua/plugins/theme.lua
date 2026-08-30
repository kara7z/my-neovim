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
        colors.bg_visual = "#33467c"
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
        -- make Visual selection clearly visible on true black (was #1a1a1a too dark)
        hl.Visual = { bg = "#33467c", fg = c.fg }
        hl.VisualNOS = { bg = "#33467c", fg = c.fg }
        -- search word highlight (when you press * or select word)
        hl.Search = { bg = c.yellow, fg = "#000000" }
        hl.IncSearch = { bg = c.orange, fg = "#000000" }
        hl.CurSearch = { bg = c.red, fg = "#ffffff" }
        -- lsp references when selecting word
        hl.LspReferenceText = { bg = "#3b4261" }
        hl.LspReferenceRead = { bg = "#3b4261" }
        hl.LspReferenceWrite = { bg = "#3b4261" }
        -- unused variable subtle hidden like before (faded, not cyan) - DiagnosticUnnecessary is used for unused
        hl.DiagnosticUnnecessary = { fg = c.fg_gutter, bg = "#000000", italic = true }
        hl.DiagnosticHint = { fg = c.hint, bg = "#000000" }
        hl.DiagnosticInfo = { fg = c.fg_gutter, bg = "#000000", italic = true }
        -- keep inlay hints subtle
        hl.LspInlayHint = { fg = c.comment, bg = "#1a1a1a", italic = true }
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
