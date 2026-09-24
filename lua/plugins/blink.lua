return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "enter",
      ["<Tab>"] = { LazyVim.cmp.map({ "snippet_forward", "ai_nes", "ai_accept" }), "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", LazyVim.cmp.map({ "snippet_backward" }), "fallback" },
      -- select_and_accept: Enter works even when preselect is lost
      -- (accept alone needs a selection and falls back to newline)
      ["<CR>"] = { "select_and_accept", "fallback" },
      ["<C-y>"] = { "select_and_accept", "fallback" },
      -- manual fallback when auto-show stops: force menu, then Enter
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
    },
  },
}
