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

--------------------------------------------------------------------------------
-- Code that allows for access to Textadept's multiple cursors
--
-- Changelog:
--     Version 0.2
--     * Fixed some bugs with the selectAll function.
--     Version 0.3
--     * Updated to Textadept 5
--------------------------------------------------------------------------------

local M = {}

_M.common.findall = require "common.findall"

local positions = {}
local restore = false
local find_all_occurrences = _M.common.findall.find_all_occurrences

function select_all_occurences()
	local current = buffer.current_pos
	local mainstart, mainend = buffer.current_pos, buffer.current_pos
	local locations = find_all_occurrences()
	for index, value in ipairs(locations) do
		if current <= value[2] and current >= value[1] then
			mainstart = value[1]
			mainend = value[2]
		elseif index == 1 then
			buffer:set_selection(value[1], value[2])
		else
			buffer:add_selection(value[1], value[2])
		end
	end
	buffer:add_selection(mainstart, mainend)
end

return M
