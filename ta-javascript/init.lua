--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2011 Brian Schott (Sir Alaran)
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--------------------------------------------------------------------------------

local M = {}

_M.common.cstyle = require "common.cstyle"

_M.textadept.editing.comment_string.javascript = "//"

function M:set_buffer_properties()
end

-- Adeptsense
sense = _M.textadept.adeptsense.new("javascript")
sense.ctags_kinds = {
	m = "functions",
	f = "fields",
	c = "classes"
}

-- Load ctags files
if lfs.attributes(_USERHOME.."/modules/javascript/tags") then
	sense:load_ctags(_USERHOME.."/modules/javascript/tags")
end

sense:add_trigger(".")
sense.syntax.word_chars = "%w_%$" -- allow dollar sign for jQuery
sense.syntax.symbol_chars = '[%w_%$%.]'

-- Override get_symbol so that adeptsense will show jQuery autocomplete in the
-- following situation:
-- $("#someid").
function sense:get_symbol()
	local char = string.char(buffer.char_at[buffer.current_pos - 2])
	if char == ")" then
		begin = buffer:brace_match(buffer.current_pos - 2)
		if string.char(buffer.char_at[begin - 1]) == "$" then return "jQuery", "" end
	end
	return self.super.get_symbol(sense)
end

-- $ is a common alias for jQuery
function sense:get_class(symbol)
	if symbol == "$" then return "jQuery" else return symbol end
end

-- Snippets
if type(_G.snippets) == "table" then
	snippets.javascript = {
		gei = [[document.getElementById("%1")]]
	}
end

-- Keys
keys.javascript = {
	[keys.LANGUAGE_MODULE_PREFIX] = {
		m = { io.open_file,
		(_USERHOME..'/modules/javascript/init.lua'):iconv('UTF-8', _CHARSET) },
	},
	--['a\n'] = {_M.common.cstyle.newline},
	['s\n'] = {_M.common.cstyle.newline_semicolon},
	['c;'] = {_M.common.cstyle.endline_semicolon},
	['}'] = {_M.common.cstyle.match_brace_indent},
	['\n'] = {_M.common.cstyle.enter_key_pressed},
	-- force K&R style because JS is dumb
	['c{'] = {_M.common.cstyle.openBraceMagic, false},
	['cs\n'] = {_M.common.cstyle.closeTagComStr},
	['cM'] = {_M.common.cstyle.selectScope},
	[not OSX and 'ci' or 'cesc'] = { sense.complete, sense },
}

return M
