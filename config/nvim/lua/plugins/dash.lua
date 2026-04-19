return {
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		config = function()
			local db = require("dashboard")
			db.setup({
				theme = "hyper",
				letter_list = "abcdefgimnopqrstuvwxyz",
				config = {
					header = {
						[[  ______                   __  __    __  __                __    __                     __     __  __               ]],
						[[ /      \                 |  \|  \  |  \|  \              |  \  |  \                   |  \   |  \|  \              ]],
						[[|  $$$$$$\ __    __   ____| $$| $$  | $$| $$_______       | $$\ | $$  ______    ______ | $$   | $$ \$$ ______ ____  ]],
						[[| $$___\$$|  \  |  \ /      $$ \$$\/  $$ \$/       \      | $$$\| $$ /      \  /      \| $$   | $$|  \|      \    \ ]],
						[[ \$$    \ | $$  | $$|  $$$$$$$  >$$  $$   |  $$$$$$$      | $$$$\ $$|  $$$$$$\|  $$$$$$\\$$\ /  $$| $$| $$$$$$\$$$$\]],
						[[ _\$$$$$$\| $$  | $$| $$  | $$ /  $$$$\    \$$    \       | $$\$$ $$| $$    $$| $$  | $$ \$$\  $$ | $$| $$ | $$ | $$]],
						[[|  \__| $$| $$__/ $$| $$__| $$|  $$ \$$\   _\$$$$$$\      | $$ \$$$$| $$$$$$$$| $$__/ $$  \$$ $$  | $$| $$ | $$ | $$]],
						[[ \$$    $$ \$$    $$ \$$    $$| $$  | $$  |       $$      | $$  \$$$ \$$     \ \$$    $$   \$$$   | $$| $$ | $$ | $$]],
						[[  \$$$$$$  _\$$$$$$$  \$$$$$$$ \$$   \$$   \$$$$$$$        \$$   \$$  \$$$$$$$  \$$$$$$     \$     \$$ \$$  \$$  \$$]],
						[[          |  \__| $$                                                                                                ]],
						[[           \$$    $$                                                                                                ]],
						[[            \$$$$$$                                                                                                 ]],
						[[]],
					},
					disable_move = true,
					project = {
						enable = true,
						limit = 5,
						icon = "  Most Recent Projects",
						label = "",
						action = function(path)
							vim.cmd("cd " .. path)
							vim.cmd("e .")
						end,
					},
					shortcut = {
						{ desc = "󰐱 Lazy", group = "@property", action = "Lazy", key = "L" },
						{
							icon = " ",
							icon_hl = "@variable",
							desc = "FindFiles",
							group = "Label",
							action = "Telescope file_browser",
							key = "F",
						},
						{
							icon = " ",
							icon_hl = "@variable",
							desc = "NewFile",
							group = "Label",
							action = "new",
							key = "N",
						},
					},
					footer = { "Vim's Cool" },
				},
			})
		end,
		dependencies = { { "nvim-tree/nvim-web-devicons" } },
		vim.keymap.set("n", "H", "<cmd>Dashboard<cr>"),
	},
}
