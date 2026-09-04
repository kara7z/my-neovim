return {
  {
    "Zeioth/compiler.nvim",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
    dependencies = { "stevearc/overseer.nvim", "nvim-telescope/telescope.nvim" },
    opts = {},
    config = function(_, opts)
      require("compiler").setup(opts)
      -- Fix C++: compile only current file (not all *.cpp) to avoid multiple definition of main
      -- Default cpp.lua compiles all *.cpp in cwd to bin/program, which fails when each .cpp has its own main
      local ok, cpp = pcall(require, "compiler.languages.cpp")
      if not ok or not cpp then
        vim.notify("compiler.nvim: cpp language not found, skipping override", vim.log.levels.WARN)
        return
      end
      local orig_action = cpp.action
      cpp.action = function(selected_option)
        if selected_option == "option1" or selected_option == "option2" then
          -- Build (and run) only current buffer file, not all *.cpp
          local overseer = require("overseer")
          local bufname = vim.api.nvim_buf_get_name(0)
          if bufname == "" then
            bufname = vim.fn.getcwd() .. "/main.cpp"
          end
          local output_dir = vim.fn.getcwd() .. "/bin/"
          local output = output_dir .. vim.fn.fnamemodify(bufname, ":t:r")
          local cmd
          if selected_option == "option1" then
            cmd = 'mkdir -p "' .. output_dir .. '" && g++ "' .. bufname .. '" -o "' .. output .. '" -Wall -g && "' .. output .. '"'
          else
            cmd = 'mkdir -p "' .. output_dir .. '" && g++ "' .. bufname .. '" -o "' .. output .. '" -Wall -g'
          end
          local task = overseer.new_task({
            name = "- C++ compiler",
            strategy = { "orchestrator", tasks = { { name = "- Build program → \"" .. bufname .. "\"", cmd = cmd, components = { "default" } } } },
          })
          task:start()
        elseif selected_option == "option3" then
          -- Run: run current file's binary - just result
          local overseer = require("overseer")
          local bufname = vim.api.nvim_buf_get_name(0)
          if bufname == "" then
            bufname = vim.fn.getcwd() .. "/main.cpp"
          end
          local output = vim.fn.getcwd() .. "/bin/" .. vim.fn.fnamemodify(bufname, ":t:r")
          local task = overseer.new_task({
            name = "- C++ compiler",
            strategy = { "orchestrator", tasks = { { name = "- Run program → \"" .. output .. "\"", cmd = '"' .. output .. '"', components = { "default" } } } },
          })
          task:start()
        else
          return orig_action(selected_option)
        end
      end
    end,
    keys = {
      { "<F6>", "<cmd>CompilerOpen<cr>", desc = "Open compiler" },
      { "<S-F6>", "<cmd>CompilerStop<cr><cmd>CompilerRedo<cr>", desc = "Redo last compiler task" },
      { "<S-F7>", "<cmd>CompilerToggleResults<cr>", desc = "Toggle compiler results" },
    },
  },
  {
    "stevearc/overseer.nvim",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
    opts = {
      task_list = { direction = "bottom", min_height = 25, max_height = 25, default_detail = 1 },
    },
  },
}
