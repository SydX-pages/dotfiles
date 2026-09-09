return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			options = {
				always_divide_middle = false,
				component_separators = { left = " ", right = " " },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { "filename" },
				lualine_x = {},
				lualine_y = { "encoding", "fileformat", "filetype", "progress" },
				lualine_z = { "location" },
			},
			winbar = {
				lualine_a = {
					"filename",
				},
				lualine_b = {
					{
						function()
							return " "
						end,
						color = "Comment",
					},
				},
				lualine_x = {
					"lsp_status",
				},
			},
		},
	},

	{
		"romgrk/barbar.nvim",
		version = "^1.0.0",
		dependencies = {
			"lewis6991/gitsigns.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		init = function()
			vim.g.barbar_auto_setup = false
			require("barbar").setup({
				insert_at_end = true,
			})
		end,
		opts = {},
	},

	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			filters = {
				git_ignored = false, -- 显示被 .gitignore 忽略的文件
				dotfiles = false, -- 同时显示隐藏文件（可选）
			},
		},
	},

	{
		"HiPhish/rainbow-delimiters.nvim",
		submodules = false,
		main = "rainbow-delimiters.setup",
		opts = {},
	},

	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			presets = {
				lsp_doc_border = true,
			},
			notify = {
				enabled = true,
			},
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},
	{
		"rcarriga/nvim-notify",
		opts = {
			stages = "slide",
			timeout = 1000,
		},
		config = function(_, opts)
			require("notify").setup(opts)
			vim.notify = require("notify")
		end,
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "│" },
				change = { text = "│" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local map = function(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end
				-- Navigation
				map("n", "]c", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Next hunk" })
				map("n", "[c", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Prev hunk" })
				-- Actions
				map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
				map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Stage hunk" })
				map("v", "<leader>hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Reset hunk" })
				map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
				map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
				map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
				map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, { desc = "Blame line" })
				map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, { desc = "Diff this ~" })
				-- Text object
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
			end,
		},
	},

	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {
			transparent_background = true,
			integrations = {
				barbar = true,
				blink_cmp = true,
				gitsigns = true,
				mason = true,
				noice = true,
				notify = true,
				nvimtree = true,
				rainbow_delimiters = true,
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
