-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The css module.
-- It provides utilities for editing CSS code.
-- User tags are loaded from _USERHOME/modules/css/tags and user apis are loaded
-- from _USERHOME/modules/css/api.
module('_M.css')]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `:`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
--
-- ## Fields
--
-- * `sense`: The CSS [Adeptsense](_M.textadept.adeptsense.html).

---
-- Sets default buffer properties for CSS files.
-- @name set_buffer_properties
function M.set_buffer_properties()
  buffer.word_chars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-'
end

-- Adeptsense.

M.sense = _M.textadept.adeptsense.new('css')
M.sense.ctags_kinds = {
  s = 'classes', p = 'classes', v = 'fields', S = 'functions', m = 'fields',
  c = 'fields'
}
M.sense:load_ctags(_HOME..'/modules/css/tags', true)
M.sense.syntax.word_chars = '%w-'
M.sense.syntax.symbol_chars = '[%w-]'
M.sense.api_files = { _HOME..'/modules/css/api' }
M.sense:add_trigger(':')
M.sense:add_trigger(': ')
M.sense.always_show_globals = false

-- Returns a full symbol (if any) and current symbol part (if any) behind the
-- caret.
function M.sense:get_symbol()
  local line, p = buffer:get_cur_line()
  local symbol, part = line:sub(1, p):match('([%w-]-):([%w-]*)$')
  if not symbol then part = line:sub(1, p):match('([%w-]*)$') end
  return symbol or '', part or ''
end

local selector_match = '}[^{]*$'
local property_match = '{[^}]*$'
local value_match = '([%w-]+):[^;{]*$'

-- Returns the class name for the given symbol.
-- If the symbol is the empty string, determine if a symbol at the caret would
-- be either a selector or property. Selectors are outside of {}s and
-- properties are within them.
-- @param symbol The symbol to get the class of.
function M.sense:get_class(symbol)
  if symbol ~= '' then return symbol end
  local buffer = buffer
  local line, p = buffer:get_cur_line()
  line = line:sub(1, p)
  local property = line:match(value_match)
  if property then return property end
  if line:find(property_match) then
    return 'property'
  elseif line:find(selector_match) then
    return 'selector'
  end
  for i = buffer:line_from_position(buffer.current_pos) - 1, 0, -1 do
    line = buffer:get_line(i)
    if line:find(property_match) then
      return 'property'
    elseif line:find(selector_match) then
      return 'selector'
    end
  end
  return 'selector'
end

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/css/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/css/tags')
end
if lfs.attributes(_USERHOME..'/modules/css/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/css/api'
end

-- Commands.

---
-- Container for CSS-specific key commands.
-- @class table
-- @name _G.keys.css
keys.css = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = { io.open_file,
          (_HOME..'/modules/css/init.lua'):iconv('UTF-8', _CHARSET) },
  },
}

-- Snippets.

if type(snippets) == 'table' then
---
-- Container for CSS-specific snippets.
-- @class table
-- @name _G.snippets.css
  snippets.css = {

  }
end

return M
