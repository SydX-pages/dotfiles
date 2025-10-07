require("config.lazy")
-- backgroud-opacity
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })


vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"


vim.opt.clipboard = "unnamedplus"


vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.termguicolors = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.laststatus = 3
vim.opt.showtabline = 2
vim.opt.cmdheight = 0

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("keymapping")

vim.api.nvim_set_hl(0, "LineNr", { fg = "#89b4fa", bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffff77", bg = "none", bold = true })
--"#f38ba8"

vim.filetype.add({
    extension = {
        ejs = "html",
        sh = "sh",
    },
})
