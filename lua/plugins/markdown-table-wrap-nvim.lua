-- Wraps markdown table cell content onto multiple lines with the border extended to match,
-- fixing what render-markdown.nvim's pipe_table renderer can't do (see render-markdown-nvim.lua).
-- Also drives render-markdown.nvim's enabled state so the two stay in sync - see the
-- MarkdownTableWrapRenderSync autocmds below.
return {
  -- https://github.com/ice345/markdown-table-wrap.nvim
  'ice345/markdown-table-wrap.nvim',
  ft = { 'markdown', 'quarto', 'rmd' },
  dependencies = { 'MeanderingProgrammer/render-markdown.nvim' },
  config = function()
    require('markdown-table-wrap').setup({
      auto_preview = false, -- don't render anything until <leader>mr toggles it on
      preview_mode = 'reader', -- read-only full-document view when rendered; source is untouched (and fully editable) otherwise
      mappings = {
        reader = {
          -- i/a/I/A/o/O do nothing while rendered (blocked by modifiable=false, E21) instead of
          -- closing the reader and dropping into insert mode - editing requires toggling off first
          insert = false,
        },
      },
    })

    -- render-markdown.nvim has no concept of the reader view, so drive its enabled state from
    -- the reader's actual lifecycle instead of toggling it separately - keeps both plugins in
    -- sync no matter which key closes the reader (<leader>mr, q, e, or switching buffers away).
    local group = vim.api.nvim_create_augroup('MarkdownTableWrapRenderSync', { clear = true })
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'MarkdownTableWrapReaderEnter',
      callback = function() vim.cmd('RenderMarkdown enable') end,
    })
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'MarkdownTableWrapReaderLeave',
      callback = function() vim.cmd('RenderMarkdown disable') end,
    })
  end,
}
