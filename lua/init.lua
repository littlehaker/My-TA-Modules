-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The lua module.
-- It provides utilities for editing Lua code.
-- User tags are loaded from _USERHOME/modules/lua/tags and user apis are loaded
-- from _USERHOME/modules/lua/api.
module('_M.lua')]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `Ctrl+L, G` (`⌘L, G`): Goto file being 'require'd on the current line.
-- + `Shift+Return` (`⇧↩`): Try to autocomplete an `if`, `for`, etc. statement
--   with `end`.
-- + `.`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `:`: When to the right of a known symbol, show an autocompletion list of
--   functions only.
--
-- ## Fields
--
-- * `sense`: The Lua [Adeptsense](_M.textadept.adeptsense.html).

local m_editing, m_run = _M.textadept.editing, _M.textadept.run
-- Comment string tables use lexer names.
m_editing.comment_string.lua = '--'
-- Compile and Run command tables use file extensions.
m_run.run_command.lua = 'lua %(filename)'
m_run.error_detail.lua = {
  pattern = '^lua: (.-):(%d+): (.+)$',
  filename = 1, line = 2, message = 3
}

---
-- Sets default buffer properties for Lua files.
-- @name set_buffer_properties
function M.set_buffer_properties()

end

-- Adeptsense.

M.sense = _M.textadept.adeptsense.new('lua')
M.sense.syntax.class_definition = 'module%s*%(?%s*[\'"]([%w_%.]+)'
M.sense.syntax.symbol_chars = '[%w_%.:]'
M.sense.syntax.type_declarations = {}
M.sense.syntax.type_assignments = {
  ['^[\'"]'] = 'string', -- foo = 'bar' or foo = "bar"
  ['^([%w_%.]+)%s*$'] = '%1', -- foo = _M.textadept.adeptsense
  ['^(_M%.textadept%.adeptsense)%.new'] = '%1',
  ['require%s*%(?%s*(["\'])([%w_%.]+)%1%)?'] = '%2',
  ['^io%.p?open%s*%b()%s*$'] = 'file'
}
M.sense.api_files = { _HOME..'/modules/lua/api' }
M.sense:add_trigger('.')
M.sense:add_trigger(':', false, true)

-- script/update_doc generates a fake set of ctags used for autocompletion.
M.sense.ctags_kinds = {
  f = 'functions', F = 'fields', m = 'classes', t = 'fields'
}
M.sense:load_ctags(_HOME..'/modules/lua/tags', true)

-- Strips '_G' from symbols since it's implied.
function M.sense:get_symbol()
  local symbol, part = self.super.get_symbol(self)
  if symbol:find('^_G') then symbol = symbol:gsub('_G%.?', '') end
  if part == '_G' then part = '' end
  return symbol, part
end

-- Shows an autocompletion list for the symbol behind the caret.
-- If the symbol contains a ':', only display functions. Otherwise, display
-- both functions and fields.
function M.sense:complete(only_fields, only_functions)
  local line, pos = buffer:get_cur_line()
  local symbol = line:sub(1, pos):match(self.syntax.symbol_chars..'*$')
  return self.super.complete(self, false, symbol:find(':'))
end

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/lua/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/lua/tags')
end
if lfs.attributes(_USERHOME..'/modules/lua/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/lua/api'
end

-- Commands.

---
-- Patterns for auto 'end' completion for control structures.
-- @class table
-- @name control_structure_patterns
-- @see try_to_autocomplete_end
local control_structure_patterns = {
  '^%s*for', '^%s*function', '^%s*if', '^%s*repeat', '^%s*while',
  'function%s*%b()%s*$', '^%s*local%s*function'
}

---
-- Tries to autocomplete Lua's 'end' keyword for control structures like 'if',
-- 'while', 'for', etc.
-- @see control_structure_patterns
-- @name try_to_autocomplete_end
function M.try_to_autocomplete_end()
  local buffer = buffer
  local line_num = buffer:line_from_position(buffer.current_pos)
  local line = buffer:get_line(line_num)
  local line_indentation = buffer.line_indentation
  for _, patt in ipairs(control_structure_patterns) do
    if line:find(patt) then
      local indent = line_indentation[line_num]
      buffer:begin_undo_action()
      buffer:new_line()
      buffer:new_line()
      buffer:add_text(patt:find('repeat') and 'until' or 'end')
      line_indentation[line_num + 1] = indent + buffer.indent
      buffer:line_up()
      buffer:line_end()
      buffer:end_undo_action()
      return true
    end
  end
  return false
end

---
-- Determines the Lua file being 'require'd, searches through package.path for
-- that file, and opens it in Textadept.
-- @name goto_required
function M.goto_required()
  local line = buffer:get_cur_line()
  local patterns = { 'require%s*(%b())', 'require%s*(([\'"])[^%2]+%2)' }
  local file
  for _, patt in ipairs(patterns) do
    file = line:match(patt)
    if file then break end
  end
  if not file then return end
  file = package.searchpath(file:sub(2, -2):iconv('UTF-8', _CHARSET),
                            package.path)
  if file then io.open_file(file) end
end

-- Show syntax errors as annotations.
events.connect(events.FILE_AFTER_SAVE, function()
  if buffer:get_lexer() ~= 'lua' then return end
  local buffer = buffer
  buffer:annotation_clear_all()
  local text = buffer:get_text():gsub('^#![^\n]+', '') -- ignore shebang line
  local f, err = load(text)
  if f then return end
  local line, msg = err:match('^.-:(%d+):%s*(.+)$')
  if line then
    buffer.annotation_visible = 2
    buffer:annotation_set_text(line - 1, msg)
    buffer.annotation_style[line - 1] = 8 -- error style number
    buffer:goto_line(line - 1)
  end
end)

---
-- Container for Lua-specific key commands.
-- @class table
-- @name _G.keys.lua
keys.lua = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = { io.open_file,
          (_HOME..'/modules/lua/init.lua'):iconv('UTF-8', _CHARSET) },
    g = M.goto_required,
  },
  ['s\n'] = M.try_to_autocomplete_end,
}

-- Snippets.

if type(snippets) == 'table' then
---
-- Container for Lua-specific snippets.
-- @class table
-- @name _G.snippets.lua
  snippets.lua = {
    l = "local %1(expr)%2( = %3(value))",
    p = "print(%0)",
    f = "function %1(name)(%2(args))\n\t%0\nend",
    ['for'] = "for i = %1(1), %2(10)%3(, -1) do\n\t%0\nend",
    fori = "for %1(i), %2(val) in ipairs(%3(table)) do\n\t%0\nend",
    forp = "for %1(k), %2(v) in pairs(%3(table)) do\n\t%0\nend",
    ['if'] = "if %1(condition) then %2(statement) end"
  }
end

return M
