-- Prefer Marksman installed by the system package manager (works across distros).
-- On NixOS, fall back to the local wrapper when Mason's binary cannot find ICU.
local nix_marksman = vim.fn.stdpath("data") .. "/marksman-nix/bin/marksman"
local marksman = vim.fn.exepath("marksman")
if marksman == "" and vim.fn.executable(nix_marksman) == 1 then
  marksman = nix_marksman
end

-- If neither binary exists, leave the server to the normal Mason setup.
if marksman == "" then
  return {}
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          mason = false,
          cmd = { marksman, "server" },
        },
      },
    },
  },
}
