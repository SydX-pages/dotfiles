return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui", -- 图形化界面
			"theHamsta/nvim-dap-virtual-text", -- 显示变量值
			"nvim-neotest/nvim-nio",
		},

		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			require("nvim-dap-virtual-text").setup()
			dapui.setup()

			-- 自动开关UI
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- ✅ 添加 GDB 适配器
			dap.adapters.gdb = {
				type = "executable",
				command = "gdb",
				args = { "-i", "dap" },
			}

			-- ✅ 为 C 和 C++ 定义调试配置
			dap.configurations.c = {
				{
					name = "Launch program",
					type = "gdb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopAtBeginningOfMainSubprogram = false,
				},
				{
					name = "Attach to process",
					type = "gdb",
					request = "attach",
					pid = require("dap.utils").pick_process,
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
				},
			}

			dap.configurations.cpp = dap.configurations.c
		end,
	},
}
