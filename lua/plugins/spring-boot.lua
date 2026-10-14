-- Spring Boot language tooling: application config completion/navigation,
-- Spring bean and endpoint lookup, and Spring-specific Java code actions.
return {
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = { "mfussenegger/nvim-jdtls" },
    opts = {
      -- Start Spring tooling for Spring Framework/Web projects as well as Boot.
      -- Keep it disabled for ordinary Java projects to avoid an extra JVM.
      project_filter = function(root_dir)
        -- Check the root before walking submodules, and scan once for both
        -- Boot and Framework dependencies. The plugin caches this per root.
        local skip = { target = true, build = true, node_modules = true, vendor = true, bin = true }
        local dirs, index, files_read = { root_dir }, 1, 0
        while index <= #dirs and files_read < 50 do
          local dir = dirs[index]
          index = index + 1
          for _, name in ipairs({ "pom.xml", "build.gradle", "build.gradle.kts" }) do
            local ok, lines = pcall(vim.fn.readfile, dir .. "/" .. name)
            if ok then
              files_read = files_read + 1
              local contents = table.concat(lines, "\n"):lower()
              if contents:find("org%.springframework")
                or contents:find("spring%-boot%-starter")
                or contents:find("spring%-boot%-maven%-plugin")
                or contents:find("spring%-webmvc")
                or contents:find("spring%-webflux")
                or contents:find("spring%-context")
              then
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
            if kind == "directory" and name:sub(1, 1) ~= "." and not skip[name] then
              dirs[#dirs + 1] = dir .. "/" .. name
            end
          end
        end
        return false
      end,
    },
  },
}
