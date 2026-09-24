return {
  {
    "Zeioth/compiler.nvim",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo", "CompilerStop" },
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
      --- Project root for a file: pom dir -> git root -> file dir -> cwd.
      ---@param bufname string
      ---@return string
      local function project_root_for(bufname)
        local start = bufname ~= "" and vim.fs.dirname(bufname) or vim.fn.getcwd()
        local pom = vim.fs.find("pom.xml", { path = start, upward = true })[1]
        if pom then
          return vim.fn.fnamemodify(pom, ":h")
        end
        local git = vim.fs.find(".git", { path = start, upward = true })[1]
        if git then
          return vim.fs.dirname(git)
        end
        if bufname ~= "" then
          return vim.fs.dirname(bufname)
        end
        return vim.fn.getcwd()
      end
      --- Shell-escape a path for `sh -c` task strings (handles spaces AND quotes).
      ---@param s string
      ---@return string
      local function sh(s)
        return vim.fn.shellescape(s)
      end
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
            local output_dir = project_root_for(bufname) .. "/bin/"
            local output = output_dir .. vim.fn.fnamemodify(bufname, ":t:r")
            local cmd
            if selected_option == "option1" then
              -- Build and run (show program output)
              cmd = "mkdir -p "
                .. sh(output_dir)
                .. " && g++ "
                .. sh(bufname)
                .. " -o "
                .. sh(output)
                .. " "
                .. arguments
                .. ' && echo "--- Program output ---" && '
                .. sh(output)
                .. ' && echo "" && echo "--- Done ---"'
            else
              -- option2 (Build) and option4 (Build solution -> also single-file)
              cmd = "mkdir -p "
                .. sh(output_dir)
                .. " && g++ "
                .. sh(bufname)
                .. " -o "
                .. sh(output)
                .. " "
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
            local output = project_root_for(bufname) .. "/bin/" .. vim.fn.fnamemodify(bufname, ":t:r")
            local cmd = 'echo "--- Program output ---" && ' .. sh(output) .. ' && echo "" && echo "--- Done ---"'
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
            local output_dir = project_root_for(bufname) .. "/bin/"
            local output = output_dir .. vim.fn.fnamemodify(bufname, ":t:r")
            local cmd
            if selected_option == "option1" then
              cmd = "mkdir -p "
                .. sh(output_dir)
                .. " && gcc "
                .. sh(bufname)
                .. " -o "
                .. sh(output)
                .. " "
                .. c_args
                .. ' && echo "--- Program output ---" && '
                .. sh(output)
                .. ' && echo "" && echo "--- Done ---"'
            else
              cmd = "mkdir -p "
                .. sh(output_dir)
                .. " && gcc "
                .. sh(bufname)
                .. " -o "
                .. sh(output)
                .. " "
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
            local output = project_root_for(bufname) .. "/bin/" .. vim.fn.fnamemodify(bufname, ":t:r")
            local cmd = 'echo "--- Program output ---" && ' .. sh(output) .. ' && echo "" && echo "--- Done ---"'
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

      -- Resolve the fully-qualified class name of the current buffer
      -- (package declaration + file name). Used for Maven exec:java.
      local function java_fqcn(bufname)
        local pkg = nil
        for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 40, false)) do
          pkg = line:match("^%s*package%s+([%w%.]+)%s*;")
          if pkg then
            break
          end
        end
        local stem = vim.fn.fnamemodify(bufname, ":t:r")
        return (pkg and pkg .. "." or "") .. stem
      end

      -- F5: universal single-file build & run for every language (no picker)
      local function f5_start(cmd, name)
        local overseer = require("overseer")
        -- Dynamic: stop any previous run so output always belongs to current buffer,
        -- never a stale task from another project (e.g. albaraka vs Al Baraka).
        for _, t in ipairs(overseer.list_tasks({})) do
          local s = t.status
          if s == "RUNNING" or s == "PENDING" then
            pcall(function()
              t:stop()
            end)
          end
        end
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
        local cwd = project_root_for(bufname)
        local output_dir = cwd .. "/bin/"
        local output = output_dir .. stem

        if ft == "c" then
          local cmd = "mkdir -p "
            .. sh(output_dir)
            .. " && gcc "
            .. sh(bufname)
            .. " -o "
            .. sh(output)
            .. ' -Wall -g && echo "--- Program output ---" && '
            .. sh(output)
            .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Build & run (c) → "' .. bufname .. '"')
        elseif ft == "cpp" then
          local cmd = "mkdir -p "
            .. sh(output_dir)
            .. " && g++ "
            .. sh(bufname)
            .. " -o "
            .. sh(output)
            .. " "
            .. arguments
            .. ' && echo "--- Program output ---" && '
            .. sh(output)
            .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Build & run (cpp) → "' .. bufname .. '"')
        elseif ft == "java" then
          -- Decide how to compile based on project structure:
          --   1. Maven project (pom.xml exists)      → mvn compile exec:java
          --   2. Simple project (src/ exists, no pom)  → javac src/**/*.java → bin/, run FQCN
          --   3. Single file (no src/, no pom)         → javac current file → bin/, run it
          local fdir = vim.fs.dirname(bufname)
          local pom = vim.fs.find("pom.xml", { path = fdir, upward = true })[1]
          local has_src = vim.fn.isdirectory(cwd .. "/src") == 1

          if pom then
            -- ── Maven ──────────────────────────────────────────────────────
            local root = vim.fn.fnamemodify(pom, ":h")
            local wrapper = root .. "/mvnw"
            local mvn = vim.fn.executable(wrapper) == 1 and wrapper or "mvn"
            local fqcn = java_fqcn(bufname)
            local cmd = "cd "
              .. sh(root)
              .. " && "
              .. sh(mvn)
              .. ' -q -DskipTests compile org.codehaus.mojo:exec-maven-plugin:3.1.0:java -Dexec.mainClass="'
              .. fqcn
              .. '" && echo "" && echo "--- Done ---"'
            f5_start(cmd, '- Build & run (maven) → "' .. vim.fn.fnamemodify(root, ":t") .. " » " .. fqcn .. '"')

          elseif has_src then
            -- ── Simple multi-file project (src/models, src/services, …) ────
            local out = cwd .. "/bin"
            local fqcn = java_fqcn(bufname)
            local cmd = "cd "
              .. sh(cwd)
              .. " && mkdir -p "
              .. sh(out)
              .. ' && find src -name "*.java" -print0 | xargs -0 javac -d '
              .. sh(out)
              .. ' -Xlint:all && echo "--- Program output ---" && java -cp '
              .. sh(out)
              .. ' "'
              .. fqcn
              .. '" && echo "" && echo "--- Done ---"'
            f5_start(cmd, '- Build & run (src/) → "' .. vim.fn.fnamemodify(cwd, ":t") .. " » " .. fqcn .. '"')

          else
            -- ── Single file ────────────────────────────────────────────────
            local cmd = "mkdir -p "
              .. sh(output_dir)
              .. " && javac -d "
              .. sh(output_dir)
              .. " -Xlint:all "
              .. sh(bufname)
              .. ' && echo "--- Program output ---" && java -cp '
              .. sh(output_dir)
              .. ' "'
              .. stem
              .. '" && echo "" && echo "--- Done ---"'
            f5_start(cmd, '- Build & run (java) → "' .. bufname .. '"')
          end
        elseif ft == "python" then
          -- prefer python3 (python may be py2 on some systems)
          local py = vim.fn.executable("python3") == 1 and "python3" or "python"
          local cmd = 'echo "--- Program output ---" && ' .. py .. " " .. sh(bufname) .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (python) → "' .. bufname .. '"')
        elseif ft == "lua" then
          local cmd = 'echo "--- Program output ---" && lua ' .. sh(bufname) .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (lua) → "' .. bufname .. '"')
        elseif ft == "sh" or ft == "bash" then
          local cmd = 'echo "--- Program output ---" && bash ' .. sh(bufname) .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (sh) → "' .. bufname .. '"')
        elseif ft == "php" then
          local cmd = 'echo "--- Program output ---" && php ' .. sh(bufname) .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (php) → "' .. bufname .. '"')
        elseif ft == "javascript" or ft == "javascriptreact" then
          if ext == "jsx" then
            local cmd = 'echo "--- Program output ---" && npx --yes tsx '
              .. sh(bufname)
              .. ' && echo "" && echo "--- Done ---"'
            f5_start(cmd, '- Run (tsx) → "' .. bufname .. '"')
          else
            local cmd = 'echo "--- Program output ---" && node ' .. sh(bufname) .. ' && echo "" && echo "--- Done ---"'
            f5_start(cmd, '- Run (node) → "' .. bufname .. '"')
          end
        elseif ft == "typescript" or ft == "typescriptreact" then
          local cmd = 'echo "--- Program output ---" && npx --yes tsx '
            .. sh(bufname)
            .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (tsx) → "' .. bufname .. '"')
        elseif ft == "rust" then
          local cmd = "mkdir -p "
            .. sh(output_dir)
            .. " && rustc "
            .. sh(bufname)
            .. " -o "
            .. sh(output)
            .. ' && echo "--- Program output ---" && '
            .. sh(output)
            .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Build & run (rust) → "' .. bufname .. '"')
        elseif ft == "go" then
          local cmd = 'echo "--- Program output ---" && go run ' .. sh(bufname) .. ' && echo "" && echo "--- Done ---"'
          f5_start(cmd, '- Run (go) → "' .. bufname .. '"')
        elseif ft == "ruby" then
          local cmd = 'echo "--- Program output ---" && ruby ' .. sh(bufname) .. ' && echo "" && echo "--- Done ---"'
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
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo", "CompilerStop" },
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
