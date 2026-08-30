-- Web dev stack: Laravel PHP (blade), Java, Angular, C/C++, Vue, React, TS/JS, Node, Lua, HTML/CSS/Tailwind
-- Full web stack kept; C++ first-class via clangd + clang-format + codelldb
return {
  -- Treesitter: ensure parsers for all stack languages (single spec, merged)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "blade",
        "c",
        "cpp",
        "css",
        "dockerfile",
        "html",
        "java",
        "javascript",
        "json",
        "jsonc",
        "lua",
        "markdown",
        "markdown_inline",
        "php",
        "php_only",
        "python",
        "query",
        "regex",
        "scss",
        "tsx",
        "typescript",
        "vue",
        "yaml",
        "comment",
        "git_config",
        "gitignore",
        "ini",
        "toml",
      })
    end,
  },

  -- Mason: ensure LSP/tools for stack (eslint for JS errors)
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "blade-formatter",
        "clangd",
        "clang-format",
        "codelldb",
        "css-lsp",
        "css-variables-language-server",
        "emmet-language-server",
        "eslint-lsp",
        "eslint_d",
        "html-lsp",
        "intelephense",
        "jdtls",
        "lua-language-server",
        "marksman",
        "prettier",
        "shfmt",
        "stylua",
        "tailwindcss-language-server",
        "typescript-language-server",
        "vue-language-server",
        "yaml-language-server",
      })
    end,
  },

  -- LSP: html/css/json/yaml/lua + eslint for JS errors, intelephense strict for PHP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
        css_variables = {},
        emmet_language_server = {},
        jsonls = {},
        yamlls = {},
        dockerls = {},
        docker_compose_language_service = {},
        eslint = {},
        -- php: intelephense strict diagnostics for undefined symbols (fixes index.php accepting bad syntax)
        intelephense = {
          settings = {
            intelephense = {
              diagnostics = {
                undefinedTypes = true,
                undefinedFunctions = true,
                undefinedConstants = true,
                undefinedClassConstants = true,
                undefinedMethods = true,
                undefinedProperties = true,
                undefinedVariables = true,
              },
            },
          },
        },
        phpactor = { enabled = false },
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
            },
          },
        },
        -- blade handled via html + php; use intelephense for php (php extra already sets)
        -- tailwind, vtsls, vue_ls, angularls, jdtls, clangd covered by extras
      },
    },
  },

  -- Conform: prettier + clang-format on save (pint conditional for non-composer projects)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        lua = { "stylua" },
        sh = { "shfmt" },
        php = { "pint", "blade_formatter" },
      },
      formatters = {
        pint = {
          condition = function(_, ctx)
            return vim.fs.find("composer.json", { path = ctx.dirname, upward = true })[1] ~= nil
          end,
        },
      },
    },
  },

  -- Blade filetype detection (Laravel) + .env
  {
    "nvim-lua/plenary.nvim",
    event = "BufReadPre",
    config = function()
      vim.filetype.add({
        pattern = {
          [".*%.blade%.php"] = "blade",
          [".*%.env.*"] = "sh",
        },
        filename = {
          [".env"] = "sh",
          [".env.example"] = "sh",
          [".env.local"] = "sh",
        },
      })
    end,
  },
}
