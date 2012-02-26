-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The ruby module.
-- It provides utilities for editing Ruby code.
-- User tags are loaded from _USERHOME/modules/ruby/tags and user apis are
-- loaded from _USERHOME/modules/ruby/api.
module('_M.ruby')]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `Ctrl+L, G` (`⌘L, G`): Goto file being 'require'd on the current line.
-- + `Shift+Return`: Try to autocomplete an `if`, `for`, etc. statement with
--   `end`.
-- + `.`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `::`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
--
-- ## Fields
--
-- * `sense`: The Ruby [Adeptsense](_M.textadept.adeptsense.html).

local m_editing, m_run = _M.textadept.editing, _M.textadept.run
-- Comment string tables use lexer names.
m_editing.comment_string.ruby = '#'
-- Compile and Run command tables use file extensions.
m_run.run_command.rb = 'ruby %(filename)'
m_run.error_detail.ruby = {
  pattern = '^(.-):(%d+): (.+)$',
  filename = 1, line = 2, message = 3
}

---
-- Sets default buffer properties for Ruby files.
-- @name set_buffer_properties
function M.set_buffer_properties()
  buffer.word_chars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_?!'
end

-- Adeptsense.

M.sense = _M.textadept.adeptsense.new('ruby')
M.sense.syntax.class_definition = '^%s*class%s+([%w_:]+)%s*<?%s*([%w_:]*)'
M.sense.syntax.word_chars = '%w_%?!'
M.sense.syntax.symbol_chars = '[%w_%.:%?!]'
M.sense.api_files = { _HOME..'/modules/ruby/api' }
M.sense.syntax.type_declarations = {
  '%_%s*=%s*([%w_:]+)%.new'
}
M.sense.syntax.type_assignments = {
  ['^[\'"]'] = 'String',
  ['^%['] = 'Array',
  ['^{'] = 'Hash',
  ['^/'] = 'Regexp',
  ['^:'] = 'Symbol',
}
M.sense:add_trigger('.')
M.sense:add_trigger('::')

-- Fake set of ctags used for autocompletion.
M.sense.ctags_kinds = {
  a = 'fields', c = 'classes', C = 'fields', f = 'functions', m = 'classes'
}
M.sense:load_ctags(_HOME..'/modules/ruby/tags', true)

local ALWAYS = function(inside) return true end -- for symbol_syntax

-- Map of symbols to their syntax definitions.
-- This is used for type inference (e.g. 'string' or [array]) when determining
-- a syntax pattern's class. Each key is the symbol name with a table value
-- whose keys are patt and condition. The patt key has a Lua pattern that
-- matches an instance of the symbol (e.g. a string or array literal) and has
-- 3 captures: starting delimiter, text between delimiters, and ending
-- delimiter. The condition key has a function that accepts a single parameter,
-- the text between delimiters, and returns true or false depending on whether
-- or not the matched pattern is an instance of a symbol.
-- @class table
-- @name symbol_syntax
local symbol_syntax = {
  String = { patt = '[^:]([\'"`])(.-)(%1)%s*%.([%w_]*)$', condition = ALWAYS },
  Array = { patt = '%s(%[)(.-)(%])%s*%.([%w_]*)$', condition = ALWAYS },
  Hash = { patt = '({)(.-)(})%s*%.([%w_]*)$', condition = function(inside)
             if inside:find('^%s*$') then return true end
             return inside:find('=>') or inside:find('[%w_]:')
           end },
  Regexp = { patt = '(/)(.-)(/)[iomx]*%s*%.([%w_]*)$', condition = ALWAYS },
  Symbol = { patt = ':([\'"]?)([%w_]+)(%1)%.([%w_]*)$', condition = ALWAYS },
}

-- Returns a full symbol (if any) and current symbol part (if any) behind the
-- caret.
-- Tries type inference (e.g. 'string'. or [array].) first before falling back
-- on the normal adeptense.get_symbol() method.
function M.sense:get_symbol()
  local line, p = buffer:get_cur_line()
  line = ' '..line:sub(1, p)
  for symbol, syntax in pairs(symbol_syntax) do
    local c1, inside, c2, part = line:match(syntax.patt)
    if c1 and c2 and syntax.condition(inside) then return symbol, part end
  end
  return self.super.get_symbol(self)
end

