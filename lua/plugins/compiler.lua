return {
  {
    "Zeioth/compiler.nvim",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
    event = "VeryLazy",
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
      local arguments = "-Wall -g -std=c++17 -Wno-unused-parameter"
      local orig_action = cpp.action
      cpp.action = function(selected_option)
        if selected_option == "option1" or selected_option == "option2" or selected_option == "option4" then
          -- Build (and run) only current buffer file, not all *.cpp
          -- Handles "Cpp learning" spaces via quoting, uses cwd/bin/<name> per user choice
          local overseer = require("overseer")
          local bufname = vim.api.nvim_buf_get_name(0)
          if bufname == "" then
            vim.notify("Save file first (no buffer name)", vim.log.levels.ERROR)
            return
          end
          -- auto-save before compile if modified
          if vim.bo.modified then
            vim.cmd("silent write")
          end
          local output_dir = vim.fn.getcwd() .. "/bin/"
          local output = output_dir .. vim.fn.fnamemodify(bufname, ":t:r")
          local cmd
          if selected_option == "option1" then
            -- Build and run (show program output)
            cmd = 'mkdir -p "'
              .. output_dir
              .. '" && g++ "'
              .. bufname
              .. '" -o "'
              .. output
              .. '" '
              .. arguments
              .. ' && echo "--- Program output ---" && "'
              .. output
              .. '" && echo "" && echo "--- Done ---"'
          else
            -- option2 (Build) and option4 (Build solution -> also single-file)
            cmd = 'mkdir -p "' .. output_dir .. '" && g++ "' .. bufname .. '" -o "' .. output .. '" ' .. arguments .. ' && echo "Build OK: ' .. output .. '"'
          end
          local task = overseer.new_task({
            cmd = cmd,
            name = '- Build program → "' .. bufname .. '"',
            components = { "default_extended", "open_output" },
          })
          task:start()
          vim.defer_fn(function() pcall(function() require("overseer").open({ enter = false }) end) end, 100)
        elseif selected_option == "option3" then
          -- Run: run current file's binary (show output)
          local overseer = require("overseer")
          local bufname = vim.api.nvim_buf_get_name(0)
          if bufname == "" then
            vim.notify("Save file first (no buffer name)", vim.log.levels.ERROR)
            return
          end
          local output = vim.fn.getcwd() .. "/bin/" .. vim.fn.fnamemodify(bufname, ":t:r")
          local cmd = 'echo "--- Program output ---" && "' .. output .. '" && echo "" && echo "--- Done ---"'
          local task = overseer.new_task({
            cmd = cmd,
            name = '- Run program → "' .. output .. '"',
            components = { "default_extended", "open_output" },
          })
          task:start()
          vim.defer_fn(function() pcall(function() require("overseer").open({ enter = false }) end) end, 100)
        else
          return orig_action(selected_option)
        end
      end

      -- F5: instant single-file build & run (no picker) - any file even with multiple mains elsewhere
      vim.keymap.set("n", "<F5>", function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname == "" then
          vim.notify("Save file first (no buffer name)", vim.log.levels.ERROR)
          return
        end
        if vim.bo.modified then
          vim.cmd("silent write")
        end
        local overseer = require("overseer")
        local output_dir = vim.fn.getcwd() .. "/bin/"
        local output = output_dir .. vim.fn.fnamemodify(bufname, ":t:r")
        local cmd = 'mkdir -p "'
          .. output_dir
          .. '" && g++ "'
          .. bufname
          .. '" -o "'
          .. output
          .. '" '
          .. arguments
          .. ' && echo "--- Program output ---" && "'
          .. output
          .. '" && echo "" && echo "--- Done ---"'
        local task = overseer.new_task({
          cmd = cmd,
          name = '- Build & run → "' .. bufname .. '"',
          components = { "default_extended", "open_output" },
        })
        task:start()
        vim.defer_fn(function() pcall(function() require("overseer").open({ enter = false }) end) end, 100)
      end, { desc = "C++: Build & run current file (F5, single-file)" })
    end,
    keys = {
      { "<F5>", desc = "C++: Build & run current file (single-file)" },
      { "<F6>", "<cmd>CompilerOpen<cr>", desc = "Open compiler" },
      { "<S-F6>", "<cmd>CompilerStop<cr><cmd>CompilerRedo<cr>", desc = "Redo last compiler task" },
      { "<S-F7>", "<cmd>CompilerToggleResults<cr>", desc = "Toggle compiler results" },
    },
  },
  {
    "stevearc/overseer.nvim",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
    opts = {
      task_list = { direction = "bottom", min_height = 25, max_height = 25, default_detail = 2 },
    },
  },
}
