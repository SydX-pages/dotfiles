vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

--Basic Operations
vim.keymap.set("i","<C-h>","<Left>")
vim.keymap.set("i","<C-l>","<Right>")
vim.keymap.set("i","<C-j>","<Down>")
vim.keymap.set("i","<C-k>","<Up>")

vim.keymap.set("n","<C-h>","<C-w>h")
vim.keymap.set("n","<C-l>","<C-w>l")
vim.keymap.set("n","<C-j>","<C-w>j")
vim.keymap.set("n","<C-k>","<C-w>k")

vim.keymap.set("n","<M-Left>","<C-w>h")
vim.keymap.set("n","<M-Right>","<C-w>l")
vim.keymap.set("n","<M-Up>","<C-w>k")
vim.keymap.set("n","<M-Down>","<C-w>j")


vim.keymap.set("i","<C-p>","<C-o>p")

vim.keymap.set("i","<C-z>","<C-o>u")
vim.keymap.set("i","<C-S-z>","<C-o><C-r>")
vim.keymap.set("n","<C-z>","u")
vim.keymap.set("n","<C-S-z>","<C-r>")


--Save and Buffer actions
vim.keymap.set("n","<C-s>","<cmd>w<CR>")
--vim.keymap.set("n","<leader>bd","<cmd>bd<CR>")
--vim.keymap.set("n","<leader>bn","<cmd>bn<CR>")
--vim.keymap.set("n","<leader>bp","<cmd>bp<CR>")
vim.keymap.set("n","<Tab>","<cmd>bn<CR>")
vim.keymap.set("n","<S-Tab>","<cmd>bp<CR>")
vim.keymap.set("i","<C-Tab>","<C-o><cmd>bn<CR>")
vim.keymap.set("i","<C-S-Tab>","<C-o><cmd>bp<CR>")
vim.keymap.set("i","<C-s>","<cmd>w<CR>")
vim.keymap.set("n","<C-x>","<cmd>bd<CR>")
vim.keymap.set("i","<C-x>","<cmd>bd<CR>")
vim.keymap.set("n","<C-q>","<cmd>qa<CR>")
vim.keymap.set("i","<C-q>","<cmd>qa<CR>")
vim.keymap.set("n","<M-Space>","<C-w>>")
vim.keymap.set("n","<M-S-Space>","<C-w><")

--Insert Choose
vim.keymap.set("i", "<S-Left>",  "<C-o>v<C-o>h")
vim.keymap.set("i", "<S-Right>", "<C-o>v<C-o>l")
vim.keymap.set("i", "<S-Up>",    "<C-o>v<C-o>k")
vim.keymap.set("i", "<S-Down>",  "<C-o>v<C-o>j")
vim.keymap.set("n", "<S-Left>",  "v<C-o>h")
vim.keymap.set("n", "<S-Right>", "v<C-o>l")
vim.keymap.set("n", "<S-Up>",    "v<C-o>k")
vim.keymap.set("n", "<S-Down>",  "v<C-o>j")


vim.keymap.set("v","<S-Down>","<Down>")

--Head and Tail
vim.keymap.set("n","(","^")
vim.keymap.set("n",")","$")
vim.keymap.set("v","(","^")
vim.keymap.set("v",")","$")

vim.keymap.set("n","<C-Right>","$")
vim.keymap.set("n","<C-Left>","^")
vim.keymap.set("i","<C-Right>","<C-o>$")
vim.keymap.set("i","<C-Left>","<C-o>^")
vim.keymap.set("v","<C-Right>","<C-o>$")
vim.keymap.set("v","<C-Left>","<C-o>^")

--Code Runner
vim.keymap.set("n","<M-Return>","<cmd>RunCode<CR>")
vim.keymap.set("i","<M-Return>","<cmd>RunCode<CR>")
vim.keymap.set("v","<M-Return>","<cmd>RunCode<CR>")

--Telescope Keymap
vim.keymap.set("n","<leader>f","<cmd>Telescope file_browser<cr>")

