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

  -- Mason: ensure LSP/tools for stack (eslint for JS, selene for lua)
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
        "java-debug-adapter",
        "java-test",
        "lua-language-server",
        "marksman",
        "prettier",
        "selene",
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
  -- Fix clangd --function-arg-placeholders invalid for clangd 22 (was bare flag, needs value or omitted)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sqlls = { enabled = false },
        sqls = { enabled = false },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--fallback-style=llvm",
          },
        },
        html = {},
        cssls = {
          settings = {
            css = { lint = { unknownAtRules = "error", emptyRules = "warn", duplicateProperties = "error" } },
            scss = { lint = { unknownAtRules = "error", emptyRules = "warn", duplicateProperties = "error" } },
            less = { lint = { unknownAtRules = "error", emptyRules = "warn", duplicateProperties = "error" } },
          },
        },
        -- Disabled: css-variables-language-server crashes with EACCES scandir on
        -- Steam Proton prefixes (dosdevices/z:/boot) when cwd is $HOME, exits 1.
        -- cssls + tailwindcss already cover CSS; re-enable with a tight root_dir if needed.
        css_variables = { enabled = false },
        emmet_language_server = {},
        jsonls = {},
        yamlls = {},
        dockerls = {},
        docker_compose_language_service = {},
        eslint = {},
        -- php: intelephense strict diagnostics for undefined + unused symbols
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
                undefinedVariables = "on",
                unusedSymbols = true,
              },
            },
          },
        },
        phpactor = { enabled = false },
        psalm = { enabled = false },
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
                -- enable unused variable diagnostics for Lua (also via luacheck)
                enable = true,
                neededFileStatus = {
                  ["unused-local"] = "Any",
                  ["unused-vararg"] = "Any",
                  ["codestyle-check"] = "None",
                },
              },
              workspace = { checkThirdParty = false },
            },
          },
        },
        -- JS/TS: enable unused variable via typescript settings (vtsls/ts_ls via jsconfig/tsconfig)
        vtsls = {
          settings = {
            javascript = {
              inlayHints = { enumMemberValues = { enabled = true } },
            },
            typescript = {
              inlayHints = { enumMemberValues = { enabled = true } },
            },
          },
        },
        -- blade handled via html + php; use intelephense for php (php extra already sets)
        -- tailwind, vtsls, vue_ls, angularls, jdtls, clangd covered by extras
      },
    },
  },

  -- Conform: prettier + clang-format on save (pint conditional for non-composer projects)
  -- php uses pint only when composer.json exists; blade files use blade_formatter.
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
        php = { "pint" },
        blade = { "blade_formatter" },
      },
      formatters = {
        pint = {
          condition = function(_, ctx)
            if not ctx or not ctx.dirname then
              return false
            end
            return vim.fs.find("composer.json", { path = ctx.dirname, upward = true })[1] ~= nil
          end,
        },
      },
    },
  },

  -- Blade filetype detection (Laravel) + .env
  -- NOTE: plenary is also specced in java-scaffold.lua (init defines commands).
  -- Use init here too so both init functions run (lazy merges same-plugin specs;
  -- mixing init + config risks the config override hiding commands).
  {
    "nvim-lua/plenary.nvim",
    init = function()
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
