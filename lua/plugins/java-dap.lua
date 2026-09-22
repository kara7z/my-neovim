-- Java debugging (DAP).
-- The LazyVim Java extra (lazyvim.plugins.extras.lang.java) already:
--   * loads java-debug-adapter + java-test bundles into jdtls
--   * calls require("jdtls").setup_dap()  -> dap.adapters["java"] (via jdtls DAP port)
--   * adds <leader>co (organize imports) + jdtls test keymaps (<leader>tt/<leader>tr/<leader>tT)
-- ...but ONLY when nvim-dap is present. This file enables that path.
return {
  -- Core debugger client
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      -- make sure the java debug/test bundles are installed even if jdtls
      -- attaches before the java extra's own mason dependency kicks in
      {
        "mason-org/mason.nvim",
        opts = { ensure_installed = { "java-debug-adapter", "java-test" } },
      },
    },
    -- stylua: ignore
    keys = {
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<S-F11>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Debug: Run/Continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Debug: Run to Cursor" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Debug: Run Last" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Debug: Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Debug: Toggle REPL" },
      { "<leader>ds", function() require("dap").session() end, desc = "Debug: Session" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Debug: Terminate" },
    },
    config = function()
      local dap = require("dap")

      -- breakpoint / stopped-line visual feedback
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
      for name, sign in pairs(LazyVim.config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end

      -- The java adapter/configurations come from jdtls.setup_dap (LazyVim java
      -- extra). Keep a remote-attach fallback for when jdtls hasn't started yet.
      if not dap.adapters["java"] then
        dap.adapters["java"] = function(callback, config)
          callback({ type = "server", host = config.hostName or "127.0.0.1", port = config.port or 5005 })
        end
      end
      if not dap.configurations.java then
        dap.configurations.java = {
          {
            type = "java",
            request = "attach",
            name = "Debug (Attach) - Remote",
            hostName = "127.0.0.1",
            port = 5005,
          },
        }
      end
    end,
  },

  -- Fancy debugger UI (panel with variables / watches / stack / breakpoints)
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Debug: Toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Debug: Eval", mode = { "n", "x" } },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },

  -- Inline variable values while stopped at a breakpoint
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
}