return {
    "folke/tokyonight.nvim",
    enabled = true,
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
        vim.cmd("colorscheme tokyonight-moon") -- add additional options: 'moon', 'storm', 'night', 'day'
    end,
}
