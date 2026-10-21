-- nvim's colourscheme: highlights built from the shared theme root's
-- colors.sh, so nvim follows the same `current` symlink as tmux, WezTerm, pi
-- and the statuslines - no colorscheme plugin is installed or loaded. See
-- docs/colorschemes.md.
--
-- The palette is parsed once at require time (lualine is eager and asks for its
-- theme during lazy.setup, before init.lua reaches our apply()), then re-parsed
-- by the watcher whenever the symlink or colors.sh changes.
local M = {}

local uv = vim.uv or vim.loop
local ROOT = vim.fn.expand("~/.config/colorschemes")
local CURRENT = ROOT .. "/current"
local PARSER = ROOT .. "/parse.lua"
local PICKER = vim.fn.expand("~/.config/tmux/scripts/colorscheme-picker.sh")

-- Tokyonight "night" literals, merged per key under the parsed palette so a
-- machine with no `current` yet (or a theme missing a key) cannot blank the UI.
local FALLBACK = {
  BG = "#1A1B26", FG = "#C0CAF5", MUTED = "#565F89", ACCENT = "#7AA2F7",
  GREEN = "#9ECE6A", YELLOW = "#E0AF68", RED = "#F7768E", CYAN = "#7DCFFF",
  PINK = "#BB9AF7",
  ANSI_BLACK = "#15161E", ANSI_RED = "#F7768E", ANSI_GREEN = "#9ECE6A",
  ANSI_YELLOW = "#E0AF68", ANSI_BLUE = "#7AA2F7", ANSI_MAGENTA = "#BB9AF7",
  ANSI_CYAN = "#7DCFFF", ANSI_WHITE = "#A9B1D6", ANSI_BRIGHT_BLACK = "#414868",
  ANSI_BRIGHT_RED = "#FF899D", ANSI_BRIGHT_GREEN = "#9FE044",
  ANSI_BRIGHT_YELLOW = "#FABA4A", ANSI_BRIGHT_BLUE = "#8DB0FF",
  ANSI_BRIGHT_MAGENTA = "#C7A9FF", ANSI_BRIGHT_CYAN = "#A4DAFF",
  ANSI_BRIGHT_WHITE = "#C0CAF5",
}

-- The 16 ANSI slots in terminal order, for g:terminal_color_0..15.
local ANSI_ORDER = {
  "ANSI_BLACK", "ANSI_RED", "ANSI_GREEN", "ANSI_YELLOW",
  "ANSI_BLUE", "ANSI_MAGENTA", "ANSI_CYAN", "ANSI_WHITE",
  "ANSI_BRIGHT_BLACK", "ANSI_BRIGHT_RED", "ANSI_BRIGHT_GREEN",
  "ANSI_BRIGHT_YELLOW", "ANSI_BRIGHT_BLUE", "ANSI_BRIGHT_MAGENTA",
  "ANSI_BRIGHT_CYAN", "ANSI_BRIGHT_WHITE",
}

-- "#RRGGBB" mix, t = 0 gives `a`, t = 1 gives `b`. String maths, not bitwise:
-- this file must stay LuaJIT-5.1 friendly.
local function blend(a, b, t)
  local function mix(i)
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    return string.format("%02X", math.floor(x + (y - x) * t + 0.5))
  end
  return "#" .. mix(2) .. mix(4) .. mix(6)
end

-- Scheme name plus the colors.sh it resolves to, or the tokyonight default when
-- `current` is missing or dangling.
local function resolve()
  local link = uv.fs_lstat(CURRENT)
  if link and link.type == "link" then
    local dir = uv.fs_readlink(CURRENT)
    if dir and dir:sub(1, 1) ~= "/" then
      dir = ROOT .. "/" .. dir
    end
    local st = dir and uv.fs_stat(dir .. "/colors.sh")
    if st then
      return vim.fn.fnamemodify(dir, ":t"), dir .. "/colors.sh", st
    end
  end
  return "tokyonight", nil, nil
