-- Rendered markdown view, toggled with <leader>mr (see core/keymaps.lua)
return {
  -- https://github.com/MeanderingProgrammer/render-markdown.nvim
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown' },
  opts = {
    enabled = false, -- starts in raw/editing mode; toggle with :RenderMarkdown toggle
    pipe_table = { enabled = false }, -- table rendering handled by markdown-table-wrap.nvim instead
  },
}
