-- Spring Boot language tooling: application config completion/navigation,
-- Spring bean and endpoint lookup, and Spring-specific Java code actions.
return {
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    config = function(_, opts)
      local spring = require("spring_boot")
      -- YAML must not load nvim-jdtls: LazyVim attaches it to the current
      -- buffer on initialization. Spring can dispatch client commands itself.
      vim.lsp.handlers["workspace/executeClientCommand"] = vim.lsp.handlers["workspace/executeClientCommand"]
        or spring.execute_client_command
      spring.setup(opts)
    end,
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
