return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			options = {
				theme = "catppuccin",
				always_divide_middle = false,
				component_separators = { left = " ", right = " " },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branck", "diff", "diagnostics" },
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
		end,
		opts = {},
	},

	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
	},

	{
		"HiPhish/rainbow-delimiters.nvim",
		submodules = false,
		main = "rainbow-delimiters.setup",
		opts = {},
	},

	-- lazy.nvim
	--    {
	--        "folke/noice.nvim",
	--        event = "VeryLazy",
	--        opts = {
	--        -- add any options here
	---        },
	--       dependencies = {
	--           -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
	--           "MunifTanjim/nui.nvim",
	--           -- OPTIONAL:
	--           --   `nvim-notify` is only needed, if you want to use the notification view.
	--           --   If not available, we use `mini` as the fallback
	--           "rcarriga/nvim-notify",
	--           opts = {
	--               --stages = "fade", -- 动画方式，可选 "fade", "slide", "fade_in_slide_out", "static"
	--               timeout = 1000,  -- 通知停留时间（毫秒）
	--               --top_down = false, -- 改成从下往上弹出（不会挡住顶部代码）
	--               --render = "compact", -- 渲染方式更紧凑
	--           },
	--       }
	--    }

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
			--            top_down = false,
		},
		config = function(_, opts)
			require("notify").setup(opts)
			vim.notify = require("notify")
		end,
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

			--vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
			--vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
		end,
	},
}