end

-- What the watcher compares between ticks: which scheme is pointed at, and when
-- its colors.sh was last written.
local function snapshot()
  local name, _, st = resolve()
  if not st then
    return name
  end
  return name .. "\t" .. st.mtime.sec .. "." .. st.mtime.nsec
end

local parser = (function()
  local chunk = loadfile(PARSER)
  return chunk and chunk()
end)()

-- Returns the colour table (parsed over the fallbacks, plus a few blended
-- shades derived from it) and the scheme name.
local function load()
  local name, path = resolve()
  local parsed = (parser and path) and parser(path) or {}
  local C = {}
  for k, v in pairs(FALLBACK) do
    C[k] = parsed[k] or v
  end
  C.soft = blend(C.BG, C.FG, 0.06)
  C.sel = blend(C.BG, C.FG, 0.14)
  C.add = blend(C.BG, C.GREEN, 0.15)
  C.change = blend(C.BG, C.YELLOW, 0.15)
  C.delete = blend(C.BG, C.RED, 0.15)
  C.text = blend(C.BG, C.YELLOW, 0.30)
  C.orange = blend(C.RED, C.YELLOW, 0.5)
  return C, name
end

local C, scheme = load()

-- Compact highlight specs: a plain string is the foreground role, or a table
-- whose fg/bg/sp values name a role in C (bg = false means "NONE") and whose
-- other keys (bold, undercurl, link, ...) pass straight to nvim_set_hl.
local function expand(spec)
  if type(spec) == "string" then
    return { fg = C[spec] }
  end
  local out = {}
  for k, v in pairs(spec) do
    if k == "fg" or k == "bg" or k == "sp" then
      out[k] = v == false and "NONE" or (C[v] or v)
    else
      out[k] = v
    end
  end
  return out
end

