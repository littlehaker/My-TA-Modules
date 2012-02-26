-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The hypertext module.
-- It provides utilities for editing HTML code.
-- User tags are loaded from _USERHOME/modules/hypertext/tags and user apis are
-- loaded from _USERHOME/modules/hypertext/api.
module('_M.hypertext')]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `<`: show an autocompletion list of tags.
--
-- ## Fields
--
-- * `sense`: The HTML [Adeptsense](_M.textadept.adeptsense.html).

-- Load CSS Adeptsense.
if not _M.css then _M.css = require 'css' end

---
-- Sets default buffer properties for HTML files.
-- @name set_buffer_properties
function M.set_buffer_properties()
  buffer.word_chars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-'
end

-- Adeptsense.

M.sense = _M.textadept.adeptsense.new('hypertext')
M.sense.ctags_kinds = { t = 'classes', a = 'fields', e = 'functions' }
M.sense:load_ctags(_HOME..'/modules/hypertext/tags', true)
M.sense.syntax.word_chars = '%w-'
M.sense.syntax.symbol_chars = '[%w-]'
M.sense.api_files = { _HOME..'/modules/hypertext/api' }
M.sense:add_trigger('<')

-- Returns a full symbol (if any) and current symbol part (if any) behind the
-- caret.
function M.sense:get_symbol()
  local line, p = buffer:get_cur_line()
  local symbol, part = line:sub(1, p):match('<(%w*)[^<>]-([%w:]*)$')
  if symbol and not self.completions[symbol] then symbol, part = '', symbol end
  return symbol or '', part or ''
end

-- Shows a calltip with API documentation for the selected symbol or the symbol
-- at the caret.
-- @param symbol The symbol to get the apidoc for.
function M.sense:get_apidoc(symbol)
  local buffer = buffer
  local s, e = buffer.selection_start, buffer.selection_end
  if s == e then
    s = buffer:word_start_position(s, true)
    e = buffer:word_end_position(s, true)
  end
  symbol = buffer:text_range(s, e)
  if not symbol then return nil end
  local line, p = buffer:get_cur_line()
  local tag = line:sub(1, p):match('<(%w+)%s+[^<>]*$')
  if tag then symbol = tag..'.'..symbol end
  return self.super.get_apidoc(self, symbol)
end

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/hypertext/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/hypertext/tags')
end
if lfs.attributes(_USERHOME..'/modules/hypertext/api') then
  local api_files = M.sense.api_files
  api_files[#api_files + 1] = _USERHOME..'/modules/hypertext/api'
end

-- Commands.

---
-- Container for HTML-specific key commands.
-- @class table
-- @name _G.keys.hypertext
keys.hypertext = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = { io.open_file,
          (_HOME..'/modules/hypertext/init.lua'):iconv('UTF-8', _CHARSET) },
  },
}

-- Snippets.

if type(snippets) == 'table' then
---
-- Container for HTML-specific snippets.
-- @class table
-- @name _G.snippets.hypertext
  snippets.hypertext = {
    c = '<!-- %0 -->',
    ['<'] = '<%1(div)>\n\t%0\n</%1>',
    divc = '<div class="%1">\n\t%0\n</div>',
    divi = '<div id="%1">\n\t%0\n</div>',
    br = '<br />\n%0',
    table = '<table class="%1">\n\t<tr>\n\t\t<th>%0</th>\n\t</tr>\n</table>',
    td = '<td>%0</td>',
    tr = '<tr>\n\t%0\n</tr>',
    ulc = '<ul class="%1(list)">\n\t%0\n</ul>',
    ul = '<ul>\n\t%0\n</ul>',
    li = '<li>%0</li>',
  }
end

return M
