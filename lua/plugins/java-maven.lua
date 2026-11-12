-- Maven build integration using overseer (the same task runner F5 builds use).
-- Commands:
--   :MavenClean / :MavenCompile / :MavenTest / :MavenPackage / :MavenInstall
--   :MavenSpringBootRun / :MavenRun / :Maven <any args...>
-- Keymaps (<leader>jm prefix):
--   jmc compile | jmt test | jmb package | jmi install | jmj run | jms spring-boot:run
return {
  {
    "stevearc/overseer.nvim",
    -- Commands are registered in init below and load Overseer through require.
    -- Lazy cmd stubs would delete those real commands when Overseer loads.
    -- stylua: ignore
    keys = {
      { "<leader>jmc", "<cmd>MavenCompile<cr>", desc = "Maven: compile" },
      { "<leader>jmt", "<cmd>MavenTest<cr>", desc = "Maven: test" },
      { "<leader>jmb", "<cmd>MavenPackage<cr>", desc = "Maven: package (skip tests)" },
      { "<leader>jmi", "<cmd>MavenInstall<cr>", desc = "Maven: install (skip tests)" },
      { "<leader>jmj", "<cmd>MavenRun<cr>", desc = "Maven: run current class" },
      { "<leader>jms", "<cmd>MavenSpringBootRun<cr>", desc = "Maven: spring-boot:run" },
    },
    -- init runs at startup even though overseer itself is lazy; handlers only
    -- require overseer when a command is actually invoked.
    init = function()
      --- Project root: nearest pom.xml upward from current file, else cwd.
      ---@return string
      local function project_root()
        local buf = vim.api.nvim_buf_get_name(0)
        local start = buf ~= "" and vim.fs.dirname(buf) or vim.fn.getcwd()
        local pom = vim.fs.find("pom.xml", { path = start, upward = true })[1]
        if pom then
          return vim.fn.fnamemodify(pom, ":h")
        end
        return vim.fn.getcwd()
      end
      local function run_mvn(args, name)
        local root = project_root()
        local prefix = vim.fs.normalize(root):gsub("/$", "") .. "/"
        -- Save project files only; unnamed notes and unrelated buffers must
        -- neither block the build nor be written as a side effect.
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            local path = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
            local options = vim.bo[buf]
            if
              path:sub(1, #prefix) == prefix
              and options.buftype == ""
              and options.modified
              and options.modifiable
              and not options.readonly
            then
              local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
                vim.cmd("silent update")
              end)
              if not ok then
                vim.notify("Maven: cannot save " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
                return
              end
            end
          end
        end
        local overseer = require("overseer")
        local wrapper = root .. "/mvnw"
        local mvn = vim.fn.executable(wrapper) == 1 and wrapper or "mvn"
        local task = overseer.new_task({
          cmd = vim.fn.shellescape(mvn) .. " " .. args,
          name = name,
          cwd = root,
          components = { "default_extended" },
        })
        task:start()
        vim.defer_fn(function()
          pcall(function()
            require("overseer").open({ enter = false })
          end)
        end, 100)
      end

      --- Fully-qualified class name of the current buffer (package + file name).
      ---@return string
      local function buf_fqcn()
        local name = vim.api.nvim_buf_get_name(0)
        local class = vim.fn.fnamemodify(name, ":t:r")
        local pkg = nil
        for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 60, false)) do
          pkg = line:match("^%s*package%s+([%w_$.]+)%s*;")
          if pkg then
            break
          end
        end
        return (pkg and pkg .. "." or "") .. class
      end

      local exec_java = "compile org.codehaus.mojo:exec-maven-plugin:3.1.0:java"

      vim.api.nvim_create_user_command("MavenClean", function()
        run_mvn("clean", "Maven clean")
      end, { desc = "mvn clean" })

      vim.api.nvim_create_user_command("MavenCompile", function()
        -- Preserve target/ so Maven can reuse unchanged compiled classes.
        run_mvn("compile", "Maven compile")
      end, { desc = "mvn compile (incremental)" })

      vim.api.nvim_create_user_command("MavenTest", function()
        run_mvn("test", "Maven test")
      end, { desc = "mvn test" })

      vim.api.nvim_create_user_command("MavenPackage", function()
        run_mvn("-DskipTests package", "Maven package (skip tests)")
      end, { desc = "mvn -DskipTests package" })

      vim.api.nvim_create_user_command("MavenInstall", function()
        run_mvn("-DskipTests install", "Maven install (skip tests)")
      end, { desc = "mvn -DskipTests install" })

      vim.api.nvim_create_user_command("MavenSpringBootRun", function()
        run_mvn("-Dmaven.test.skip=true spring-boot:run", "Maven spring-boot:run")
      end, { desc = "mvn spring-boot:run (skip test compilation)" })

      vim.api.nvim_create_user_command("MavenRun", function()
        local fqcn = buf_fqcn()
        if fqcn == "" or fqcn:match("%.$") then
          fqcn = vim.fn.input("Main class: ", fqcn)
        end
        if vim.trim(fqcn) == "" then
          return
        end
        run_mvn(
          "-q -DskipTests " .. exec_java .. " " .. vim.fn.shellescape("-Dexec.mainClass=" .. fqcn),
          "Maven run: " .. fqcn
        )
      end, { desc = "mvn compile + exec:java <main class>" })

      vim.api.nvim_create_user_command("Maven", function(opts)
        local args = vim.trim(opts.args)
        run_mvn(args, "Maven " .. (args ~= "" and args or "(no args)"))
      end, { nargs = "*", desc = "Run arbitrary maven arguments" })
    end,
  },
}
