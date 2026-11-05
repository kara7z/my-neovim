-- Spring Boot language tooling: application config completion/navigation,
-- Spring bean and endpoint lookup, and Spring-specific Java code actions.
return {
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = { "mfussenegger/nvim-jdtls" },
    opts = {
      server = {
        handlers = require("config.spring").handlers,
        root_dir = require("config.spring").root_dir,
      },
      -- Start Spring tooling for Spring Framework/Web projects as well as Boot.
      -- Keep it disabled for ordinary Java projects to avoid an extra JVM.
      project_filter = require("config.java").is_spring_project,
    },
  },
}
