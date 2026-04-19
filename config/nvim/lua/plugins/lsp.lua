return {
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"lua-language-server",
			},
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp" },

		-- example calling setup directly for each LSP
		config = function()
			vim.diagnostic.config({
				underline = false,
				signs = false,
				update_in_insert = true,
				virtual_text = { spacing = 2, prefix = "!", suffix = "!" },
				severity_sort = true,
				float = {
					border = "rounded",
				},
			})

			--			local capabilities = require("blink.cmp").get_lsp_capabilities()
			--			vim.lsp.enable("lua_ls", {
			--				capabilities = capabilities,
			--				settings = {
			--					Lua = {
			--						diagnostics = {
			--							globals = { "vim" },
			--						},
			--					},
			--				},
			--			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					vim.keymap.set("n", "I", vim.lsp.buf.hover)
					vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, {
						buffer = ev.buf,
						desc = "[LSP] Show diagnostic",
					})
				end,
			})
		end,
	},
}
