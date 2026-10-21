-- Treesitter-aware text objects (af/if, ab/ib, aq/iq, at/it, aa/ia, ...)
return {
  -- https://github.com/nvim-mini/mini.ai
  'nvim-mini/mini.ai',
  event = 'VeryLazy',
  dependencies = {
    -- Query-file source only (queries/<lang>/textobjects.scm); its own
    -- module/keymaps are never required/configured, mini.ai drives af/if.
    { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
  },
  config = function()
    require('mini.ai').setup({
      custom_textobjects = {
        -- Overrides the built-in `f` (function call) with function *definition*
        f = require('mini.ai').gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
      },
    })
  end,
}