-- Comments stay non-italic and keywords non-bold, matching the look the
-- tokyonight plugin's config produced before this module existed.
local MAP = {
  -- Editor surfaces
  Normal = { fg = "FG", bg = false }, -- transparent by design
  NormalNC = { fg = "FG", bg = false },
  NormalFloat = { fg = "FG", bg = false },
  FloatBorder = { fg = "MUTED", bg = false },
  FloatTitle = { fg = "ACCENT", bg = false },
  Cursor = { fg = "BG", bg = "ACCENT" },
  lCursor = { fg = "BG", bg = "ACCENT" },
  CursorIM = { fg = "BG", bg = "ACCENT" },
  TermCursor = { fg = "BG", bg = "ACCENT" },
  TermCursorNC = { fg = "MUTED" },
  CursorLine = { bg = "soft" },
  CursorColumn = { bg = "soft" },
  ColorColumn = { bg = "soft" },
  CursorLineNr = { fg = "YELLOW", bold = true },
  LineNr = { fg = "MUTED" },
  LineNrAbove = { fg = "MUTED" },
  LineNrBelow = { fg = "MUTED" },
  SignColumn = { bg = false },
  FoldColumn = { fg = "MUTED", bg = false },
  Folded = { fg = "MUTED", bg = "soft" },
  WinSeparator = { fg = "sel" },
  VertSplit = { fg = "sel" },
  StatusLine = { fg = "FG", bg = "sel" },
  StatusLineNC = { fg = "MUTED", bg = "soft" },
  WinBar = { fg = "MUTED", bg = false },
  WinBarNC = { fg = "MUTED", bg = false },
  TabLine = { fg = "MUTED", bg = "soft" },
  TabLineFill = { bg = false },
  TabLineSel = { fg = "ACCENT", bold = true, bg = false },
  Pmenu = { fg = "FG", bg = "soft" },
  PmenuSel = { fg = "BG", bg = "ACCENT" },
  PmenuKind = { fg = "ACCENT", bg = "soft" },
  PmenuKindSel = { fg = "BG", bg = "ACCENT" },
  PmenuExtra = { fg = "MUTED", bg = "soft" },
  PmenuExtraSel = { fg = "BG", bg = "ACCENT" },
  PmenuSbar = { bg = "sel" },
  PmenuThumb = { bg = "MUTED" },
  Visual = { bg = "sel" },
  VisualNOS = { bg = "sel" },
  Search = { fg = "BG", bg = "YELLOW" },
  CurSearch = { fg = "BG", bg = "PINK", bold = true },
  IncSearch = { fg = "BG", bg = "ACCENT" },
  MatchParen = { fg = "PINK", bold = true },
  Conceal = { fg = "MUTED" },
  NonText = { fg = "MUTED" },
  Whitespace = { fg = "sel" },
  SpecialKey = { fg = "MUTED" },
  EndOfBuffer = { fg = false },
  Directory = { fg = "ACCENT" },
  Title = { fg = "ACCENT", bold = true },
  MsgArea = { fg = "FG" },
  MsgSeparator = { fg = "sel", bg = "soft" },
  MoreMsg = { fg = "ACCENT" },
  Question = { fg = "GREEN" },
  ModeMsg = { fg = "FG", bold = true },
  ErrorMsg = { fg = "RED" },
  WarningMsg = { fg = "YELLOW" },
  QuickFixLine = { bg = "sel", bold = true },
  WildMenu = { link = "PmenuSel" },

  -- Diff (the old colorscheme spec set these from a VimEnter autocmd)
  DiffAdd = { fg = "GREEN", bg = "add" },
  DiffChange = { fg = "YELLOW", bg = "change" },
  DiffDelete = { fg = "RED", bg = "delete" },
  DiffText = { fg = "YELLOW", bg = "text", bold = true },
  Added = { fg = "GREEN", bg = "add" },
  Changed = { fg = "YELLOW", bg = "change" },
  Removed = { fg = "RED", bg = "delete" },

  -- Diagnostics
  DiagnosticError = { fg = "RED" },
  DiagnosticWarn = { fg = "YELLOW" },
  DiagnosticInfo = { fg = "ACCENT" },
  DiagnosticHint = { fg = "CYAN" },
  DiagnosticOk = { fg = "GREEN" },
  DiagnosticSignError = { link = "DiagnosticError" },
  DiagnosticSignWarn = { link = "DiagnosticWarn" },
  DiagnosticSignInfo = { link = "DiagnosticInfo" },
  DiagnosticSignHint = { link = "DiagnosticHint" },
  DiagnosticSignOk = { link = "DiagnosticOk" },
  DiagnosticVirtualTextError = { fg = "RED", bg = "delete" },
  DiagnosticVirtualTextWarn = { fg = "YELLOW", bg = "change" },
  DiagnosticVirtualTextInfo = { fg = "ACCENT", bg = "sel" },
  DiagnosticVirtualTextHint = { fg = "CYAN", bg = "sel" },
  DiagnosticVirtualTextOk = { fg = "GREEN", bg = "add" },
  DiagnosticUnderlineError = { sp = "RED", undercurl = true },
  DiagnosticUnderlineWarn = { sp = "YELLOW", undercurl = true },
  DiagnosticUnderlineInfo = { sp = "ACCENT", undercurl = true },
  DiagnosticUnderlineHint = { sp = "CYAN", undercurl = true },
  DiagnosticUnderlineOk = { sp = "GREEN", undercurl = true },
  DiagnosticFloatingError = { fg = "RED", bg = "soft" },
  DiagnosticFloatingWarn = { fg = "YELLOW", bg = "soft" },
  DiagnosticFloatingInfo = { fg = "ACCENT", bg = "soft" },
  DiagnosticFloatingHint = { fg = "CYAN", bg = "soft" },
  DiagnosticFloatingOk = { fg = "GREEN", bg = "soft" },
  DiagnosticUnnecessary = { fg = "MUTED" },
  DiagnosticDeprecated = { fg = "MUTED", strikethrough = true },

  -- LSP
  LspReferenceText = { bg = "sel" },
  LspReferenceRead = { bg = "sel" },
  LspReferenceWrite = { bg = "sel", underline = true },
  LspSignatureActiveParameter = { fg = "ACCENT", bold = true },
  LspCodeLens = { fg = "MUTED" },
  LspCodeLensSeparator = { fg = "sel" },

  -- Syntax
  Comment = { fg = "MUTED" },
  Constant = { fg = "YELLOW" },
  String = { fg = "GREEN" },
  Character = { fg = "GREEN" },
  Number = { fg = "YELLOW" },
  Boolean = { fg = "YELLOW" },
  Float = { fg = "YELLOW" },
  Identifier = { fg = "FG" },
  Function = { fg = "ACCENT" },
  Statement = { fg = "PINK" },
  Conditional = { fg = "PINK" },
  Repeat = { fg = "PINK" },
  Label = { fg = "PINK" },
  Operator = { fg = "CYAN" },
  Keyword = { fg = "PINK" },
  Exception = { fg = "PINK" },
  PreProc = { fg = "CYAN" },
  Include = { fg = "CYAN" },
  Define = { fg = "CYAN" },
  Macro = { fg = "CYAN" },
  PreCondit = { fg = "CYAN" },
  Type = { fg = "CYAN" },
  StorageClass = { fg = "CYAN" },
  Structure = { fg = "CYAN" },
  Typedef = { fg = "CYAN" },
  Special = { fg = "ACCENT" },
  SpecialChar = { fg = "YELLOW" },
  Tag = { fg = "PINK" },
  Delimiter = { fg = "FG" },
  SpecialComment = { fg = "MUTED" },
  Debug = { fg = "YELLOW" },
  Underlined = { underline = true },
  Ignore = { fg = "MUTED" },
  Error = { fg = "RED" },
  Todo = { fg = "BG", bg = "YELLOW", bold = true },

  -- Treesitter captures
  ["@variable"] = { fg = "FG" },
  ["@variable.builtin"] = { fg = "PINK" },
  ["@variable.parameter"] = { fg = "FG" },
  ["@variable.member"] = { fg = "CYAN" },
  ["@constant"] = { fg = "YELLOW" },
  ["@constant.builtin"] = { fg = "YELLOW" },
  ["@constant.macro"] = { fg = "CYAN" },
  ["@module"] = { fg = "CYAN" },
  ["@string"] = { fg = "GREEN" },
  ["@string.escape"] = { fg = "PINK" },
  ["@string.regexp"] = { fg = "CYAN" },
  ["@string.special"] = { fg = "CYAN" },
  ["@character"] = { fg = "GREEN" },
  ["@character.special"] = { fg = "PINK" },
  ["@number"] = { fg = "YELLOW" },
  ["@boolean"] = { fg = "YELLOW" },
  ["@function"] = { fg = "ACCENT" },
  ["@function.builtin"] = { fg = "ACCENT" },
  ["@function.call"] = { fg = "ACCENT" },
  ["@function.macro"] = { fg = "CYAN" },
  ["@constructor"] = { fg = "PINK" },
  ["@operator"] = { fg = "CYAN" },
  ["@keyword"] = { fg = "PINK" },
  ["@keyword.function"] = { fg = "PINK" },
  ["@keyword.return"] = { fg = "PINK" },
  ["@keyword.operator"] = { fg = "CYAN" },
  ["@conditional"] = { fg = "PINK" },
  ["@repeat"] = { fg = "PINK" },
  ["@exception"] = { fg = "PINK" },
  ["@include"] = { fg = "CYAN" },
  ["@define"] = { fg = "CYAN" },
  ["@type"] = { fg = "CYAN" },
  ["@type.builtin"] = { fg = "CYAN" },
  ["@type.qualifier"] = { fg = "PINK" },
  ["@storageclass"] = { fg = "CYAN" },
  ["@attribute"] = { fg = "CYAN" },
  ["@property"] = { fg = "CYAN" },
  ["@field"] = { fg = "CYAN" },
  ["@parameter"] = { fg = "FG" },
  ["@label"] = { fg = "PINK" },
  ["@namespace"] = { fg = "CYAN" },
  ["@punctuation.delimiter"] = { fg = "FG" },
  ["@punctuation.bracket"] = { fg = "FG" },
  ["@punctuation.special"] = { fg = "CYAN" },
  ["@comment"] = { fg = "MUTED" },
  ["@comment.documentation"] = { fg = "MUTED" },
  ["@comment.error"] = { fg = "BG", bg = "RED", bold = true },
  ["@comment.warning"] = { fg = "BG", bg = "YELLOW", bold = true },
  ["@comment.todo"] = { fg = "BG", bg = "ACCENT", bold = true },
  ["@comment.note"] = { fg = "BG", bg = "CYAN", bold = true },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.underline"] = { underline = true },
  ["@markup.heading"] = { fg = "ACCENT", bold = true },
  ["@markup.quote"] = { fg = "MUTED" },
  ["@markup.math"] = { fg = "CYAN" },
  ["@markup.link"] = { fg = "CYAN" },
  ["@markup.link.label"] = { fg = "ACCENT" },
  ["@markup.link.url"] = { fg = "CYAN", underline = true },
  ["@markup.raw"] = { fg = "GREEN" },
  ["@markup.raw.block"] = { fg = "GREEN" },
  ["@markup.list"] = { fg = "CYAN" },
  ["@markup.list.checked"] = { fg = "GREEN" },
  ["@markup.list.unchecked"] = { fg = "MUTED" },
  ["@tag"] = { fg = "PINK" },
  ["@tag.attribute"] = { fg = "CYAN" },
  ["@tag.delimiter"] = { fg = "FG" },
  ["@diff.plus"] = { link = "DiffAdd" },
  ["@diff.minus"] = { link = "DiffDelete" },
  ["@diff.delta"] = { link = "DiffChange" },

  -- rainbow-delimiters defines these with `default = true` on VeryLazy, so our
  -- values have to be set here to survive it loading.
  RainbowDelimiterRed = { fg = "RED" },
  RainbowDelimiterOrange = { fg = "orange" },
  RainbowDelimiterYellow = { fg = "YELLOW" },
  RainbowDelimiterGreen = { fg = "GREEN" },
  RainbowDelimiterBlue = { fg = "ACCENT" },
  RainbowDelimiterViolet = { fg = "PINK" },
  RainbowDelimiterCyan = { fg = "CYAN" },

  -- The two nvim-tree groups that do not link to a standard group.
  NvimTreeFolderIcon = { fg = "ACCENT" },
  NvimTreeWindowPicker = { fg = "BG", bg = "ACCENT", bold = true },

  -- nvim-notify's default background_colour: it needs a group with a real bg
  -- for its fade stages, and warns at startup (once per session) when the
  -- group is undefined. The terminal background shows through Normal, so use
  -- the theme's own BG for the composited colour.
  NotifyBackground = { bg = "BG" },

  -- Help and health
  helpSpecial = { fg = "CYAN" },
  helpHyperTextJump = { fg = "ACCENT", underline = true },
  helpCommand = { fg = "GREEN" },
  helpExample = { fg = "MUTED" },
  helpHeader = { fg = "PINK", bold = true },
  helpOption = { fg = "CYAN" },
  helpVim = { fg = "PINK" },
  healthError = { fg = "RED" },
  healthWarning = { fg = "YELLOW" },
  healthSuccess = { fg = "GREEN" },
  healthHelp = { fg = "MUTED" },
}

