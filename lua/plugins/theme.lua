return {
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    main = "flexoki",
    priority = 1000,
    opts = {
      variant = "dark",
      highlight_groups = {
        Normal = { fg = "#CECDC3", bg = "NONE" },
        NormalNC = { fg = "#CECDC3", bg = "NONE" },
        NormalFloat = { fg = "#CECDC3", bg = "NONE" },
        FloatBorder = { fg = "#4385BE", bg = "NONE" },
        TelescopeNormal = { bg = "NONE" },
        TelescopeBorder = { fg = "#4385BE", bg = "NONE" },
        NeoTreeNormal = { bg = "NONE" },
        NeoTreeNormalNC = { bg = "NONE" },
        WhichKeyNormal = { bg = "NONE" },
        SnacksNormal = { bg = "NONE" },
        SnacksWinBar = { bg = "NONE" },
        SignColumn = { bg = "NONE" },
        EndOfBuffer = { bg = "NONE" },
        LineNr = { fg = "#6F6E69", bg = "NONE" },
        CursorLineNr = { fg = "#D0A215", bg = "NONE" },
        CursorLine = { bg = "NONE" },
        FoldColumn = { fg = "#6F6E69", bg = "NONE" },
        WinSeparator = { fg = "#403E3C", bg = "NONE" },
        StatusLine = { fg = "#CECDC3", bg = "NONE" },
        StatusLineNC = { fg = "#878580", bg = "NONE" },
        WinBar = { fg = "#CECDC3", bg = "NONE" },
        WinBarNC = { fg = "#878580", bg = "NONE" },
        NeoTreeEndOfBuffer = { bg = "NONE" },
        Pmenu = { fg = "#CECDC3", bg = "NONE" },
        WhichKeyFloat = { bg = "NONE" },
        LspInlayHint = { fg = "#878580", bg = "NONE", italic = true },
        -- Match the explorer and picker windows to Flexoki, not default blue.
        Directory = { fg = "#D0A215", bg = "NONE" },
        SnacksPickerDirectory = { fg = "#D0A215", bg = "NONE" },
        SnacksPickerDir = { fg = "#878580", bg = "NONE" },
        SnacksPickerFile = { fg = "#CECDC3", bg = "NONE" },
        SnacksPickerNormal = { fg = "#CECDC3", bg = "NONE" },
        SnacksPickerBorder = { fg = "#575653", bg = "NONE" },
        SnacksPickerInputBorder = { fg = "#3AA99F", bg = "NONE" },
        SnacksPickerTitle = { fg = "#D0A215", bg = "NONE", bold = true },
        SnacksPickerTree = { fg = "#575653", bg = "NONE" },
        SnacksPickerMatch = { fg = "#DA702C", bold = true },
        SnacksPickerCursorLine = { bg = "#282726" },
        -- High-contrast targets for Flash's f/F/t/T character searches.
        FlashBackdrop = { fg = "#6F6E69" },
        FlashMatch = { fg = "#CECDC3", bg = "#403E3C", bold = true },
        FlashCurrent = { fg = "#100F0F", bg = "#DFB431", bold = true },
        FlashLabel = { fg = "#100F0F", bg = "#87D3C3", bold = true },
        TabLine = { fg = "#878580", bg = "NONE" },
        TabLineFill = { bg = "NONE" },
        TabLineSel = { fg = "#D0A215", bg = "NONE", bold = true },
        -- Brighter Flexoki accents stay readable over the blurred wallpaper.
        Comment = { fg = "#9F9D96", italic = true },
        ["@keyword"] = { fg = "#CE5D97", bold = true },
        ["@keyword.type"] = { fg = "#CE5D97", bold = true },
        ["@keyword.modifier"] = { fg = "#A699D0" },
        ["@type"] = { fg = "#DFB431" },
        ["@type.builtin"] = { fg = "#DA702C" },
        ["@function"] = { fg = "#66A0C8" },
        ["@function.method"] = { fg = "#66A0C8" },
        ["@function.call"] = { fg = "#66A0C8" },
        ["@function.method.call"] = { fg = "#66A0C8" },
        ["@string"] = { fg = "#A0AF54" },
        ["@number"] = { fg = "#EC8B49" },
        ["@boolean"] = { fg = "#EC8B49" },
        ["@variable.parameter"] = { fg = "#87D3C3" },
        ["@variable.member"] = { fg = "#5ABDAC" },
        ["@attribute"] = { fg = "#A699D0" },
        ["@lsp.type.interface"] = { fg = "#DFB431", bold = true },
        ["@lsp.type.class"] = { fg = "#DFB431" },
        ["@lsp.type.annotation"] = { fg = "#A699D0" },
        DiagnosticError = { fg = "#E8705F" },
        DiagnosticWarn = { fg = "#DFB431" },
        DiagnosticInfo = { fg = "#66A0C8" },
        DiagnosticHint = { fg = "#5ABDAC" },
        DiagnosticSignError = { fg = "#E8705F", bg = "NONE" },
        DiagnosticSignWarn = { fg = "#DFB431", bg = "NONE" },
        DiagnosticVirtualTextError = { fg = "#E8705F", bg = "NONE" },
        DiagnosticVirtualTextWarn = { fg = "#DFB431", bg = "NONE" },
        DiagnosticUnderlineError = { sp = "#E8705F", undercurl = true },
        DiagnosticUnderlineWarn = { sp = "#DFB431", undercurl = true },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      -- Bufferline has its own palette; keep every tab surface transparent.
      opts.highlights = opts.highlights or {}
      local colors = {
        fill = "#878580",
        background = "#878580",
        tab = "#878580",
        tab_selected = "#D0A215",
        tab_separator = "#403E3C",
        tab_separator_selected = "#D0A215",
        tab_close = "#878580",
        offset_separator = "#403E3C",
      }
      for _, suffix in ipairs({ "", "_visible", "_selected" }) do
        local selected = suffix == "_selected"
        colors["buffer" .. suffix] = selected and "#D0A215" or "#878580"
        colors["numbers" .. suffix] = selected and "#D0A215" or "#6F6E69"
        colors["close_button" .. suffix] = selected and "#CECDC3" or "#6F6E69"
        colors["separator" .. suffix] = "#403E3C"
        if suffix ~= "" then
          colors["indicator" .. suffix] = "#3AA99F"
        end
        colors["modified" .. suffix] = "#DA702C"
        colors["diagnostic" .. suffix] = "#878580"
        for severity, color in pairs({
          error = "#E8705F",
          warning = "#DFB431",
          info = "#66A0C8",
          hint = "#5ABDAC",
        }) do
          colors[severity .. suffix] = color
          colors[severity .. "_diagnostic" .. suffix] = color
        end
      end
      for group, fg in pairs(colors) do
        opts.highlights[group] = { fg = fg, bg = "NONE", italic = false, bold = group:find("selected") ~= nil }
      end
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "flexoki-dark",
    },
  },
}
