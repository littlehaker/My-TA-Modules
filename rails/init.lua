-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The rails module.
-- It provides utilities for editing Ruby on Rails code.
-- User tags are loaded from _USERHOME/modules/rails/tags and user apis are
-- loaded from _USERHOME/modules/rails/api.
module('_M.rails')]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `Ctrl+L, G` (`⌘L, G`): Goto file being 'require'd on the current line.
-- + `Ctrl+L, P` (`⌘L, P`): Open a Rails project for snapopen.
-- + `Ctrl+L, O` (`⌘L, O`): Snapopen a Rails project file.
-- + `Shift+Return`: Try to autocomplete an `if`, `for`, etc. statement with
--   `end`.
-- + `.`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `::`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
--
-- ## Fields
--
-- * `sense`: The Rails [Adeptsense](_M.textadept.adeptsense.html).
-- * `singular`: A map of plural controller names to their singulars. Add
--   key-value pairs to this if [singularize()](#singularize) is incorrectly
--   converting your plural controller name to its singular model name.

local m_editing = _M.textadept.editing
m_editing.comment_string.rails = m_editing.comment_string.ruby

if not _M.ruby then _M.ruby = require 'ruby' end
M.set_buffer_properties = _M.ruby.set_buffer_properties

-- Adeptsense.

local rubysense = _M.ruby.sense
M.sense = _M.textadept.adeptsense.new('rails')
M.sense.syntax = rubysense.syntax
M.sense.api_files = rubysense.api_files
M.sense.api_files[#M.sense.api_files + 1] = _HOME..'/modules/rails/api'
M.sense:add_trigger('.')
M.sense:add_trigger('::')
M.sense.ctags_kinds = rubysense.ctags_kinds
M.sense:load_ctags(_HOME..'/modules/ruby/tags')
M.sense:load_ctags(_HOME..'/modules/rails/tags')
M.sense.get_symbol = rubysense.get_symbol

-- Map to plural controller names to their singulars.
-- This is used for names that singularize cannot handle properly.
-- @class table
-- @name singular
M.singular = {}

-- Returns the singular form of the given controller name.
-- @param name The name to get the singular form of.
local function singularize(name)
  if M.singular[name] then
    return M.singular[name]
  elseif name:find('ies$') then
    return name:match('^(.-)ies$')..'y'
  elseif name:find('es$') then
    return name:match('^(.-)es$')
  elseif name:find('s$') then
    return name:match('^(.-)s$')
  end
  return name
end

-- If the caret is inside a Controller and the symbol is the Controller's model,
-- return ActiveResource::Base as the class instead of ApplicationController.
-- Otherwise, use the normal method of determining the symbol's class.
-- @param symbol The symbol to get the class of.
function M.sense:get_class(symbol)
  local class = rubysense.get_class(self, symbol) -- not rubysense:get_symbol()
  if not class and symbol ~= '' then class = self.super.get_class(self, '') end
  if class ~= 'ApplicationController' then return class end
  local buffer = buffer
  for i = buffer:line_from_position(buffer.current_pos), 0, -1 do
    local line = buffer:get_line(i)
    local name, superclass = line:match(rubysense.syntax.class_definition)
    if superclass == class then
      name = name:match('^(.-)Controller$')
      return symbol == singularize(name) and 'ActiveResource::Base' or class
    end
  end
  return class
end

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/rails/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/rails/tags')
end
if lfs.attributes(_USERHOME..'/modules/rails/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/rails/api'
end

-- Commands.

---
-- Sets keys.al.o to snapopen a Rails project.
-- If not directory is provided, the user is prompted for one.
-- @param utf8_dir The UTF-8 Rails project directory.
-- @name load_project
function M.load_project(utf8_dir)
  if not utf8_dir then
    utf8_dir = gui.dialog('fileselect',
                          '--title', 'Select a Rails Project',
                          '--select-only-directories',
                          '--with-directory',
                          (buffer.filename or ''):match('^.+[/\\]') or '',
                          '--no-newline')
  end
  if utf8_dir ~= '' then
    if not keys.al then keys.al = {} end
    keys.al.o = { _M.textadept.snapopen.open, utf8_dir }
    gui.statusbar_text = 'Snapopen project with '..
                         (OSX and 'Apple' or 'Alt')..'+L, O'
  end
end

---
-- Container for Rails-specific key commands.
-- @class table
-- @name _G.keys.rails
keys.rails = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = { io.open_file,
          (_HOME..'/modules/rails/init.lua'):iconv('UTF-8', _CHARSET) },
    g = _M.ruby.goto_required,
    p = M.load_project,
  },
}
-- Add Ruby keys to Rails keys.
local rails_keys, ruby_keys = keys.rails, keys.ruby
for k, v in pairs(ruby_keys) do
  if not rails_keys[k] then rails_keys[k] = v end
end

-- Snippets.

if type(snippets) == 'table' then
---
-- Container for Rails-specific snippets.
-- @class table
-- @name _G.snippets.rails
  snippets.rails = {
    bt = 'belongs_to :%1(category)',
    ho = 'has_one :%1(article)',
    hm = 'has_many :%1(comments)',
    habtm = 'has_and_belongs_to_many :%1(roles)',
    cond = ':conditions => %1(rails conditions string or array)',
    vao = 'validates_acceptance_of :%1(attribute)',
    va = 'validates_associated :%1(attribute)',
    vco = 'validates_confirmation_of :%1(attribute)',
    ve = [[
validates_each :%1(attribute) do |record, attr, value|
  record.errors.add attr, "%2(message)" if %0
end]],
    veo = [[
validates_exclusion_of :%1(attribute),
                       :in => %0]],
    vfo = [[
validates_format_of :%1(attribute),
                    :with%0]],
    vio = [[
validates_inclusion_of :%1(attribute),
                       :in%0]],
    vlo = [[
validates_length_of :%1(attribute),
                    :%2(maximum, minimum, is or within)]],
    vno = 'validates_numericality_of :%1(attribute)',
    vpo = 'validates_presence_of :%1(attribute)',
    on = ':on => :%1(default is save, other options are create or update)',
    vifp = ':if => Proc.new {|instance| %1(some code that checks your instance)',
    vif = ':if => :%1(method_name)',
    blank = ':allow_blank => %1(false)',
    vnil = ':allow_nil => %1(false)',
    msg = ':message => "%1(message)"',
    tl = ':too_long => "%1(value is too long (maximum is %d characters))"',
    ts = ':too_short => "%1(value is too short (minimum is %d characters))"',
    wl = ':wrong_length => "%1(value has wrong length (should be %d characters))"',
    accept = ':accept => "%1(1)"',
    with = ':with => /^%1(regexp)$/',
    ['in'] = ':in => ',
    max = ':maximum => %1(12)',
    min = ':minimum => %1(12)',
    within = ':within => (%1(12)..%2(15))',
    oi = ':only_integer => %1(true)',
    gt = ':greater_than => %1(5)',
    gtet = ':greater_than_or_equal_to => %1(5)',
    et = ':equal_to => %1(5)',
    lt = ':less_than => %1(5)',
    ltet = ':less_than_or_equal_to => %1(5)',
    odd = ':odd => true',
    even = ':even => true',
    bf = 'before_filter :%1(method_name)',
    only = ':only => [:%1(create)]',
    tcbi = 't.binary :%1(title)%2(, :limit => %3(2).megabytes)',
    tcb = 't.boolean :%1(title)',
    tcda = 't.date :$1(title)',
    tcdt = 't.datetime :%1(title)',
    tcd = 't.decimal :%1(title)%2(%3(, :precision => %4(10))%5(, :scale => %6(2)))',
    tcf = 't.float :%1(title)',
    tci = 't.integer :%1(title)',
    tcl = 't.integer :lock_version, :null => false, :default => 0',
    tcr = 't.references :%1(taggable)%2(, :polymorphic => %3({ :default => \'%4(Photo)\' }))',
    tcs = 't.string :%1(title)',
    tct = 't.text :%1(title)',
    tcti = 't.time :%1(title)',
    tcts = 't.timestamp :%1(title)',
    tctss = 't.timestamps',
    asrt = 'assert_redirected_to %1(:action => "%1(index)")',
    asrtp = 'assert_redirected_to %1(model)_path(%2(@)%3(%1))',
    asrtpl = 'assert_redirected_to %1(model)s_path',
    asrtnp = 'assert_redirected_to %1(parent)_%2(child)_path(%3(@)%4(%1), %5(@)%6(%2))',
    asrtnpp = 'assert_redirected_to %1(parent)_%2(child)_path(%3(@)%4(%1))',
    asre = 'assert_response :%1(success)%2(, @response.body)',
    asd = 'assert_difference "%1(Model).%2(count)", %3(+1) do\n\t%0\nend',
    asnd = 'assert_no_difference "%1(Model).%2(count)" do\n\t%0\nend',
    asrj = 'assert_rjs :%1(replace), %2("%3(dom id)")',
    ass = 'assert_select \'%1(path)\'%2(, :%3(text) => %4(\'%5(inner_html)\')) %6(do\n\t%0\nend)',
  }
  -- Add Ruby snippets to Rails snippets.
  local rails_snippets, ruby_snippets = snippets.rails, snippets.ruby
  for k, v in pairs(ruby_snippets) do
    if not rails_snippets[k] then rails_snippets[k] = v end
  end
end

return M
