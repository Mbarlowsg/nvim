return {
    { "Mofiqul/dracula.nvim" },
    enabled = true,
    priority = 50, -- default value is 50, useful to set high number for colorschemes
    opts = {
        vim.cmd("colorscheme dracula")
    },
}
