return{
    {
        "catgoose/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = { -- set to setup table
        },
    },
    {
        "uga-rosa/ccc.nvim",
        config = function()
        local ccc = require("ccc")
        ccc.setup({
            highlighter = {
            auto_enable = true,
            lsp = true,
            },
        })
        vim.keymap.set("n","<C-r>","<cmd>CccPick<CR>")
    end,
  },
}
