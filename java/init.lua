-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The java module.
-- It provides utilities for editing Java code.
-- User tags are loaded from _USERHOME/modules/java/tags and user apis are
-- loaded from _USERHOME/modules/java/api.
module('_M.java')]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `Ctrl+L, G, C` (`⌘L, G, C`): Open filtered list to jump to a known class.
-- + `Ctrl+L, G, I` (`⌘L, G, I`): Open filtered list to jump to a known
--   interface.
-- + `Ctrl+L, G, M` (`⌘L, G, M`): Open filtered list to jump to a known method.
-- + `Ctrl+L, G, F` (`⌘L, G, F`): Open filtered list to jump to a known field.
-- + `.`: When to the right of a known identifier, show an autocompletion list
--   of methods, fields, and packages.
--
-- ## Fields
--
-- * `sense`: The Java [Adeptsense](_M.textadept.adeptsense.html).

local m_editing, m_run = _M.textadept.editing, _M.textadept.run
-- Comment string tables use lexer names.
m_editing.comment_string.java = '//'
-- Compile and Run command tables use file extensions.
m_run.compile_command.java = 'javac "%(filename)"'
m_run.run_command.java = function()
  local buffer = buffer
  local text = buffer:get_text()
  local s, e, package
  repeat
    s, e, package = text:find('package%s+([^;]+)', e or 1)
  until not s or buffer:get_style_name(buffer.style_at[s]) ~= 'comment'
  if package then
    local classpath = ''
    for dot in package:gmatch('%.') do classpath = classpath..'../' end
    return 'java -cp '..(WIN32 and '%CLASSPATH%;' or '$CLASSPATH:')..
      classpath..'../ '..package..'.%(filename_noext)'
  else
    return 'java %(filename_noext)'
  end
end

---
-- Sets default buffer properties for Java files.
-- @name set_buffer_properties
function M.set_buffer_properties()

end

-- Adeptsense.

M.sense = _M.textadept.adeptsense.new('java')
M.sense.ctags_kinds = {
  c = 'classes', f = 'fields', i = 'classes', m = 'functions'
}
M.sense.api_files = { _HOME..'/modules/java/api' }
M.sense.syntax.type_declarations = {
  '(%u[%w_%.]+)%s+%_', -- Foo bar
  '(%u[%w_%.]+)%b<>%s+%_', -- List<Foo> bar
}
M.sense:add_trigger('.')

-- Add packages to an import table for autocompletion.
function M.sense:handle_ctag(tag_name, file_name, ex_cmd, ext_fields)
  if ext_fields:sub(1, 1) ~= 'p' then return end -- not a package
  if not self.imports then self.imports = {} end
  local import = self.imports
  for package in tag_name:gmatch('[^.]+') do
    if not import[package] then import[package] = {} end
    import = import[package]
  end
  import[#import + 1] = file_name:match('([^/\\]-)%.java$')
end
M.sense:load_ctags(_HOME..'/modules/java/tags', true)

-- Attempt to get completions for an 'import' statement before falling back on
-- the default get_completions().
function M.sense:get_completions(symbol, only_fields, only_funcs)
  if not buffer:get_cur_line():find('^%s*import') then
    return self.super.get_completions(self, symbol, only_fields, only_funcs)
  end
  if symbol == 'import' then symbol = '' end -- top-level import
  local c = {}
  local import = self.imports or {}
  for package in symbol:gmatch('[^%.]+') do
    if not import[package] then return nil end
    import = import[package]
  end
  for k, v in pairs(import) do
    c[#c + 1] = type(v) == 'table' and k..'?1' or v..'?2'
  end
  table.sort(c)
  return c
end

-- Clear imports table.
function M.sense:handle_clear()
  self.imports = {}
end

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/java/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/java/tags')
end
if lfs.attributes(_USERHOME..'/modules/java/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/java/api'
end

-- Commands.

---
-- Container for Java-specific key commands.
-- @class table
-- @name _G.keys.java
keys.java = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = { io.open_file,
          (_HOME..'/modules/java/init.lua'):iconv('UTF-8', _CHARSET) },
    g = {
      c = { M.sense.goto_ctag, M.sense, 'c', 'Classes' },
      i = { M.sense.goto_ctag, M.sense, 'i', 'Interfaces' },
      m = { M.sense.goto_ctag, M.sense, 'm', 'Methods' },
      f = { M.sense.goto_ctag, M.sense, 'f', 'Fields' },
    },
  },
}

-- Snippets.

if type(snippets) == 'table' then
---
-- Container for Java-specific snippets.
-- @class table
-- @name _G.snippets.java
  snippets.java = {

  }
end

return M
