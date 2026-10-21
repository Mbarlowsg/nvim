-- Fuzzy finder
return {
    -- https://github.com/nvim-telescope/telescope.nvim
    'nvim-telescope/telescope.nvim',
    lazy = true,
    cmd = 'Telescope',
    tag = 'v0.2.2', -- pinned explicitly: 0.1.x is upstream's abandoned branch (unmaintained since May 2024) whose previewer still calls the removed `nvim-treesitter.parsers.ft_to_lang()` API, crashing the file previewer against this repo's `main`-pinned nvim-treesitter; v0.2.2 is the latest stable tag and already uses `vim.treesitter.language.get_lang()` instead
    dependencies = {
        -- https://github.com/nvim-lua/plenary.nvim
        { 'nvim-lua/plenary.nvim' },
        {
            -- https://github.com/nvim-telescope/telescope-fzf-native.nvim
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
            cond = function()
                return vim.fn.executable 'make' == 1
            end,
        },
    },
    opts = {
        defaults = {
            layout_config = {
                vertical = {
                    width = 0.75
                }
            }
        }
    },
    config = function ()
        require('telescope').load_extension("noice")
        require('telescope').load_extension("dap")
    end
}
