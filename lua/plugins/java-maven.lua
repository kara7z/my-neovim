-- Maven build integration using overseer (the same task runner F5 builds use).
-- Commands:
--   :MavenClean / :MavenCompile / :MavenTest / :MavenPackage / :MavenInstall
--   :MavenSpringBootRun / :MavenRun / :Maven <any args...>
-- Keymaps (<leader>jm prefix):
--   jmc clean compile | jmt test | jmb package | jmi install | jmj run | jms spring-boot:run
return {
  {
    "stevearc/overseer.nvim",
    cmd = {
      "MavenClean",
      "MavenCompile",
      "MavenTest",
      "MavenPackage",
      "MavenInstall",
      "MavenSpringBootRun",
      "MavenRun",
      "Maven",
    },
    -- stylua: ignore
    keys = {
      { "<leader>jmc", "<cmd>MavenCompile<cr>", desc = "Maven: clean compile" },
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
        local overseer = require("overseer")
        local root = project_root()
        local wrapper = root .. "/mvnw"
        local mvn = vim.fn.executable(wrapper) == 1 and wrapper or "mvn"
        local task = overseer.new_task({
          cmd = mvn .. " " .. args,
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
          pkg = line:match("^%s*package%s+([%w%.]+)%s*;")
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
        run_mvn("-q clean compile", "Maven clean compile")
      end, { desc = "mvn -q clean compile" })

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
        run_mvn("spring-boot:run", "Maven spring-boot:run")
      end, { desc = "mvn spring-boot:run" })

      vim.api.nvim_create_user_command("MavenRun", function()
        local fqcn = buf_fqcn()
        if fqcn == "" or fqcn:match("%.$") then
          fqcn = vim.fn.input("Main class: ", fqcn)
        end
        run_mvn("-q -DskipTests " .. exec_java .. " -Dexec.mainClass=" .. fqcn, "Maven run: " .. fqcn)
      end, { desc = "mvn compile + exec:java <main class>" })

      vim.api.nvim_create_user_command("Maven", function(opts)
        local args = vim.trim(opts.args)
        run_mvn(args, "Maven " .. (args ~= "" and args or "(no args)"))
      end, { nargs = "*", desc = "Run arbitrary maven arguments" })
    end,
  },
}