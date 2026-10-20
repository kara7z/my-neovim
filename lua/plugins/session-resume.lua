return {
	"folke/persistence.nvim",
	lazy = false,
	opts = { need = 1 },
	config = function(_, opts)
		local persistence = require("persistence")
		persistence.setup(opts)
		-- Reopen files and layouts; terminal jobs cannot survive a reboot.
		vim.opt.sessionoptions:remove({ "terminal", "options", "localoptions" })
		vim.opt.sessionoptions:append({ "buffers", "curdir", "tabpages", "winsize", "folds" })

		local group = vim.api.nvim_create_augroup("user_session_resume", { clear = true })
		local ready = false
		local function save()
			if not ready or not persistence.active() or #vim.api.nvim_list_uis() == 0 then
				return
			end
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if
					vim.bo[buf].buflisted
					and vim.bo[buf].buftype == ""
					and vim.api.nvim_buf_get_name(buf) ~= ""
					and not vim.tbl_contains({ "gitcommit", "gitrebase", "jj" }, vim.bo[buf].filetype)
				then
					local ok, err = pcall(persistence.save)
					if not ok then
						vim.notify("Could not save Neovim session: " .. tostring(err), vim.log.levels.WARN)
					end
					return
				end
			end
		end

		vim.api.nvim_create_autocmd("VimEnter", {
			group = group,
			once = true,
			callback = function()
				if #vim.api.nvim_list_uis() == 0 then
					return
				end
				if vim.fn.argc() == 0 and vim.v.this_session == "" and not vim.g.session_resume_stdin then
					persistence.load({ last = vim.g.resume_last_session == 1 })
				end
				ready = true
				save()
				local timer = vim.uv.new_timer()
				timer:start(10000, 10000, vim.schedule_wrap(save))
				vim.api.nvim_create_autocmd("VimLeavePre", {
					group = group,
					once = true,
					callback = function()
						timer:stop()
						timer:close()
					end,
				})
			end,
		})
		vim.api.nvim_create_autocmd("StdinReadPre", {
			group = group,
			callback = function()
				vim.g.session_resume_stdin = true
			end,
		})
		vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TabEnter", "BufWritePost", "FocusLost", "CursorHold" }, {
			group = group,
			callback = function()
				vim.schedule(save)
			end,
		})
	end,
}