-- Returns the class name for a given symbol.
-- Tries the normal method based on sense.syntax.type_declarations before
-- falling back on method based on type inference (e.g. foo = 'string').
-- @param symbol The symbol to get the class of.
function M.sense:get_class(symbol)
  local class = self.super.get_class(self, symbol)
  if class then return class end
  -- Integers and Floats.
  if tonumber(symbol:match('^%d+%.?%d*$')) then
    return symbol:find('%.') and 'Float' or 'Integer'
  end
  -- Ranges.
  if symbol:match('^%d+%.%.%.?%d+$') then return 'Range' end
  return nil
end

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/ruby/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/ruby/tags')
end
if lfs.attributes(_USERHOME..'/modules/ruby/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/ruby/api'
end

-- Commands.

---
-- Patterns for auto 'end' completion for control structures.
-- @class table
-- @name control_structure_patterns
-- @see try_to_autocomplete_end
local control_structure_patterns = {
  '^%s*begin', '^%s*case', '^%s*class', '^%s*def', '^%s*for', '^%s*if',
  '^%s*module', '^%s*unless', '^%s*until', '^%s*while', 'do%s*|?.-|?%s*$'
}

---
-- Tries to autocomplete Ruby's 'end' keyword for control structures like 'if',
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
      buffer:add_text('end')
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
-- Determine the Ruby file being 'require'd, and search through the RUBYPATH
-- for that file and open it in Textadept.
-- @name goto_required
function M.goto_required()
  local line, _ = buffer:get_cur_line()
  local patterns = { 'require%s*(%b())', 'require%s*(([\'"])[^%2]+%2)' }
  local file
  for _, patt in ipairs(patterns) do
    file = line:match(patt)
    if file then break end
  end
  if not file then return end
  local command = 'ruby -e "puts $:"'
  local p = io.popen(command..' 2>&1')
  for path in p:lines() do
    path = path..'/'..file..'.rb'
    if lfs.attributes(path) then
      io.open_file(path:iconv('UTF-8', _CHARSET))
      break
    end
  end
  p:close()
end

-- Show syntax errors as annotations.
events.connect(events.FILE_AFTER_SAVE, function()
  if buffer:get_lexer() == 'ruby' then
    local buffer = buffer
    buffer:annotation_clear_all()
    local dir, filename =
      buffer.filename:iconv(_CHARSET, 'UTF-8'):match('^(.+[/\\])([^/\\]+)$')
    local p = io.popen('ruby -C"'..dir..'" -c "'..filename..'" 2>&1')
    local out = p:read('*all')
    p:close()
    if not out:match('^Syntax OK') then
      local line, err_msg = out:match('^[^:]+:(%d+): (.+)\r?\n$')
      if line then
        buffer.annotation_visible = 2
        buffer:annotation_set_text(line - 1, err_msg)
        buffer.annotation_style[line - 1] = 8 -- error style number
        buffer:goto_line(line - 1)
      end
    end
  end
end)

-- Contains newline sequences for buffer.eol_mode.
-- This table is used by toggle_block().
-- @class table
-- @name newlines
local newlines = { [0] = '\r\n', '\r', '\n' }

---
-- Toggles between { ... } and do ... end Ruby blocks.
-- If the caret is inside a { ... } single-line block, that block is converted
-- to a multiple-line do .. end block. If the caret is on a line that contains
-- single-line do ... end block, that block is converted to a single-line
-- { ... } block. If the caret is inside a multiple-line do ... end block, that
-- block is converted to a single-line { ... } block with all newlines replaced
-- by a space. Indentation is important. The 'do' and 'end' keywords must be on
-- lines with the same level of indentation to toggle correctly
-- @name toggle_block
function M.toggle_block()
  local buffer = buffer
  local pos = buffer.current_pos
  local line = buffer:line_from_position(pos)
  local e = buffer.line_end_position[line]
  local line_indentation = buffer.line_indentation

  -- Try to toggle from { ... } to do ... end.
  local char_at = buffer.char_at
  local p = pos
  while p < e do
    if char_at[p] == 125 then -- '}'
      local s = buffer:brace_match(p)
      if s >= 0 then
        local block = buffer:text_range(s + 1, p)
        local hash = false
        local s2, e2 = block:find('%b{}')
        if not s2 and not e2 then s2, e2 = #block, #block end
        local part1, part2 = block:sub(1, s2), block:sub(e2 + 1)
        hash = part1:find('=>') or part1:find('[%w_]:') or
               part2:find('=>') or part2:find('[%w_]:')
        if not hash then
          local newline = newlines[buffer.eol_mode]
          local block, r = block:gsub('^(%s*|[^|]*|)', '%1'..newline)
          if r == 0 then block = newline..block end
          buffer:begin_undo_action()
          buffer.target_start, buffer.target_end = s, p + 1
          buffer:replace_target('do'..block..newline..'end')
          local indent = line_indentation[line]
          line_indentation[line + 1] = indent + buffer.indent
          line_indentation[line + 2] = indent
          buffer:end_undo_action()
          return
        end
      end
    end
    p = p + 1
  end

  -- Try to toggle from do ... end to { ... }.
  local block, r = buffer:get_cur_line():gsub('do([^%w_]+.-)end$', '{%1}')
  if r > 0 then
    -- Single-line do ... end block.
    buffer:begin_undo_action()
    buffer.target_start, buffer.target_end = buffer:position_from_line(line), e
    buffer:replace_target(block)
    buffer:goto_pos(pos - 1)
    buffer:end_undo_action()
    return
  end
  local do_patt, end_patt = 'do%s*|?[^|]*|?%s*$', '^%s*end'
  local s = line
  while s >= 0 and not buffer:get_line(s):find(do_patt) do s = s - 1 end
  if s < 0 then return end -- no block start found
  local indent = line_indentation[s]
  e = s + 1
  while e < buffer.line_count and (not buffer:get_line(e):find(end_patt) or
                                   line_indentation[e] ~= indent) do
    e = e + 1
  end
  if e >= buffer.line_count then return end -- no block end found
  local s2 = buffer:position_from_line(s) + buffer:get_line(s):find(do_patt) - 1
  local _, e2 = buffer:get_line(e):find(end_patt)
  e2 = buffer:position_from_line(e) + e2
  if e2 < pos then return end -- the caret is outside the block found
  block = buffer:text_range(s2, e2):match('^do(.+)end$')
  block = block:gsub('[\r\n]+', ' '):gsub(' +', ' ')
  buffer:begin_undo_action()
  buffer.target_start, buffer.target_end = s2, e2
  buffer:replace_target('{'..block..'}')
  buffer:end_undo_action()
end

---
-- Container for Ruby-specific key commands.
-- @class table
-- @name _G.keys.ruby
keys.ruby = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = { io.open_file,
          (_HOME..'/modules/ruby/init.lua'):iconv('UTF-8', _CHARSET) },
    g = M.goto_required,
  },
  ['s\n'] = M.try_to_autocomplete_end,
  ['c{'] = M.toggle_block,
}

