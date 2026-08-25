return {

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" }, -- 在保存前加载
		config = function()
			require("conform").setup({
				formatters = {
					prettier = {
						args = function(_, ctx)
							local args = { "--stdin-filepath", "$FILENAME" }
							if vim.bo[ctx.buf].filetype == "astro" then
								vim.list_extend(args, { "--plugin", "prettier-plugin-astro" })
							end
							return args
						end,
					},
				},
				formatters_by_ft = {
					css = { "prettier" },
					sh = { "beautysh" },
					xml = { "xmlformatter" },
					lua = { "stylua" },
					javascript = { "prettier" },
					javascriptreact = { "prettier" },
					typescript = { "prettier" },
					markdown = { "prettier" },
					ejs = { "prettier" },
					yaml = { "yamlfix" },
					c = { "clang-format" },
					cpp = { "clang-format" },
					python = { "black" },
					java = { "google-java-format" },
					json = { "clang-format" },
					astro = { "prettier" },
				},
				format_on_save = {
					lsp_fallback = true,
					async = false,
					timeout_ms = 1000,
				},
				stop_after_first = true,
			})
		end,
	},
}
