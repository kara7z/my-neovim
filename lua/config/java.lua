local M = {}
local build_files =
  { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", "build.xml" }

function M.has_build_file(root)
  if type(root) ~= "string" or root == "" then
    return false
  end
  for _, file in ipairs(build_files) do
    if vim.fn.filereadable(root .. "/" .. file) == 1 then
      return true
    end
  end
  return false
end

function M.is_project(root)
  return M.has_build_file(root)
    or (
      type(root) == "string"
      and (vim.fn.isdirectory(root .. "/src") == 1 or vim.fn.filereadable(root .. "/.classpath") == 1)
    )
end

function M.is_spring_project(root)
  -- A standalone file in $HOME is not a Spring workspace just because an
  -- unrelated project somewhere below $HOME depends on Spring.
  if not M.has_build_file(root) then
    return false
  end
  local skip = { target = true, build = true, node_modules = true, vendor = true, bin = true }
  local dirs, index, files_read = { root }, 1, 0
  while index <= #dirs and files_read < 50 do
    local dir = dirs[index]
    index = index + 1
    for _, file in ipairs({ "pom.xml", "build.gradle", "build.gradle.kts" }) do
      local ok, lines = pcall(vim.fn.readfile, dir .. "/" .. file)
      if ok then
        files_read = files_read + 1
        local text = table.concat(lines, "\n"):lower()
        if text:find("org%.springframework") or text:find("spring%-boot%-starter") or text:find("spring%-context") then
          return true
        end
        if files_read >= 50 then
          return false
        end
      end
    end
    local handle = vim.uv.fs_scandir(dir)
    while handle do
      local name, kind = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end
      if kind == "directory" and name:sub(1, 1) ~= "." and not skip[name] and #dirs < 200 then
        dirs[#dirs + 1] = dir .. "/" .. name
      end
    end
  end
  return false
end

local function bundle_name(path)
  local name = vim.fs.basename(path)
  return name:match("^(.-)_%d") or name:gsub("%.jar$", "")
end

function M.filter_bundles(bundles, plugins_dir)
  local builtins = {}
  for _, path in ipairs(vim.fn.glob(plugins_dir .. "/*", false, true)) do
    builtins[bundle_name(path)] = true
  end
  local result, seen = {}, {}
  for _, path in ipairs(bundles) do
    local real = vim.uv.fs_realpath(path) or path
    local name = vim.fs.basename(real)
    -- These are test-launcher artifacts, not Eclipse extension bundles.
    local launcher = name == "jacocoagent.jar" or name:match("runner%-jar%-with%-dependencies%.jar$")
    if not launcher and not seen[real] and not builtins[bundle_name(real)] then
      seen[real] = true
      result[#result + 1] = path
    end
  end
  return result
end

return M
