-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The RHTML module.
-- It provides utilities for editing RHTML.
-- User tags are loaded from _USERHOME/modules/rhtml/tags and user apis are
-- loaded from _USERHOME/modules/rhtml/api.
module('_M.rhtml')]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `<`: show an autocompletion list of tags.
--
-- ## Fields
--
-- * `sense`: The RHTML [Adeptsense](_M.textadept.adeptsense.html).

if not _M.rails then _M.rails = require 'rails' end
if not _M.hypertext then _M.hypertext = require 'hypertext' end

M.set_buffer_properties = _M.hypertext.set_buffer_properties

-- Adeptsense.

local htmlsense = _M.hypertext.sense
M.sense = _M.textadept.adeptsense.new('rhtml')
M.sense.syntax = htmlsense.syntax
M.sense.api_files = htmlsense.api_files
M.sense:add_trigger('<')
M.sense.ctags_kinds = htmlsense.ctags_kinds
M.sense:load_ctags(_HOME..'/modules/hypertext/tags')
M.sense.get_symbol = htmlsense.get_symbol
M.sense.get_apidoc = htmlsense.get_apidoc

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/rhtml/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/rhtml/tags')
end
if lfs.attributes(_USERHOME..'/modules/rhtml/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/rhtml/api'
end

-- Commands.

---
-- Container for RHTML-specific key commands.
-- @class table
-- @name _G.keys.rhtml
keys.rhtml = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = { io.open_file,
          (_HOME..'/modules/rhtml/init.lua'):iconv('UTF-8', _CHARSET) },
  },
}
-- Add HTML keys to rhtml keys.
local rhtml_keys, html_keys = keys.rhtml, keys.hypertext
for k, v in pairs(html_keys) do
  if not rhtml_keys[k] then rhtml_keys[k] = v end
end

-- Snippets.

if type(snippets) == 'table' then
---
-- Container for RHTML-specific snippets.
-- @class table
-- @name _G.snippets.rhtml
  snippets.rhtml = {
    confirm = ':confirm => \'%1(Are you sure?)\'',
    cai = ':controller => :%1(posts), :action => :%2(show), :id => %3(post)',
    img = '<%= image_tag \'%1\' %%>',
    imgt = '<%= image_tag \'%2\', :title => "%1" %%>',
    jit = '<%= javascript_include_tag %1(defaults) %%>',
    slt = '<%= stylesheet_link_tag \'%1(style)\' %%>',
    lt = '<%= link_to \'%1\', %0 %%>',
    ltr = '<%= link_to_remote \'%1\', :url => { %2 }%3 %%>',
    partial = '<%= render :partial => \'%1(item)\'%0 %%>',
    ft = '<% form_tag %1do %%>\n\t%0\n<% end %%>',
    ftm = '<% form_tag %2, :method => %1(post) do %%>\n\t%0\n<% end %%>',
    ll = '<label>%0</label>',
    lf = '<label for="%1">%0</label>',
    emf = '<%= error_messages_for(:%1) %%>',
    pf = '<%= password_field :%1(model), :%2(attribute) %%>',
    st = '<%= submit_tag \'%1(save)\' %%>',
    tf = '<%= text_field :%1(model), :%2(attribute) %%>',
    hf = '<%= hidden_field :%1(model), :%2(attribute) %%>',
    cb = '<%= check_box :%1(model), :%2(attribute) %%>',
    select = '<%= select :%1(model), :%2(attribute), %3(values), { :include_blank => true } %%>',
    troe = '<tr class="<%= cycle( \'odd\', \'even\' ) %%>">\n\t%0\n</tr>',
    ['='] = '<%= %0 %%>',
    ['%'] = '<% %0 %%>',
    ['do'] = 'do\n\t%0\nend',
    doo = 'do |%1(object)|\n\t%0\nend',
    eachdo = '<% %1(@list).each do |%2(item)| %%>\n\t%0\n<% end %%>',
    forin = '<%= for %1(element) in %2(collection)\n\t%1.%0\nend %%>',
    ['if'] = '<% if %1(condition) %%>\n\t%0\n<% end %%>',
    ife = '<% if %1(condition) %%>\n\t%0\n<% else %%>\n\t\n<% end %%>',
    ['end'] = '<% end %%>',
  }
  -- Add HTML snippets to RHTML snippets.
  local rhtml_snippets, html_snippets = snippets.rhtml, snippets.hypertext
  for k, v in pairs(html_snippets) do
    if not rhtml_snippets[k] then rhtml_snippets[k] = v end
  end
  -- Add Ruby snippets to RHTML snippets.
  local ruby_snippets = snippets.rails
  for k, v in pairs(ruby_snippets) do
    if not rhtml_snippets[k] then rhtml_snippets[k] = v end
  end
end

return M
