--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2010 Brian Schott
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
-- Note: I did not look at any of the Zen Coding code while creating this
-- module. I looked only at the syntax reference posted here:
-- http://code.google.com/p/zen-coding/wiki/ZenHTMLSelectorsEn
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Revision History:
--     *    0.4 - Updated for Textadept 5
--     *    0.3 - Added support for the $ operator. Fixed behavior with the -
--          and _ characters. Added a few more tags to the SPECIAL_TAGS table.
--     *    0.2 - Updated to work with Textadept 3
--     *    0.1 - First 'real' release. Thanks to Robert Gould for adding
--          support for more of the Zen syntax and fixing a few bugs.
--------------------------------------------------------------------------------

local M = {}

--------------------------------------------------------------------------------
-- Configuration options for the various tags.
--------------------------------------------------------------------------------
local SPECIAL_TAGS = {
	a = {singleLine = true, indentChildren = false, attributes = {"href"}},
	acronym = {singleLine = true, indentChildren = false, attributes = {"title"}},
	area = {singleLine = true, indentChildren = false, attributes = {"shape", "coords", "href", "alt"}},
	b = {singleLine = true, indentChildren = false, attributes = {}},
	bdo = {singleLine = true, indentChildren = false, attributes = {"dir"}},
	button = {singleLine = true, indentChildren = false, attributes = {"type"}},
	caption = {singleLine = true, indentChildren = false, attributes = {}},
	colgroup = {singleLine = true, indentChildren = false, attributes = {}},
	dl = {singleLine = true, indentChildren = false, attributes = {}},
	dt = {singleLine = true, indentChildren = false, attributes = {}},
	em = {singleLine = true, indentChildren = false, attributes = {}},
	h1 = {singleLine = false, indentChildren = false, attributes = {}},
	h2 = {singleLine = false, indentChildren = false, attributes = {}},
	h3 = {singleLine = false, indentChildren = false, attributes = {}},
	h4 = {singleLine = false, indentChildren = false, attributes = {}},
	h5 = {singleLine = false, indentChildren = false, attributes = {}},
	h6 = {singleLine = false, indentChildren = false, attributes = {}},
	p = {singleLine = false, indentChildren = false, attributes = {}},
	li = {singleLine = false, indentChildren = false, attributes = {}},
	iframe = {singleLine = false, indentChildren = true, attributes = {"src", "width", "height"}},
	label = {singleLine = true, indentChildren = false, attributes = {"for"}},
	map = {singleLine = true, indentChildren = false, attributes = {"name"}},
	noframes = {singleLine = true, indentChildren = false, attributes = {}},
	noscript = {singleLine = true, indentChildren = false, attributes = {}},
	object = {singleLine = true, indentChildren = false, attributes = {}},
	option = {singleLine = true, indentChildren = false, attributes = {}},
	small = {singleLine = true, indentChildren = false, attributes = {}},
	span = {singleLine = true, indentChildren = false, attributes = {"style"}},
	strong = {singleLine = true, indentChildren = false, attributes = {}},
	sub = {singleLine = true, indentChildren = false, attributes = {}},
	sup = {singleLine = true, indentChildren = false, attributes = {}},
	table = {singleLine = false, indentChildren = true, attributes = {"border"}},
	textarea = {singleLine = false, indentChildren = true, attributes = {"rows", "cols"}},
	td = {singleLine = true, indentChildren = false, attributes = {}},
	th = {singleLine = true, indentChildren = false, attributes = {}},
	tr = {singleLine = false, indentChildren = false, attributes = {}},
	td = {singleLine = true, indentChildren = false, attributes = {}},
	p = {singleLine = false, indentChildren = true, attributes = {}},
}

local function tokenizeZen(text)
	local i = 0
	local t = {}
	while #text ~= 0 do
		local capture = text:match("^[%w_%-$]+") or text:match("[.>#+*]")
		if capture == nil then return nil end
		table.insert(t, capture)
		text = text:sub(#capture + 1)
		i = i + 1
	end
	return t
end

local function parseZen(partsTable)
	tree = {}
	currentParent = tree
	current = {class={}, children={}, multiplier=1}
	-- 0 = element name
	-- 1 = multiplier
	-- 2 = class
	-- 4 = id
	local meaning = 0
	for i, j in ipairs(partsTable) do
		if j:match(">") then
			table.insert(currentParent, current)
			currentParent = current.children
			current = {class={}, children={}, multiplier=1}
			meaning = 0
		elseif j:match("%*") then
			meaning = 1
		elseif j:match("%.") then
			meaning = 2
		elseif j:match("%+") then
			table.insert(currentParent, current)
			current = {class={}, children={}, multiplier=1}
			meaning = 0
		elseif j:match("#") then
			meaning = 3
		else
			if meaning == 0 then
				current.name = j
			elseif meaning == 1 then
				current.multiplier = tonumber(j)
			elseif meaning == 2 then
				table.insert(current.class, j)
			elseif meaning == 3 then
				current.id = j
			end
		end
	end
	table.insert(currentParent, current)
	return tree
end

local function printStack(elementList, index)
	if index == nil then index = 1 end
	if #elementList == 0 then return "" end
	for index, current in ipairs(elementList) do
		for j = 1, current.multiplier do
			--if current.name == nil then return "" end
			buffer:add_text("<"..(current.name or "div"))
			if current.id ~= nil then
				buffer:add_text(" id=\""..current.id:gsub("%$",
					string.format("%d", j)).."\"")
			end
			if #current.class ~= 0 then
				buffer:add_text(" class=\"")
				for i = 1, #current.class do
					if i > 1 then buffer:add_text(" ") end
					buffer:add_text(current.class[i]:gsub("%$",
						string.format("%d", j)))
				end
				buffer:add_text("\"")
			end
			if SPECIAL_TAGS[current.name] ~= nil then
				for index, attribute in ipairs(SPECIAL_TAGS[current.name].attributes) do
					buffer:add_text(" "..attribute.."=\"\"")
				end
			end
			buffer:add_text(">")
			if SPECIAL_TAGS[current.name] == nil
					or SPECIAL_TAGS[current.name].indentChildren ~= false then
				buffer:new_line()
				buffer:tab()
			end

			printStack(current.children, index + 1)

			if SPECIAL_TAGS[current.name] == nil
					or SPECIAL_TAGS[current.name].indentChildren ~= false then
				if #current.children ~= 0 then buffer:new_line() end
				buffer:back_tab()
			end
			buffer:add_text("</"..(current.name or "div")..">")
			if SPECIAL_TAGS[current.name] == nil or SPECIAL_TAGS[current.name].singleLine ~= true then
				if j ~= current.multiplier then buffer:new_line() end
			end
		end
		if index ~= #elementList then buffer:new_line() end
	end
end

function M.process_zen()
	buffer:begin_undo_action()
	buffer.target_end = buffer.current_pos
	buffer.target_start = buffer.current_pos
	while buffer.style_at[buffer.target_start - 1] ~= 17 and buffer.target_start > 0
			and not string.match(string.char(buffer.char_at[buffer.target_start - 1]), "%s") do
		buffer.target_start = buffer.target_start - 1
	end

	local text = buffer:target_as_utf8()
	local returnValue = false
	if text:match("[%w*>._$]+") then
		local partsTable = tokenizeZen(text)
		if partsTable ~= nil then
			buffer:replace_sel("")
			returnValue = true
			local tree = parseZen(partsTable)
			buffer:set_selection(buffer.target_start, buffer.target_end)
			buffer:delete_back()
			printStack(tree)
		end
	end
	buffer:end_undo_action()
	return returnValue
end

return M
