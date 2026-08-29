-- Web dev stack: Laravel PHP (blade), Java, Angular, C/C++, Vue, React, TS/JS, Node, Lua, HTML/CSS/Tailwind
return {
  -- Treesitter: ensure parsers for all stack languages
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
      })
    end,
  },

  -- Mason: ensure LSP/tools for stack
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "blade-formatter",
        "clangd",
        "codelldb",
        "css-lsp",
        "css-variables-language-server",
        "emmet-language-server",
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

  -- LSP: html/css/json/yaml/lua (extras cover php/java/tailwind/vue/angular/typescript/clangd)
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

  -- Env & config syntax: ini/toml/git
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "comment",
        "git_config",
        "gitignore",
        "ini",
        "toml",
      })
    end,
  },
}
