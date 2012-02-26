-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The php module.
-- It provides utilities for editing PHP code.
-- User tags are loaded from _USERHOME/modules/php/tags and user apis are loaded
-- from _USERHOME/modules/php/api.
module('_M.php')]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `->`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `::`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `Shift+Return`: Add ';' to line end and insert newline.
--
-- ## Fields
--
-- * `sense`: The PHP [Adeptsense](_M.textadept.adeptsense.html).

-- Comment string tables use lexer names.
_M.textadept.editing.comment_string.php = '//'

---
-- Sets default buffer properties for PHP files.
-- @name set_buffer_properties
function M.set_buffer_properties()

end

-- Adeptsense.

M.sense = _M.textadept.adeptsense.new('php')
M.sense.syntax.symbol_chars = '[%w_%->:]'
M.sense.ctags_kinds = {
  c = 'classes', i = 'classes', d = 'fields', f = 'functions', j = 'functions',
  v = 'fields'
}
M.sense:load_ctags(_HOME..'/modules/php/tags', true)
M.sense.api_files = { _HOME..'/modules/php/api' }
M.sense.syntax.type_declarations = {}
M.sense:add_trigger('->')
M.sense:add_trigger('::')

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/php/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/php/tags')
end
if lfs.attributes(_USERHOME..'/modules/php/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/php/api'
end

-- Commands.

---
-- Determines the PHP file being 'require'd or 'include'd, and opens it in
-- Textadept.
-- @name goto_required
function M.goto_required()
  local line = buffer:get_cur_line()
  local patterns = {
    'require%s*(%b())', 'require%s*(([\'"])[^%2]+%2)',
    'require_once%s*(%b())', 'require_once%s*(([\'"])[^%2]+%2)',
    'include%s*(%b())', 'include%s*(([\'"])[^%2]+%2)',
    'include_once%s*(%b())', 'include_once%s*(([\'"])[^%2]+%2)',
  }
  local file
  for _, patt in ipairs(patterns) do
    file = line:match(patt)
    if file then break end
  end
  if not (file and buffer.filename) then return end
  file = file:sub(2, -2)
  local path = buffer.filename:match('^.+[/\\]')..file
  if lfs.attributes(path) then io.open_file(path:iconv('UTF-8', _CHARSET)) end
end

-- Show syntax errors as annotations.
events.connect(events.FILE_AFTER_SAVE, function()
  if buffer:get_lexer() == 'php' then
    local buffer = buffer
    buffer:annotation_clear_all()
    local p = io.popen('php -l "'..buffer.filename..'" -f 2>&1')
    local out = p:read('*all')
    p:close()
    if not out:match('^No syntax errors') then
      local filename = buffer.filename:gsub('([%.+*%(%)%[%]-])', '%%%1')
      local err_msg, line = out:match('^PHP (.-) in '..
                                      filename..' on line (%d+)')
      if line then
        buffer.annotation_visible = 2
        buffer:annotation_set_text(line - 1, err_msg)
        buffer.annotation_style[line - 1] = 8 -- error style number
        buffer:goto_line(line - 1)
      end
    end
  end
end)

---
-- Container for PHP-specific key commands.
-- @class table
-- @name _G.keys.php
keys.php = {
  al = {
    m = { io.open_file,
          (_HOME..'/modules/php/init.lua'):iconv('UTF-8', _CHARSET) },
    g = M.goto_required,
  },
  ['s\n'] = function()
    buffer:line_end()
    buffer:add_text(';')
    buffer:new_line()
  end,
}

-- Snippets.

---
-- Container for PHP-specific snippets.
-- @class table
-- @name _G.snippets.php
if type(snippets) == 'table' then
  snippets.php = {

  }
end

return M
