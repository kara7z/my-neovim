return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      -- php: php -l for syntax only (intelephense handles undefined + unused in functions via LSP)
      -- phpcs disabled (too noisy), phpstan not needed for unused (intelephense covers function scope)
      php = { "php" },
      -- lua: selene for unused variable (luacheck broken on lua5.5, lua_ls single-file often misses)
      lua = { "selene" },
    },
  },
}
