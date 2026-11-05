-- OpenCode v2 removed the `--port` flag and changed the server API to `/api/*`,
-- so nickjvandyke/opencode.nvim (built for the v1 API) cannot connect.
-- Keep it simple: run the v2 TUI in a Neovim terminal instead.
local opencode_cmd = "opencode"

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>at",
        function()
          require("snacks.terminal").toggle(opencode_cmd, {
            win = { position = "right" },
          })
        end,
        -- A Space-leader mapping in terminal mode delays every typed space
        -- until timeoutlen expires. Keep shell input free of leader mappings.
        mode = "n",
        desc = "Toggle OpenCode terminal",
      },
    },
  },
}
