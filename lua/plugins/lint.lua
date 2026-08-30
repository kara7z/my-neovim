return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      -- php: use `php -l` for syntax only, not phpcs (PSR12) which flags closing tag/spacing for every file
      -- intelephense LSP still provides semantic diagnostics (undefined vars, types) without style noise
      php = { "php" },
      -- lua: selene for unused variable (luacheck broken on lua5.5, lua_ls single-file often misses)
      lua = { "selene" },
    },
  },
}
