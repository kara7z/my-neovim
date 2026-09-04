return {
  "mfussenegger/nvim-lint",
  opts = {
    linters = {
      selene = {
        -- fix: nvim-lint runs selene via stdin (cwd = project), so it wouldn't find selene.toml in ~/.config/nvim
        -- pass explicit config so vim/LazyVim globals are recognized for nvim config files
        args = {
          "--display-style",
          "json",
          "--config",
          vim.fn.expand("~/.config/nvim/selene.toml"),
          "-",
        },
      },
    },
    linters_by_ft = {
      -- php: php -l for syntax only (intelephense handles undefined + unused inside functions via LSP, global unused not flagged by design)
      -- phpcs/psalm/phpstan disabled (too noisy or needs config, global unused rarely needed)
      php = { "php" },
      -- lua: selene for unused variable (luacheck broken on lua5.5, lua_ls single-file often misses)
      lua = { "selene" },
    },
  },
}
