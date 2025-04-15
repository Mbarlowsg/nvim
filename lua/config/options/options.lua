local opt = vim.opt

-- Session Management
opt.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Line Numbers
opt.relativenumber = true
opt.number = true

-- Tabs & Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
vim.bo.softtabstop = 4

-- Line Wrapping
opt.wrap = false

-- Search Settings
opt.ignorecase = true
opt.smartcase = true

-- Cursor Line
opt.cusrosline = true -- highlight the line that the cursor is on

-- Appearance
opt.termguicolors = true
opt.scrolloff = 8 -- always show x lines below cursor

-- Backspace
opt.backspace = "indent,eol,start" -- default settings

-- Clipboard
opt.clipboard:append("unnamedplus") -- for linux xclip also needs to be installed

-- Split Windows
opt.splitright = true
opt.splitleft = true

-- Add keywords for navigation and auto-complete
opt.iskeyword:append("-")

-- Disable the mouse while in nvim
-- opt.mouse = ""

-- Folding
opt.foldlevel = 20 -- The higher the more folded regions are open
opt.foldmethod = "expr" -- allows foldmethod to be defined by the line below/user regex expression
opt.foldexpr = "nvim_treesitter#foldexpr()" -- Utilize Treesitter folds
