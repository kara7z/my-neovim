return {
  -- 1. Global lsp: don't show diagnostics while typing
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        update_in_insert = false,
      },
    },
  },
  -- 2. jdtls: throttle didChange + validate only on save + run jdtls on Java 21 LTS (requires >=21) while project targets 17 LTS
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- jdtls runner needs Java 21+ even if your project is Java 17 (log: jdtls requires at least Java 21)
      local jdtls_bin = vim.fn.exepath("jdtls")
      if jdtls_bin == "" then
        jdtls_bin = vim.fn.expand("$HOME/.local/share/nvim/mason/bin/jdtls")
      end
      if vim.fn.executable(jdtls_bin) ~= 1 and vim.fn.filereadable(jdtls_bin) ~= 1 then
        -- fallback to mason package path
        jdtls_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"
      end
      local lombok = vim.fn.stdpath("data") .. "/mason/share/jdtls/lombok.jar"
      -- also check legacy $MASON expansion fallback
      if vim.fn.filereadable(lombok) ~= 1 then
        local alt = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
        if alt ~= "$MASON/share/jdtls/lombok.jar" and vim.fn.filereadable(alt) == 1 then
          lombok = alt
        end
      end
      local java21 = "/usr/lib/jvm/java-21-openjdk/bin/java"
      if vim.fn.executable(java21) ~= 1 then
        java21 = vim.fn.exepath("java")
      end
      -- Only advertise JVMs that actually exist (you only have JDK 26).
      -- Listing a missing path with default=true makes jdtls complain.
      local runtimes = {}
      local candidates = {
        { name = "JavaSE-17", path = "/usr/lib/jvm/java-17-openjdk" },
        { name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk" },
        { name = "JavaSE-26", path = "/usr/lib/jvm/java-26-openjdk" },
      }
      for _, r in ipairs(candidates) do
        if vim.fn.executable(r.path .. "/bin/java") == 1 then
          table.insert(runtimes, r)
        end
      end
      if #runtimes > 0 then
        runtimes[#runtimes].default = true
      else
        -- fallback: use whatever `java` resolves to
        local fallback = vim.fn.exepath("java"):gsub("/bin/java$", "")
        if fallback ~= "" then
          runtimes = { { name = "JavaSE-26", path = fallback, default = true } }
        end
      end
      local cmd = { jdtls_bin, "--java-executable", java21 }
      if vim.fn.filereadable(lombok) == 1 then
        table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok))
      end
      opts.cmd = cmd

      opts.jdtls = vim.tbl_deep_extend("force", opts.jdtls or {}, {
        flags = {
          debounce_text_changes = 800,
          allow_incremental_sync = true,
        },
        handlers = {
          ["language/status"] = function() end,
        },
      })

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          autobuild = { enabled = false },
          maxConcurrentBuilds = 1,
          saveActions = { organizeImports = false },
          completion = {
            enabled = true,
            lazyResolveTextEdit = { enabled = false },
          },
          configuration = {
            updateBuildConfiguration = "interactive",
            runtimes = runtimes,
          },
          edit = {
            validateAllOpenBuffersOnChanges = false,
          },
        },
      })
      return opts
    end,
  },
}