--- Set every highlight, the terminal colours and the scheme name, then tell the
--- plugins that inherit from us (lualine, cmp, telescope, noice) to re-read.
function M.apply()
  for group, spec in pairs(MAP) do
    vim.api.nvim_set_hl(0, group, expand(spec))
  end
  for i, role in ipairs(ANSI_ORDER) do
    vim.g["terminal_color_" .. (i - 1)] = C[role]
  end
  vim.o.background = "dark"
  vim.g.colors_name = scheme
  vim.api.nvim_exec_autocmds("ColorScheme", {})
end

--- lualine theme table, built from the same palette. Passed as a function so
--- lualine re-evaluates it on every ColorScheme.
function M.lualine()
  local function mode(accent)
    return {
      a = { fg = C.BG, bg = accent },
      b = { fg = C.FG, bg = C.sel },
      c = { fg = C.MUTED, bg = C.soft },
    }
  end
  return {
    normal = mode(C.ACCENT),
    insert = mode(C.GREEN),
    visual = mode(C.PINK),
    replace = mode(C.RED),
    command = mode(C.YELLOW),
    inactive = {
      a = { fg = C.MUTED, bg = C.soft },
      b = { fg = C.MUTED, bg = C.soft },
      c = { fg = C.MUTED, bg = C.soft },
    },
  }
