-- Java project scaffolding inside Neovim.
--
-- Simple mode (terminal programs — no Maven):
--   :JavaProject myproject               -> src/models, src/services, src/DAO, src/enums, Main.java, bin/
--   :JavaClass User                      -> creates src/User.java
--   :JavaClass User models               -> creates src/models/User.java
--   :JavaClass User services             -> creates src/services/User.java
--   :JavaClass UserDAO DAO               -> creates src/DAO/UserDAO.java
--   :JavaClass OrderStatus enums         -> creates src/enums/OrderStatus.java (real enum)
--
-- Maven mode (has a package name with dots):
--   :JavaProject com.example myapp       -> full Maven project (pom.xml + src tree + Main)
--   :JavaProject com.example/myapp       -> same, slash-separated
--   :JavaClass com.example.UserService   -> src/main/java/com/example/UserService.java
--   :JavaClass --main UserService        -> adds main() method
return {
  {
    "nvim-lua/plenary.nvim",
    -- Use init (not config): stack.lua also specs plenary with config, and the
    -- later spec's config wins during merge, killing our command definitions.
    -- init runs at startup for ALL plugins regardless of lazy state.
    init = function()
      local M = {}

      ---@return string|nil
      function M.buf_package()
        for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 60, false)) do
          local p = line:match("^%s*package%s+([%w%.]+)%s*;")
          if p then
            return p
          end
        end
        return nil
      end

      ---@param name string
      ---@return boolean
      local function has_dots(name)
        return name:find("%.") ~= nil
      end

      ---@param name string
      ---@return boolean
      local function valid_ident(name)
        return name:match("^[%a_][%w_]*$") ~= nil
      end

      local function write(path, content)
        local f = assert(io.open(path, "w"))
        f:write(content)
        f:close()
      end

      local GITIGNORE = [[bin/
*.class
.DS_Store
]]

      local function make_main(fqcn)
        return string.format([[public class Main {

    public static void main(String[] args) {
        System.out.println("Hello from %s!");
    }
}
]], fqcn)
      end

      local function make_class(pkg, class, with_main)
        local out = {}
        if pkg and pkg ~= "" then
          table.insert(out, "package " .. pkg .. ";")
          table.insert(out, "")
        end
        table.insert(out, "public class " .. class .. " {")
        if with_main then
          local fqcn = (pkg and pkg ~= "" and pkg .. "." or "") .. class
          table.insert(out, "")
          table.insert(out, "    public static void main(String[] args) {")
          table.insert(out, '        System.out.println("Hello from ' .. fqcn .. '!");')
          table.insert(out, "    }")
        end
        table.insert(out, "}")
        table.insert(out, "")
        return table.concat(out, "\n")
      end

      -- Public enums (package visibility bug: non-public enums can't be seen
      -- from other packages, e.g. src.models -> src.enums).
      local function make_enum(pkg, class)
        local out = {}
        if pkg and pkg ~= "" then
          table.insert(out, "package " .. pkg .. ";")
          table.insert(out, "")
        end
        table.insert(out, "public enum " .. class .. " {")
        table.insert(out, "}")
        table.insert(out, "")
        return table.concat(out, "\n")
      end

      -- ── Simple mode directories ─────────────────────────────────────────
      local SIMPLE_DIRS = { "models", "services", "DAO", "enums", "utils" }

      local function is_simple_project()
        -- true when src/ exists but no pom.xml (terminal project)
        return vim.fn.isdirectory(vim.fn.getcwd() .. "/src") == 1
          and vim.fn.filereadable(vim.fn.getcwd() .. "/pom.xml") ~= 1
      end

      -- ── :JavaProject ─────────────────────────────────────────────────────
      vim.api.nvim_create_user_command("JavaProject", function(opts)
        local args = opts.fargs
        if #args == 0 then
          vim.notify("Usage: :JavaProject <name> or :JavaProject <package> <dir>", vim.log.levels.ERROR)
          return
        end

        local name = args[1]
        local dir
        local pkg = nil

        if has_dots(name) then
          -- Maven mode: :JavaProject com.example myapp
          pkg = name
          dir = args[2] or "myapp"
        else
          -- Simple mode: :JavaProject myproject
          dir = name
        end

        if not dir:match("^[%w_.-]+$") then
          vim.notify("JavaProject: invalid project name '" .. dir .. "'", vim.log.levels.ERROR)
          return
        end

        local root = vim.fn.fnamemodify(dir .. "/", ":p")

        if vim.fn.isdirectory(root) == 1 then
          vim.notify("JavaProject: already exists: " .. root, vim.log.levels.ERROR)
          return
        end

        if pkg then
          -- ── Maven mode ───────────────────────────────────────────────────
          local java_dir = root .. "src/main/java/" .. pkg:gsub("%.", "/")
          local test_dir = root .. "src/test/java/" .. pkg:gsub("%.", "/")
          vim.fn.mkdir(java_dir, "p")
          vim.fn.mkdir(root .. "src/main/resources", "p")
          vim.fn.mkdir(test_dir, "p")
          vim.fn.mkdir(root .. "src/test/resources", "p")
          write(root .. ".gitignore", [[target/
*.class
.idea/
*.iml
.vscode/
.DS_Store
]])
          write(root .. "pom.xml", string.format([[<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>%s</groupId>
  <artifactId>%s</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

  <properties>
    <maven.compiler.release>17</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>5.10.2</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.2.5</version>
      </plugin>
    </plugins>
  </build>
</project>
]], pkg, dir))
          write(java_dir .. "/Main.java", make_main(pkg .. ".Main"))
          vim.notify(string.format("Created Maven project %s", root), vim.log.levels.INFO)
        else
          -- ── Simple mode ───────────────────────────────────────────────────
          for _, sub in ipairs(SIMPLE_DIRS) do
            vim.fn.mkdir(root .. "src/" .. sub, "p")
          end
          vim.fn.mkdir(root .. "bin", "p")
          write(root .. ".gitignore", GITIGNORE)
          write(root .. "src/Main.java", make_main("Main"))
          vim.notify(string.format("Created project %s", root), vim.log.levels.INFO)
        end
      end, { nargs = "+", desc = "Create a Java project" })

      -- ── :JavaClass <Name> [folder] [--main] ────────────────────────────────
      -- Simple mode (no dots):
      --   :JavaClass User                → src/User.java
      --   :JavaClass User models         → src/models/User.java
      --   :JavaClass User --main         → src/User.java with main()
      -- Maven mode (has dots):
      --   :JavaClass com.example.User    → src/main/java/com/example/User.java
      vim.api.nvim_create_user_command("JavaClass", function(opts)
        local with_main = false
        local args = {}
        for _, a in ipairs(opts.fargs) do
          if a == "--main" then
            with_main = true
          else
            table.insert(args, a)
          end
        end
        if #args == 0 then
          vim.notify("Usage: :JavaClass <Name> [folder] or :JavaClass com.example.Name", vim.log.levels.ERROR)
          return
        end

        local name = args[1]
        local folder = args[2] -- optional: subfolder inside src/
        local pkg, class

        if has_dots(name) then
          -- Maven mode: full qualified name
          local parts = vim.split(name, ".", { plain = true })
          class = table.remove(parts)
          pkg = table.concat(parts, ".")
          folder = nil -- ignored in Maven mode
        else
          -- Simple mode: just a class name, no package
          class = name
          pkg = ""
        end

        if not valid_ident(class) then
          vim.notify("JavaClass: invalid class name '" .. class .. "'", vim.log.levels.ERROR)
          return
        end

        -- ── Find the source root ─────────────────────────────────────────────
        local base = vim.fn.getcwd()
        local pom = vim.fs.find("pom.xml", { upward = true })[1]
        local simple = not pom and vim.fn.isdirectory(base .. "/src") == 1

        local target_dir
        if pom then
          -- Maven project: src/main/java/<pkg>/
          target_dir = vim.fn.fnamemodify(pom, ":h") .. "/src/main/java/" .. pkg:gsub("%.", "/")
        elseif simple and folder then
          -- Simple project with folder: src/<folder>/
          target_dir = base .. "/src/" .. folder
        elseif simple then
          -- Simple project, no folder: src/
          target_dir = base .. "/src"
        else
          target_dir = base
        end

        local file = vim.fn.fnamemodify(target_dir .. "/" .. class .. ".java", ":p")

        if vim.fn.filereadable(file) == 1 then
          vim.notify("JavaClass: already exists: " .. file, vim.log.levels.ERROR)
          return
        end

        vim.fn.mkdir(target_dir, "p")
        local content
        if has_dots(name) then
          -- Maven mode
          content = make_class(pkg, class, with_main)
        elseif folder == "enums" then
          -- Simple mode in the enums folder -> generate a real enum
          content = make_enum(nil, class)
        else
          content = make_class(nil, class, with_main)
        end
        write(file, content)
        vim.notify(string.format("Created %s", file), vim.log.levels.INFO)
        vim.cmd.edit(file)
      end, { nargs = "+", desc = "Create a Java class" })
    end,
  },
}