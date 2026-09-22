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
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("mason-lspconfig").setup({})

			local function find_tsdk(root_dir)
				local candidates = {
					root_dir and (root_dir .. "/node_modules/typescript/lib"),
					vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib",
				}
				for _, dir in ipairs(candidates) do
					if dir and vim.fn.isdirectory(dir) == 1 then
						return dir
					end
				end
			end

			local function with_tsdk()
				return function(_, config)
					local tsdk = find_tsdk(config.root_dir)
					config.init_options.typescript = config.init_options.typescript or {}
					if tsdk then
						config.init_options.typescript.tsdk = tsdk
					end
				end
			end

			vim.lsp.config("astro", { before_init = with_tsdk() })
			vim.lsp.config("ts_ls", { before_init = with_tsdk() })
		end,
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

			local esp_clangd = vim.fn.glob(
				vim.fn.expand("~/.espressif/tools/esp-clangd/*/esp-clangd/bin/clangd"),
				false,
				true
			)[1]

			-- ESP-IDF 项目标记：存在 sdkconfig 的目录
			local function esp_root(bufnr)
				return vim.fs.root(bufnr, { "sdkconfig", "sdkconfig.defaults" })
			end

			-- 普通 C/C++：PATH 里的 clangd（装了 mason clangd 后会优先命中），ESP 项目里让路
			vim.lsp.config("clangd", {
				cmd = { "clangd" },
				root_dir = function(bufnr, on_dir)
					if esp_root(bufnr) then
						return -- ESP 项目：不启动，交给 clangd_esp
					end
					-- 与原版行为一致：无标记时 root 为 nil 也启动
					on_dir(vim.fs.root(bufnr, { "compile_commands.json", ".clangd", ".git" }))
				end,
			})

			-- ESP32 项目：用 esp-clangd + build/compile_commands.json
			-- 继承 lsp/clangd.lua 默认能力（offsetEncoding 等）
			vim.lsp.config("clangd_esp", vim.tbl_extend("force", vim.lsp.config.clangd, {
				filetypes = { "c", "cpp", "objc", "objcpp" },
				root_dir = function(bufnr, on_dir)
					local root = esp_root(bufnr)
					if root then
						on_dir(root)
					end
				end,
				-- cmd 为函数时在拉起进程时才求值，此时 root_dir 已确定
				cmd = function(dispatchers, client_config)
					local argv = { esp_clangd, "--enable-config" }
					local root = client_config.root_dir
					if root and vim.fn.isdirectory(root .. "/build") == 1 then
						argv[#argv + 1] = "--compile-commands-dir=" .. root .. "/build"
					end
					return vim.lsp.rpc.start(argv, dispatchers, {})
				end,
			}))

			vim.lsp.enable({ "clangd", "clangd_esp" })
		end,
	},
}
