-- SQL completion: attach the project's DB to every SQL buffer so
-- vim-dadbod-completion returns tables/columns AND keywords (e.g. DATABASE).
-- The URL itself lives in each project's gitignored .lazy.lua as vim.g.dbs
-- (never commit passwords: this repo is public).
return {
  {
    "kristijanhusak/vim-dadbod-completion",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          if (vim.b.db == nil or vim.b.db == "") and vim.g.dbs and vim.g.dbs.albaraka then
            vim.b.db = vim.g.dbs.albaraka
          end
        end,
      })
    end,
  },
}