-- Snippets.

if type(snippets) == 'table' then
---
-- Container for Ruby-specific snippets.
-- @class table
-- @name _G.snippets.ruby
  snippets.ruby = {
    rb = '#!%[which ruby]',
    forin = 'for %1(element) in %2(collection)\n\t%1.%0\nend',
    ife = 'if %1(condition)\n\t%2\nelse\n\t%3\nend',
    ['if'] = 'if %1(condition)\n\t%0\nend',
    case = 'case %1(object)\nwhen %2(condition)\n\t%0\nend',
    Dir = 'Dir.glob(%1(pattern)) do |%2(file)|\n\t%0\nend',
    File = 'File.foreach(%1(\'path/to/file\')) do |%2(line)|\n\t%0\nend',
    am = 'alias_method :%1(new_name), :%2(old_name)',
    all = 'all? { |%1(e)| %0 }',
    any = 'any? { |%1(e)| %0 }',
    app = 'if __FILE__ == $PROGRAM_NAME\n\t%0\nend',
    as = 'assert(%1(test), \'%2(Failure message.)\')',
    ase = 'assert_equal(%1(expected), %2(actual))',
    asid = 'assert_in_delta(%1(expected_float), %2(actual_float), %3(2 ** -20))',
    asio = 'assert_instance_of(%1(ExpectedClass), %2(actual_instance))',
    asko = 'assert_kind_of(%1(ExpectedKind), %2(actual_instance))',
    asm = 'assert_match(/%1(expected_pattern)/, %2(actual_string))',
    asn = 'assert_nil(%1(instance))',
    asnm = 'assert_no_match(/%1(unexpected_pattern)/, %2(actual_string))',
    asne = 'assert_not_equal(%1(unexpected), %2(actual))',
    asnn = 'assert_not_nil(%1(instance))',
    asns = 'assert_not_same(%1(unexpected), %2(actual))',
    asnr = 'assert_nothing_raised(%1(Exception)) { %0 }',
    asnt = 'assert_nothing_thrown { %0 }',
    aso = 'assert_operator(%1(left), :%2(operator), %3(right))',
    asr = 'assert_raise(%1(Exception)) { %0 }',
    asrt = 'assert_respond_to(%1(object), :%2(method))',
    assa = 'assert_same(%1(expected), %2(actual))',
    asse = 'assert_send([%1(object), :%2(message), %3(args)])',
    ast = 'assert_throws(:%1(expected)) { %0 }',
    rw = 'attr_accessor :%1(attr_names)',
    r = 'attr_reader :%1(attr_names)',
    w = 'attr_writer :%1(attr_names)',
    cla = 'class %1(ClassName)\n\t%0\nend',
    cl = 'classify { |%1(e)| %0 }',
    col = 'collect { |%1(e)| %0 }',
    collect = 'collect { |%1(element)| %1.%0 }',
    def = 'def %1(method_name)\n\t%0\nend',
    mm = 'def method_missing(meth, *args, &block)\n\t%0\nend',
    defs = 'def self.%1(class_method_name)\n\t%0\nend',
    deft = 'def test_%1(case_name)\n\t%0\nend',
    deli = 'delete_if { |%1(e)| %0 }',
    det = 'detect { |%1(e)| %0 }',
    ['do'] = 'do\n\t%0\nend',
    doo = 'do |%1(object)|\n\t%0\nend',
    each = 'each { |%1(e)| %0 }',
    eab = 'each_byte { |%1(byte)| %0 }',
    eac = 'each_char { |%1(chr)| %0 }',
    eaco = 'each_cons(%1(2)) { |%2(group)| %0 }',
    eai = 'each_index { |%1(i)| %0 }',
    eak = 'each_key { |%1(key)| %0 }',
    eal = 'each_line%1 { |%2(line)| %0 }',
    eap = 'each_pair { |%1(name), %2(val)| %0 }',
    eas = 'each_slice(%1(2)) { |%2(group)| %0 }',
    eav = 'each_value { |%1(val)| %0 }',
    eawi = 'each_with_index { |%1(e), %2(i)| %0 }',
    fin = 'find { |%1(e)| %0 }',
    fina = 'find_all { |%1(e)| %0 }',
    flao = 'inject(Array.new) { |%1(arr), %2(a)| %1.push(*%2) }',
    grep = 'grep(%1(pattern)) { |%2(match)| %0 }',
    gsu = 'gsub(/%1(pattern)/) { |%2(match)| %0 }',
    [':'] = ':%1(key) => \'%2(value)\',',
    is = '=> ',
    inj = 'inject(%1(init)) { |%2(mem), %3(var)| %0 }',
    lam = 'lambda { |%1(args)| %0 }',
    map = 'map { |%1(e)| %0 }',
    mapwi = 'enum_with_index.map { |%1(e), %2(i)| %0 }',
    max = 'max { |a, b| %0 }',
    min = 'min { |a, b| %0 }',
    mod = 'module %1(ModuleName)\n\t%0\nend',
    par = 'partition { |%1(e)| %0 }',
    ran = 'sort_by { rand }',
    rej = 'reject { |%1(e)| %0 }',
    req = 'require \'%0\'',
    rea = 'reverse_each { |%1(e)| %0 }',
    sca = 'scan(/%1(pattern)/) { |%2(match)| %0 }',
    sel = 'select { |%1(e)| %0 }',
    sor = 'sort { |a, b| %0 }',
    sorb = 'sort_by { |%1(e)| %0 }',
    ste = 'step(%1(2)) { |%2(n)| %0 }',
    sub = 'sub(/%1(pattern)/) { |%2(match)| %0 }',
    tim = 'times { %1(n) %0 }',
    uni = 'ARGF.each_line%1 do |%2(line)|\n\t%0\nend',
    unless = 'unless %1(condition)\n\t%0\nend',
    upt = 'upto(%1(2)) { |%2(n)| %0 }',
    dow = 'downto(%1(2)) { |%2(n)| %0 }',
    when = 'when %1(condition)\n\t',
    zip = 'zip(%1(enums)) { |%2(row)| %0 }',
    tc = [[
require 'test/unit'
require '%1(library_file_name)'

class Test%2(NameOfTestCases) < Test::Unit::TestCase
	def test_%3(case_name)
		%0
	end
end]],
  }
end

return M
