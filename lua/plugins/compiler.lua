return {
  {
    "Zeioth/compiler.nvim",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
    event = "VeryLazy",
    dependencies = { "stevearc/overseer.nvim", "nvim-telescope/telescope.nvim" },
    opts = {},
    config = function(_, opts)
      require("compiler").setup(opts)
      -- Silence SUCCESS notifications: only notify on FAILURE.
      -- This hides "SUCCESS - Build & run (java) → ..." popups.
      local silent_components = {
        "on_exit_set_status",
        { "on_complete_notify", statuses = { "FAILURE" } },
        "on_complete_dispose",
        "open_output",
      }
      -- Fix C++: compile only current file (not all *.cpp) to avoid multiple definition of main
      -- Default cpp.lua compiles all *.cpp in cwd to bin/program, which fails when each .cpp has its own main
      local arguments = "-Wall -g -std=c++17 -Wno-unused-parameter"
      local ok, cpp = pcall(require, "compiler.languages.cpp")
      if not ok or not cpp then
        vim.notify("compiler.nvim: cpp language not found, skipping cpp override", vim.log.levels.WARN)
      else
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
              cmd = 'mkdir -p "'
                .. output_dir
                .. '" && g++ "'
                .. bufname
                .. '" -o "'
                .. output
                .. '" '
                .. arguments
                .. ' && echo "Build OK: '
                .. output
                .. '"'
            end
            local task = overseer.new_task({
              cmd = cmd,
              name = '- Build program → "' .. bufname .. '"',
              components = silent_components,
            })
            task:start()
            vim.defer_fn(function()
              pcall(function()
                require("overseer").open({ enter = false })
              end)
            end, 100)
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
              components = silent_components,
            })
            task:start()
            vim.defer_fn(function()
              pcall(function()
                require("overseer").open({ enter = false })
              end)
            end, 100)
          else
            return orig_action(selected_option)
          end
        end
      end

      -- Fix C: same single-file issue as C++ (default compiles all *.c)
      local ok_c, c_lang = pcall(require, "compiler.languages.c")
      if ok_c and c_lang then
        local c_args = "-Wall -g"
        local orig_c_action = c_lang.action
        c_lang.action = function(selected_option)
          if selected_option == "option1" or selected_option == "option2" or selected_option == "option4" then
            local overseer = require("overseer")
            local bufname = vim.api.nvim_buf_get_name(0)
            if bufname == "" then
              vim.notify("Save file first (no buffer name)", vim.log.levels.ERROR)
              return
            end
            if vim.bo.modified then
              vim.cmd("silent write")
            end
            local output_dir = vim.fn.getcwd() .. "/bin/"
            local output = output_dir .. vim.fn.fnamemodify(bufname, ":t:r")
            local cmd
            if selected_option == "option1" then
              cmd = 'mkdir -p "'
                .. output_dir
                .. '" && gcc "'
                .. bufname
                .. '" -o "'
                .. output
                .. '" '
                .. c_args
                .. ' && echo "--- Program output ---" && "'
                .. output
                .. '" && echo "" && echo "--- Done ---"'
            else
              cmd = 'mkdir -p "'
                .. output_dir
                .. '" && gcc "'
                .. bufname
                .. '" -o "'
                .. output
                .. '" '
                .. c_args
                .. ' && echo "Build OK: '
                .. output
                .. '"'
            end
            local task = overseer.new_task({
              cmd = cmd,
              name = '- Build program → "' .. bufname .. '"',
              components = silent_components,
            })
            task:start()
            vim.defer_fn(function()
              pcall(function()
                require("overseer").open({ enter = false })
              end)
            end, 100)
          elseif selected_option == "option3" then
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
              components = silent_components,
            })
            task:start()
            vim.defer_fn(function()
              pcall(function()
                require("overseer").open({ enter = false })
              end)
            end, 100)
          else
            return orig_c_action(selected_option)
          end
        end
      end

      -- F5: universal single-file build & run for every language (no picker)
      local function f5_start(cmd, name)
        local overseer = require("overseer")
        local task = overseer.new_task({
          cmd = cmd,
          name = name,
          components = silent_components,
        })
        task:start()
        vim.defer_fn(function()
          pcall(function()
            require("overseer").open({ enter = false })
          end)
        end, 100)
      end
      vim.keymap.set("n", "<F5>", function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname == "" then
          vim.notify("Save file first (no buffer name)", vim.log.levels.ERROR)
          return
        end
        if vim.bo.modified then
          vim.cmd("silent write")
        end
        local ft = vim.bo.filetype
        local ext = vim.fn.fnamemodify(bufname, ":e"):lower()
        local stem = vim.fn.fnamemodify(bufname, ":t:r")
        local cwd = vim.fn.getcwd()
        local output_dir = cwd .. "/bin/"
        local output = output_dir .. stem

        if ft == "c" then
          local cmd = 'mkdir -p "'
            .. output_dir
            .. '" && gcc "'
            .. bufname
            .. '" -o "'
            .. output
            .. '" -Wall -g && echo "--- Program output ---" && "'
            .. output
            .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Build & run (c) → "' .. bufname .. '"')
        elseif ft == "cpp" then
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
          f5_start(cmd, '- Build & run (cpp) → "' .. bufname .. '"')
        elseif ft == "java" then
          local cmd = 'mkdir -p "'
            .. output_dir
            .. '" && javac -d "'
            .. output_dir
            .. '" -Xlint:all "'
            .. bufname
            .. '" && echo "--- Program output ---" && java -cp "'
            .. output_dir
            .. '" "'
            .. stem
            .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Build & run (java) → "' .. bufname .. '"')
        elseif ft == "python" then
          local py = vim.fn.executable("python") == 1 and "python" or "python3"
          local cmd = 'echo "--- Program output ---" && '
            .. py
            .. ' "'
            .. bufname
            .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (python) → "' .. bufname .. '"')
        elseif ft == "lua" then
          local cmd = 'echo "--- Program output ---" && lua "' .. bufname .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (lua) → "' .. bufname .. '"')
        elseif ft == "sh" or ft == "bash" then
          local cmd = 'echo "--- Program output ---" && bash "' .. bufname .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (sh) → "' .. bufname .. '"')
        elseif ft == "php" then
          local cmd = 'echo "--- Program output ---" && php "' .. bufname .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (php) → "' .. bufname .. '"')
        elseif ft == "javascript" or ft == "javascriptreact" then
          if ext == "jsx" then
            local cmd = 'echo "--- Program output ---" && npx --yes tsx "'
              .. bufname
              .. '" && echo "" && echo "--- Done ---"'
            f5_start(cmd, '- Run (tsx) → "' .. bufname .. '"')
          else
            local cmd = 'echo "--- Program output ---" && node "' .. bufname .. '" && echo "" && echo "--- Done ---"'
            f5_start(cmd, '- Run (node) → "' .. bufname .. '"')
          end
        elseif ft == "typescript" or ft == "typescriptreact" then
          local cmd = 'echo "--- Program output ---" && npx --yes tsx "'
            .. bufname
            .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (tsx) → "' .. bufname .. '"')
        elseif ft == "rust" then
          local cmd = 'mkdir -p "'
            .. output_dir
            .. '" && rustc "'
            .. bufname
            .. '" -o "'
            .. output
            .. '" && echo "--- Program output ---" && "'
            .. output
            .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Build & run (rust) → "' .. bufname .. '"')
        elseif ft == "go" then
          local cmd = 'echo "--- Program output ---" && go run "' .. bufname .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (go) → "' .. bufname .. '"')
        elseif ft == "ruby" then
          local cmd = 'echo "--- Program output ---" && ruby "' .. bufname .. '" && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (ruby) → "' .. bufname .. '"')
        else
          -- Fallback: use compiler.nvim project runner if a backend exists, else notify
          local lang_ft = ft
          if ft == "bash" then
            lang_ft = "sh"
          end
          local ok_lang, lang = pcall(require, "compiler.languages." .. lang_ft)
          if ok_lang and lang and lang.action then
            return lang.action("option1")
          end
          vim.notify("F5: no single-file runner for filetype '" .. ft .. "'", vim.log.levels.WARN)
        end
      end, { desc = "Build & run current file (F5, single-file)" })
    end,
    keys = {
      { "<F5>", desc = "Build & run current file (single-file)" },
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
      -- Silence SUCCESS popups globally (e.g. compiler.nvim java tasks):
      -- only notify on FAILURE. This hides "SUCCESS - Build & run ...".
      component_aliases = {
        default = {
          "on_exit_set_status",
          { "on_complete_notify", statuses = { "FAILURE" } },
          { "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } },
        },
      },
    },
    config = function(_, opts)
      require("overseer").setup(opts)
      -- Re-assert FAILURE-only notify after setup (survives load order with
      -- compiler.nvim which registers "default_extended" without override).
      require("overseer").register_alias("default", {
        "on_exit_set_status",
        { "on_complete_notify", statuses = { "FAILURE" } },
        { "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } },
      }, true)
      require("overseer").register_alias("default_extended", {
        "on_complete_dispose",
        "default",
        "open_output",
      }, true)
      -- Hide orchestrator parents ("- Java compiler", etc.) so Build & Run shows
      -- just one ┃ RUNNING block (child) instead of parent + child duplication.
      -- Children keep parent_id, so they still render with ┃ indent + duration + output.
      -- Only affects display (sidebar/taskview); broadcast/dispose still see all tasks.
      local function is_orchestrator_parent(task)
        if not task or task.parent_id ~= nil then
          return false
        end
        local defn = task.strategy_defn
        if type(defn) == "table" and defn[1] == "orchestrator" then
          return true
        end
        if task.strategy and task.strategy.name == "orchestrator" then
          return true
        end
        return false
      end
      local function hide_parent_filter(task)
        return not is_orchestrator_parent(task)
      end

      -- Sidebar task list: inject filter (Sidebar.new hardcodes opts, so wrap getter)
      local ok_sb, sidebar = pcall(require, "overseer.task_list.sidebar")
      if ok_sb and sidebar and sidebar.get_or_create then
        local orig_get_or_create = sidebar.get_or_create
        sidebar.get_or_create = function()
          local sb, created = orig_get_or_create()
          if sb then
            sb.list_task_opts = sb.list_task_opts or { include_ephemeral = true }
            sb.list_task_opts.include_ephemeral = true
            sb.list_task_opts.filter = hide_parent_filter
          end
          return sb, created
        end
        local existing = sidebar.get and sidebar.get()
        if existing then
          existing.list_task_opts = existing.list_task_opts or { include_ephemeral = true }
          existing.list_task_opts.include_ephemeral = true
          existing.list_task_opts.filter = hide_parent_filter
        end
      end

      -- Task output pane (right side when direction=bottom): show child output,
      -- not the parent orchestrator table ("RUNNING - Build & run...").
      local ok_tv, TaskView = pcall(require, "overseer.task_view")
      if ok_tv and TaskView and TaskView.new then
        local orig_new = TaskView.new
        TaskView.new = function(winid, tv_opts)
          tv_opts = tv_opts or {}
          tv_opts.list_task_opts = tv_opts.list_task_opts or { include_ephemeral = true }
          tv_opts.list_task_opts.include_ephemeral = true
          local user_filter = tv_opts.list_task_opts.filter
          tv_opts.list_task_opts.filter = function(task)
            if is_orchestrator_parent(task) then
              return false
            end
            if user_filter then
              return user_filter(task)
            end
            return true
          end
          local user_select = tv_opts.select
          tv_opts.select = function(view, tasks, task_under_cursor)
            -- Cursor on hidden parent (or no cursor): pick first visible child
            if task_under_cursor and is_orchestrator_parent(task_under_cursor) then
              task_under_cursor = nil
            end
            if user_select then
              local chosen = user_select(view, tasks, task_under_cursor)
              if chosen and not is_orchestrator_parent(chosen) then
                return chosen
              end
              return tasks[1]
            end
            return task_under_cursor or tasks[1]
          end
          return orig_new(winid, tv_opts)
        end
      end
    end,
  },
}
