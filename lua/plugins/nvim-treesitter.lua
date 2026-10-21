-- Code Tree Support / Syntax Highlighting
return {
  -- https://github.com/nvim-treesitter/nvim-treesitter
  'nvim-treesitter/nvim-treesitter',
  branch = 'main', -- upstream's default branch already moved once (master -> main, a 2024 rewrite that deleted `nvim-treesitter.configs`); the explicit branch stops a future default-branch change from silently breaking this again
  -- Commit-pinned on top of the branch pin: upstream's `main` bumped its required
  -- tree-sitter-cli to >= 0.26.1 on 2026-01-29 (commit 5465196b). Every tree-sitter-cli
  -- release after 0.25.10 needs GLIBC_2.39, unavailable on older systems (e.g. Ubuntu
  -- 22.04 / glibc 2.35) - see .chezmoiscripts/run_onchange_after_install-treesitter-cli-upgrade.sh.
  -- f8bbc317 (2026-01-27) is the last `main` commit before that bump; its API still
  -- matches this file's require() calls. Same pin-for-old-systems rationale as
  -- telescope/tmux/neovim. Revisit once every target machine is on glibc >= 2.39.
  commit = 'f8bbc3177d929dc86e272c41cc15219f0a7aa1ac',
  lazy = false, -- upstream: "This plugin does not support lazy-loading"
  build = ':TSUpdate',
  config = function()
    -- Highlighting, indent, and auto-install: replaces the old
    -- opts.highlight/opts.indent/opts.auto_install/opts.ensure_installed,
    -- none of which exist in this form on the `main`-branch API. Built from
    -- main's own public functions (see docs/nvim/nvim-plugins.md for the API reference).
    -- No separate eager install() call: the parser for the first buffer's
    -- filetype installs here too, so there's nothing to duplicate.
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
        if not lang then return end

        -- get_lang() falls back to the raw filetype for anything it doesn't
        -- recognize (e.g. "text", "conf", "log"), so guard against that with
        -- get_available() before calling install() - install() logs an
        -- error for unknown languages instead of silently no-opping.
        local available = require('nvim-treesitter.config').get_available()
        if not vim.tbl_contains(available, lang) then return end

        -- Auto-install: parser not present yet? Fetch it now (async).
        if not vim.tbl_contains(require('nvim-treesitter.config').get_installed('parsers'), lang) then
          require('nvim-treesitter').install({ lang })
        end

        -- Highlighting + indent: pcall skips buffers where the parser isn't
        -- installed yet (first time a language is seen, install is async).
        if pcall(vim.treesitter.start, args.buf) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
