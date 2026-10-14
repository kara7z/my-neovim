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
        local ok, spring_util = pcall(require, "spring_boot.util")
        if ok and spring_util.has_spring_boot_dependency(root_dir) then
          return true
        end

        -- Spring Framework projects may not contain any Boot starter or plugin.
        -- Search build files, including submodules in aggregator projects.
        local build_files = vim.fs.find({ "pom.xml", "build.gradle", "build.gradle.kts" }, {
          path = root_dir,
          type = "file",
          limit = 50,
        })
        for _, file in ipairs(build_files) do
          local contents = table.concat(vim.fn.readfile(file), "\n"):lower()
          if contents:find("org%.springframework")
            or contents:find("spring%-webmvc")
            or contents:find("spring%-webflux")
            or contents:find("spring%-context")
          then
            return true
          end
        end
        return false
      end,
    },
  },
}
