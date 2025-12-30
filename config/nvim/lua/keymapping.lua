--Conclusion
--Alt For Fast Move and CompletionChoose;Ctrl For Insert Move;
--C-p for ColorPicker;C-f for Formatter;S-i for Infos of Functions(maybe)
--C-s Save;C-z Undo C-r Redo;C-x BufferDelete;C-q Quit

vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

--Basic Operations
vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-l>", "<Right>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-k>", "<Up>")

vim.keymap.set("n", "<M-H>", "<C-w>h")
vim.keymap.set("n", "<M-L>", "<C-w>l")
vim.keymap.set("n", "<M-J>", "<C-w>j")
vim.keymap.set("n", "<M-K>", "<C-w>k")

vim.keymap.set("n", "<M-Left>", "<C-w>h")
vim.keymap.set("n", "<M-Right>", "<C-w>l")
vim.keymap.set("n", "<M-Up>", "<C-w>k")
vim.keymap.set("n", "<M-Down>", "<C-w>j")

vim.keymap.set("i", "<C-p>", "<C-o>p")

vim.keymap.set("i", "<C-z>", "<C-o>u")
vim.keymap.set("i", "<C-r>", "<C-o><C-r>")
vim.keymap.set("n", "<C-z>", "u")

-- Fast Pointer Move
local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<M-j>", function()
	vim.api.nvim_feedkeys("10j", "n", false)
end, opts)
vim.keymap.set("n", "<M-k>", function()
	vim.api.nvim_feedkeys("10k", "n", false)
end, opts)

vim.keymap.set("i", "<M-j>", function()
	vim.cmd("normal! 10j")
end, opts)
vim.keymap.set("i", "<M-k>", function()
	vim.cmd("normal! 10k")
end, opts)

vim.keymap.set("v", "<M-j>", function()
	vim.cmd("normal! 10j")
end, opts)
vim.keymap.set("v", "<M-k>", function()
	vim.cmd("normal! 10k")
end, opts)

--Save and Buffer actions
vim.keymap.set("n", "<C-s>", "<cmd>w<CR>")
--vim.keymap.set("n","<leader>bd","<cmd>bd<CR>")
--vim.keymap.set("n","<leader>bn","<cmd>bn<CR>")
--vim.keymap.set("n","<leader>bp","<cmd>bp<CR>")
vim.keymap.set("n", "<Tab>", "<cmd>bn<CR>")
vim.keymap.set("n", "<S-Tab>", "<cmd>bp<CR>")
--vim.keymap.set("i", "<C-Tab>", "<C-o><cmd>bn<CR>")
--vim.keymap.set("i", "<C-S-Tab>", "<C-o><cmd>bp<CR>")
vim.keymap.set("i", "<C-s>", "<cmd>w<CR>")
vim.keymap.set("n", "<C-x>", "<cmd>bd<CR>")
vim.keymap.set("i", "<C-x>", "<cmd>bd<CR>")
vim.keymap.set("n", "<C-q>q", "<cmd>q<CR>")
vim.keymap.set("n", "<C-q>a", "<cmd>qa<CR>")
vim.keymap.set("n", "<M-d>", "<C-w>>")
vim.keymap.set("n", "<M-a>", "<C-w><")
vim.keymap.set("n", "<M-w>", "<C-w>+")
vim.keymap.set("n", "<M-s>", "<C-w>-")

--Insert Choose
--vim.keymap.set("i", "<S-Left>", "<C-o>v<C-o>h")
--vim.keymap.set("i", "<S-Right>", "<C-o>v<C-o>l")
--vim.keymap.set("i", "<S-Up>", "<C-o>v<C-o>k")
--vim.keymap.set("i", "<S-Down>", "<C-o>v<C-o>j")
--vim.keymap.set("n", "<S-Left>", "v<C-o>h")
--vim.keymap.set("n", "<S-Right>", "v<C-o>l")
--vim.keymap.set("n", "<S-Up>", "v<C-o>k")
--vim.keymap.set("n", "<S-Down>", "v<C-o>j")

--Visual Move Settings
vim.keymap.set("v", "<S-Down>", "<Down>")
vim.keymap.set("v", "<S-j>", "<Down>")
vim.keymap.set("v", "<S-k>", "<Up>")
vim.keymap.set("v", "<S-h>", "<S-Left>")
vim.keymap.set("v", "<S-l>", "<S-Right>")

--Head and Tail
vim.keymap.set("n", "(", "^")
vim.keymap.set("n", ")", "$")
vim.keymap.set("v", "(", "^")
vim.keymap.set("v", ")", "$")

vim.keymap.set("n", "<C-Right>", "$")
vim.keymap.set("n", "<C-Left>", "^")
vim.keymap.set("i", "<C-Right>", "<C-o>$")
vim.keymap.set("i", "<C-Left>", "<C-o>^")
vim.keymap.set("v", "<C-Right>", "$")
vim.keymap.set("v", "<C-Left>", "^")

vim.keymap.set("n", "<M-l>", "$")
vim.keymap.set("n", "<M-h>", "^")
vim.keymap.set("i", "<M-l>", "<C-o>$")
vim.keymap.set("i", "<M-h>", "<C-o>^")
vim.keymap.set("v", "<M-l>", "$")
vim.keymap.set("v", "<M-h>", "^")

--Code Runner
vim.keymap.set("n", "<M-Return>", "<cmd>RunCode<CR>")
vim.keymap.set("i", "<M-Return>", "<cmd>RunCode<CR>")
vim.keymap.set("v", "<M-Return>", "<cmd>RunCode<CR>")

--Telescope Keymap
vim.keymap.set("n", "<leader>f", "<cmd>Telescope file_browser<cr>")
vim.keymap.set("n", "<leader><S-f>", function()
	require("telescope").extensions.file_browser.file_browser({
		hidden = true,
	})
end)

--Format
vim.keymap.set("n", "<C-f>", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file" })
vim.keymap.set("i", "<C-f>", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file" })
