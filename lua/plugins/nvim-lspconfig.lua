-- LSP Support
return {
    -- LSP Configuration
    -- https://github.com/neovim/nvim-lspconfig
    'neovim/nvim-lspconfig',
    event = 'VeryLazy',
    dependencies = {
        -- LSP Management
        -- https://github.com/mason-org/mason.nvim
        { 'mason-org/mason.nvim' },
        -- https://github.com/mason-org/mason-lspconfig.nvim
        { 'mason-org/mason-lspconfig.nvim' },

        -- Useful status updates for LSP
        -- https://github.com/j-hui/fidget.nvim
        { 'j-hui/fidget.nvim', opts = {} },

        -- Additional lua configuration, makes nvim stuff amazing!
        -- https://github.com/folke/neodev.nvim
        {'folke/neodev.nvim' },
    },
    config = function ()
        require('mason').setup()
        require('mason-lspconfig').setup({
            -- Update this list to the language servers you need installed
            ensure_installed = {
                -- "bashls", # requires npm to be installed
                "cssls",
                "html",
                "gradle_ls",
                "lua_ls",
                -- "intelephense",
                -- "jsonls",
                "lemminx",
                "marksman",
                "quick_lint_js",
                "eslint",
                -- "yamlls",
                "pyright"
            }
            -- automatic_enable defaults to true: mason-lspconfig calls vim.lsp.enable()
            -- for every installed server itself, so no manual setup loop is needed
        })

        -- Applied to every server
        vim.lsp.config('*', {
            capabilities = require('cmp_nvim_lsp').default_capabilities(),
        })

        -- Lua LSP settings
        vim.lsp.config('lua_ls', {
            settings = {
                Lua = {
                    diagnostics = {
                        -- Get the language server to recognize the `vim` global
                        globals = {'vim'},
                    },
                },
            },
        })

        -- Python LSP Settings
        vim.lsp.config('pyright', {
            settings = {
                python = {
                    analysis = {
                        extraPaths = {"/home/michael/.local/lib/python3.14/site-packages"}
                    }
                }
            }
        })
    end
}

