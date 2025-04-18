return {
    "folke/tokyonight.nvim",
    enabled = true,
    lazy = false,
    priority = 1000,
    opts = {
        -- Change the style 
        style = "night", -- options: 'moon', 'storm', 'night', 'day'
        transparent = false, -- enable to disable setting the background
        -- Set styles for different groups
        -- Value is any valid attr-list value for `:help nvim_set_hl`
        styles = {
            comments = { italic = false}, -- set to true by default
            keywords = { italic = false},
            functions = {},
            variables = {},
        },
    },
    config = function(_, opts)
        require("tokyonight").setup(opts)
        vim.cmd("colorscheme tokyonight") 
    end,
}

