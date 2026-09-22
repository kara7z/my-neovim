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
  -- 2. jdtls: throttle didChange + validate only on save.
  -- Runner (starts jdtls) is discovered dynamically: must be >= 21.
  -- Project runtimes are discovered dynamically from /usr/lib/jvm/*.
  -- Option A default: prefer JavaSE-1.8 if present, else lowest major.
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- jdtls runner needs Java 21+ even if your project targets Java 8
      local jdtls_bin = vim.fn.exepath("jdtls")
      if jdtls_bin == "" then
        jdtls_bin = vim.fn.expand("$HOME/.local/share/nvim/mason/bin/jdtls")
      end
      if vim.fn.executable(jdtls_bin) ~= 1 and vim.fn.filereadable(jdtls_bin) ~= 1 then
        -- fallback to mason package path
        jdtls_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"
      end
      local lombok = vim.fn.stdpath("data") .. "/mason/share/jdtls/lombok.jar"
      -- optional override via $MASON env (mason install prefix)
      if vim.fn.filereadable(lombok) ~= 1 then
        local mason_root = vim.env.MASON
        if mason_root and mason_root ~= "" then
          local alt = mason_root .. "/share/jdtls/lombok.jar"
          if vim.fn.filereadable(alt) == 1 then
            lombok = alt
          end
        end
      end

      --- Parse major version from `java -version` output without blocking startup more than needed.
      --- Returns 8 for 1.8.x, N for N.x, nil if unknown.
      local function java_major_of_bin(java_bin)
        local out = vim.fn.system({ java_bin, "-version" })
        -- out goes to stderr, system() merges it; match 1.8.0_xxx or 26.0.2
        local old = out:match('"1%.(%d+)')
        if out:match('"1%.8') then
          return 8
        end
        if old then
          return tonumber(old)
        end
        local new = out:match('version%s+"(%d+)')
        if new then
          return tonumber(new)
        end
        return nil
      end

      --- Map a JVM dir (/usr/lib/jvm/java-26-openjdk) to { name, major }.
      --- Prefers dirname, falls back to release file.
      local function describe_jvm(dir)
        local base = vim.fn.fnamemodify(dir, ":t")
        -- skip arch default symlinks (default -> java-8-openjdk)
        if base:match("^default") then
          return nil
        end
        local ver = base:match("^java%-(%d+%.?%d*)")
          or base:match("^jdk%-(%d+%.?%d*)")
          or base:match("^(%d+%.?%d*)")
        if ver and ver:find("^1%.8") then
          ver = "8"
        end
        if not ver then
          -- fallback: parse release file JAVA_VERSION="26.0.2" / "1.8.0_504"
          local ok, lines = pcall(vim.fn.readfile, dir .. "/release", "", 10)
          if ok and lines then
            for _, l in ipairs(lines) do
              local v = l:match('JAVA_VERSION%s*=%s*"(.-)"')
              if v then
                if v:match("^1%.8") then
                  ver = "8"
                else
                  ver = v:match("^(%d+)")
                end
                break
              end
            end
          end
        end
        if not ver then
          return nil
        end
        local major = tonumber(tostring(ver):match("^(%d+)"))
        if not major then
          return nil
        end
        if major == 8 then
          return { name = "JavaSE-1.8", major = 8 }
        end
        return { name = "JavaSE-" .. major, major = major }
      end

      --- Discover all installed runtimes dynamically (portable).
      --- Linux: /usr/lib/jvm/*, macOS: /Library/Java/JavaVirtualMachines/*, plus $JAVA_HOME.
      local function jvm_search_dirs()
        local dirs = {}
        local function add_glob(pattern)
          for _, d in ipairs(vim.fn.glob(pattern, false, true)) do
            table.insert(dirs, d)
          end
        end
        add_glob("/usr/lib/jvm/*")
        add_glob("/usr/lib64/jvm/*")
        add_glob("/opt/java/*")
        add_glob("/opt/jvm/*")
        add_glob(os.getenv("HOME") .. "/.sdkman/candidates/java/*")
        if vim.fn.has("mac") == 1 then
          add_glob("/Library/Java/JavaVirtualMachines/*/Contents/Home")
          add_glob("/opt/homebrew/opt/openjdk*/libexec")
        end
        local jh = vim.env.JAVA_HOME
        if jh and jh ~= "" and vim.fn.isdirectory(jh) == 1 then
          table.insert(dirs, jh)
        end
        return dirs
      end
      local function discover_runtimes()
        local runtimes = {}
        local seen = {}
        for _, dir in ipairs(jvm_search_dirs()) do
          if vim.fn.isdirectory(dir) == 1 and vim.fn.executable(dir .. "/bin/java") == 1 then
            local desc = describe_jvm(dir)
            if desc and not seen[desc.name] then
              seen[desc.name] = true
              table.insert(runtimes, { name = desc.name, path = dir, major = desc.major })
            end
          end
        end
        table.sort(runtimes, function(a, b)
          return a.major < b.major
        end)
        -- strip helper field before handing to jdtls
        for _, r in ipairs(runtimes) do
          r.major = nil
        end
        return runtimes
      end

      --- Find a java >= 21 to run jdtls itself. Fully dynamic (portable):
      --- JAVA_HOME -> preferred LTS list -> glob scan -> PATH fallback.
      local function find_runner_java()
        local java_home = vim.env.JAVA_HOME
        if java_home and java_home ~= "" and vim.fn.executable(java_home .. "/bin/java") == 1 then
          local major = java_major_of_bin(java_home .. "/bin/java")
          if major and major >= 21 then
            return java_home .. "/bin/java"
          end
        end
        -- Prefer LTS 21, then 25, then whatever is newest/available.
        -- Check both Linux and macOS/Homebrew locations without hardcoding one OS.
        local preferred = {
          "/usr/lib/jvm/java-21-openjdk/bin/java",
          "/usr/lib/jvm/java-25-openjdk/bin/java",
          "/usr/lib/jvm/java-26-openjdk/bin/java",
          "/usr/lib/jvm/java-24-openjdk/bin/java",
          "/usr/lib/jvm/java-23-openjdk/bin/java",
          "/usr/lib/jvm/java-22-openjdk/bin/java",
          "/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home/bin/java",
          "/opt/homebrew/opt/openjdk@21/bin/java",
        }
        for _, p in ipairs(preferred) do
          if vim.fn.executable(p) == 1 then
            return p
          end
        end
        -- Generic scan: any JVM dir with major >= 21, pick highest.
        local best, best_major = nil, 0
        for _, dir in ipairs(jvm_search_dirs()) do
          local java_bin = dir .. "/bin/java"
          if vim.fn.executable(java_bin) == 1 then
            local desc = describe_jvm(dir)
            if desc and desc.major >= 21 and desc.major > best_major then
              best, best_major = java_bin, desc.major
            end
          end
        end
        if best then
          return best
        end
        local fallback = vim.fn.exepath("java")
        if fallback ~= "" then
          local major = java_major_of_bin(fallback)
          if not major or major < 21 then
            vim.notify(
              string.format("jdtls needs Java 21+ to run, but resolved java is %s (major %s)", fallback, tostring(major)),
              vim.log.levels.WARN
            )
          end
          return fallback
        end
        return "java"
      end

      local runtimes = discover_runtimes()
      if #runtimes > 0 then
        -- Option A: prefer JavaSE-1.8 as default (strict Java 8 diagnostics),
        -- else fall back to lowest major.
        local default_idx = 1
        for i, r in ipairs(runtimes) do
          if r.name == "JavaSE-1.8" then
            default_idx = i
            break
          end
        end
        runtimes[default_idx].default = true
      else
        -- fallback: use whatever `java` resolves to
        local fallback = vim.fn.exepath("java"):gsub("/bin/java$", "")
        if fallback ~= "" then
          runtimes = { { name = "JavaSE-1.8", path = fallback, default = true } }
        end
      end
      local runner = find_runner_java()
      local cmd = { jdtls_bin, "--java-executable", runner }
      if vim.fn.filereadable(lombok) == 1 then
        table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok))
      end
      opts.cmd = cmd

      -- LazyVim's default root_dir reads vim.lsp.config.jdtls.root_markers, which
      -- is nil here (jdtls is set up via nvim-jdtls, not lspconfig), so attach
      -- crashed with "attempt to index field 'jdtls'". Use explicit markers and
      -- fall back to the nearest src/ folder or the file's own directory so the
      -- LSP works in plain src/models + src/services projects (no pom.xml).
      opts.root_dir = function(path)
        local markers = {
          ".git", "mvnw", "mvnw.cmd", "gradlew", "gradlew.bat",
          "settings.gradle", "settings.gradle.kts",
          "build.gradle", "build.gradle.kts", "pom.xml", "build.xml",
        }
        local root = vim.fs.root(path, markers)
        if root then
          return root
        end
        -- Fallback 1: nearest ancestor directory containing a src/ folder
        local src = vim.fs.find("src", { path = vim.fs.dirname(path), upward = true, type = "directory" })
        if src[1] then
          return vim.fs.dirname(src[1])
        end
        -- Fallback 2: the file's own directory (single-file programs)
        return vim.fs.dirname(path)
      end

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
