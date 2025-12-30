return {

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" }, -- 在保存前加载
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					css = { "prettier" },
					sh = { "beautysh" },
					xml = { "xmlformatter" },
					lua = { "stylua" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					markdown = { "prettier" },
					ejs = { "prettier" },
					yaml = { "yamlfix" },
					c = { "clang-format" },
					cpp = { "clang-format" },
					python = { "black" },
					java = { "google-java-format" },
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
