return{
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        opts = {
            transparent_background = true,
            integrations = {
                barbar = true,
                blink_cmp = true,
                gitsigns = true,
                mason = true,
                noice = true,
                notify = true,
                nvimtree = true,
                rainbow_delimiters = true,
            }
        },
        config = function(_,opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme("catppuccin")
            
            --vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
            --vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

        end
    },
}

