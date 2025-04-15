return {
    "https://github.com/Mofiqul/dracula.nvim",
    enabled = false,
    lazy = false,
    priority = 1000, -- default value is 50, useful to set high number for colorschemes
    config = function()
        vim.cmd("colorscheme dracula")
    end,
}