end

--- Pick a scheme from inside nvim (`:colorscheme <name>`, or directly). The
--- picker script does the repointing and the tmux/pi/WezTerm/WSL sync, so this
--- stays a second front end to that one implementation; our own restyle arrives
--- via the watcher noticing the symlink swap.
function M.switch(name)
  if not uv.fs_stat(ROOT .. "/" .. name) then
    return vim.notify("No such colorscheme: " .. name, vim.log.levels.ERROR)
  end
  if not uv.fs_stat(PICKER) then
    return vim.notify("Colorscheme picker not found: " .. PICKER, vim.log.levels.ERROR)
  end
  -- Through bash, exactly as the tmux binds and the .zshrc gate call it: chezmoi
  -- deploys this directory's scripts without an exec bit (664 on disk whatever
  -- the source's own mode - three siblings are 755 in git and still land 664),
  -- so executing the path directly fails with E475.
  vim.fn.system({ "bash", PICKER, name })
  if vim.v.shell_error ~= 0 then
    vim.notify("Colorscheme switch failed: " .. name, vim.log.levels.ERROR)
  end
end

-- Regenerate one colors/<name>.lua stub per theme so the built-in
-- `:colorscheme` works and `:colorscheme <Tab>` lists the shared names - nvim
-- refuses lowercase user commands and only completes from real colors/ files.
-- Rewritten whenever the content differs, so added or removed themes follow.
-- stdpath("state") is what goes on the runtimepath (<rtp>/colors/<name>.lua is
-- the layout nvim scans), not the colors/ directory itself.
pcall(function()
  local state = vim.fn.stdpath("state")
  local stubs = state .. "/colors"
  vim.fn.mkdir(stubs, "p")
  for _, dir in ipairs(vim.fn.glob(ROOT .. "/*", false, true)) do
    local name = vim.fn.fnamemodify(dir, ":t")
    if vim.fn.isdirectory(dir) == 1 and name ~= "current" then
      local path = stubs .. "/" .. name .. ".lua"
      local line = 'require("core.palette").switch("' .. name .. '")\n'
      local fd = io.open(path, "r")
      local current = fd and fd:read("*a")
      if fd then
        fd:close()
      end
      if current ~= line then
        local out = io.open(path, "w")
        if out then
          out:write(line)
          out:close()
        end
      end
    end
  end
  vim.opt.runtimepath:prepend(state)
end)

-- Live reload: a picked scheme is just the `current` symlink moving, so poll it
-- (and colors.sh's mtime) rather than hooking the picker. pcall because a tick
-- can land mid-switch, when the target is briefly unresolvable.
local last = snapshot()
local timer = uv.new_timer()
timer:start(2000, 2000, vim.schedule_wrap(function()
  pcall(function()
    local now = snapshot()
    if now ~= last then
      last = now
      C, scheme = load()
      M.apply()
    end
  end)
end))

return M
