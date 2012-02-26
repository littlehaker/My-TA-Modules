--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2011 Brian Schott
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
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR THERWISE, ARISING FROM,
-- THE SOFTWARE.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- This file provides functions that will automatically close XML tags.
--
-- See the comments above each function for the key bindings that should be used
-- with the various functions. I do not recommend using autoTag in combination
-- with completeClosingTagBracket. The two functions are designed for two
-- different usage styles.
--
-- Changelog:
--     Version 0.10.0 - Dec 2011
--        * Updated to Textadept 5
--        * Use _Scintilla.next_marker_number() to get a unique marker number
--     Version 0.9.0 - Oct 26 2010
--        * Added matching tag highlighting
--     Version 0.8.1 - Aug 16 2010
--        * Fixed a bug in one of the lua patterns. This has the nice
--          side-effect of adding a "grow selection" feature to the
--          selectToMatching function
--     Version 0.8 - Aug 15 2010
--         * Bug fix for unbalanced begin_undo_action / end_undo_action
--         * Added the selectMatchingTagName function
--         * Added the selectToMatching function
--     Version 0.7 - Jun 25 2010
--         * Added the ability to comment out text by selecting it and pressing
--           the "!" key.
--     Version 0.6 - Jun 02 2010
--         * Fixed an infinite loop bug with the singleTag function
--     Version 0.5 - May 17 2010
--         * Added encloseTag function.
--     Version 0.4 - May 15 2010
--         * Added begin_undo_action and end_undo_action to various functions.
--         * Updated documentation comments.
--     Version 0.3 - May 11 2010
--------------------------------------------------------------------------------

local M = {}


MARK_XML_TAG_INDEX = _SCINTILLA.next_marker_number()
MARK_XML_TAG_MATCH_COLOR = 0x00ff00
MARK_XML_TAG_BAD_COLOR = 0x0000ff
MARK_XML_TAG_ALPHA = 128

-- Sets view properties for highlighted word indicators and markers.
local function set_highlight_properties()
  local buffer = buffer
  buffer.indic_fore[MARK_XML_TAG_INDEX] = MARK_XML_TAG_MATCH_COLOR
  buffer.indic_style[MARK_XML_TAG_INDEX] = _SCINTILLA.constants.INDIC_ROUNDBOX
  buffer.indic_alpha[MARK_XML_TAG_INDEX] = MARK_XML_TAG_ALPHA
  buffer.indic_under[MARK_XML_TAG_INDEX] = true
end
if buffer then set_highlight_properties() end
events.connect('view_new', set_highlight_properties)

local function clearMatchingTag()
	local buffer = buffer
	buffer.indicator_current = MARK_XML_TAG_INDEX
	buffer.indic_fore[MARK_XML_TAG_INDEX] = MARK_XML_TAG_MATCH_COLOR
	buffer:indicator_clear_range(0, buffer.length)
end

--------------------------------------------------------------------------------
-- Returns: start, end, type, name
-- start is the start of the tag
-- end is the end of the tag
-- type is 0 for opening, 1 for closing, and 2 for single
-- name is the tag name
--------------------------------------------------------------------------------
function M.currentTagInfo()
	local buffer = buffer
	buffer.target_end = 0
	buffer.target_start = buffer.current_pos
	buffer.search_flags = 0x00200000
	local f = buffer:search_in_target("[<>]")
	if f == -1 or buffer.char_at[f] ~= 60 then return nil end
	buffer.target_end = buffer.length
	buffer.target_start = buffer.current_pos
	local e = buffer:search_in_target("[<>]")
	if e == -1 or buffer.char_at[e] ~= 62 then return nil end
	local text = buffer:text_range(f, e + 1)
	local t
	if text:find("^</") then
		t = 1
	elseif text:find("/>$") or text:find("^<!") then
		t = 2
	else
		t = 0
	end
	local name = text:match("</?([^%s>]+)")
	return f, e + 1, t, name
end
local currentTagInfo = currentTagInfo

--------------------------------------------------------------------------------
-- Highlights the current XML tag and its matching tag
--------------------------------------------------------------------------------
function M.highlightMatchingTagName()
	local buffer = buffer
	clearMatchingTag()
	local first, last, tagType, tagName = currentTagInfo()
	if first == nil or tagName == nil then return end
	buffer:indicator_fill_range(first, last - first)
	buffer.search_flags = 0x00200000
	local depth
	if tagType == 2 then
		return
	elseif tagType == 0 then
		buffer.target_start = last
		buffer.target_end = buffer.length
		depth = 1
	else
		buffer.target_start = first
		buffer.target_end = 0
		depth = -1
	end
	local res
	while depth ~= 0 do
		res = buffer:search_in_target("</?"..tagName)
		if res == -1 then break end
		if buffer:text_range(res, res + 2) == "</" then
			depth = depth - 1
		else
			depth = depth + 1
		end
		buffer.target_start = res + tagName:len()
		if tagType == 0 then
			buffer.target_end = buffer.length
		else
			buffer.target_end = 0
		end
	end
	if depth ~= 0 then
		buffer.indic_fore[MARK_XML_TAG_INDEX] = MARK_XML_TAG_BAD_COLOR
		return
	end
	if tagType == 1 then
		buffer.target_start = res
		buffer.target_end = buffer.length
		local len = buffer:search_in_target(">") - res + 1
		buffer:indicator_fill_range(res, len)
	else
		buffer:indicator_fill_range(res, tagName:len() + 3)
	end
end

--------------------------------------------------------------------------------
-- Selects all text within the tag containing the cursor
--------------------------------------------------------------------------------
function M.selectToMatching()
	local buffer = buffer
	local oldPos = buffer.current_pos
	local pattern = "<[^>!?]*[^/>]>"
	local count = 1
	local tagName = nil
	-- Search forward, finding all tags. Stop when an end tag is found that did
	-- not have a matching opening tag during this search.
	while count ~= 0 do
		buffer:search_anchor()
		-- Prevent an infinite loop in the (likely) event of malformed xml
		if buffer:search_next(0x00200000, pattern) == -1 then
			buffer:set_sel(oldPos, oldPos)
			return
		end
		if buffer:get_sel_text():match("^</") then
			count = count - 1
		else
			count = count + 1
		end
		-- Note the name of the ending tag so that the next loop can run a bit
		-- faster.
		tagName = buffer:get_sel_text():match("^</(%S+)>$")
		buffer:char_right()
	end
	-- Save the end position of the ending tag
	local endPos = buffer.current_pos
	-- Back up the position of the cursor to before the ending tag
	buffer:search_anchor()
	buffer:search_prev(4, "<")
	-- Search for the matching opening tag
	local startPattern = "</?"..tagName
	count = 1
	while count ~= 0 do
		buffer:search_anchor()
		-- Prevent an infinite loop in the (likely) event of malformed xml
		if buffer:search_prev(0x00200000, startPattern) == -1 then
			buffer:set_sel(oldPos, oldPos)
			return
		end
		if buffer:get_sel_text():match("</") then
			count = count + 1
		else
			count = count - 1
		end
	end
	local startPos = buffer.current_pos
	-- Set the selection
	buffer:set_sel(startPos, endPos)
end

--------------------------------------------------------------------------------
-- For internal use. Returns the name of any tag open at the cursor position
--------------------------------------------------------------------------------
local function findOpenTag()
	local buffer = buffer
	local stack = {}
	local endLine = buffer:line_from_position(buffer.current_pos)
	for i = 0, endLine do
		local first = 0;
		local last = 0;
		text = buffer:get_line(i)
		first, last = text:find("</?[^%s>%?!]+.->", last)
		while first ~= nil and text:sub(first, last):find("/>") == nil do
			local tagName = text:match("<(/?[^%s>%?!]+).->", first)
			if tagName:find("^/") then
				if #stack == 0 then
					return nil
				elseif "/"..stack[#stack] == tagName then
					table.remove(stack)
				else
					break
				end
			else
				table.insert(stack, tagName)
			end
			first, last = text:find("</?[^%s>%?!]+.->", last)
		end
	end
	return stack[#stack]
end

--------------------------------------------------------------------------------
-- Call this one whenever you want a tag closed
--------------------------------------------------------------------------------
function M.completeClosingTag()
	buffer:begin_undo_action()
	local buffer = buffer
	local tagName = findOpenTag()
	if tagName ~= nil then
		buffer:add_text("</"..tagName..">")
	end
	buffer:end_undo_action()
end

--------------------------------------------------------------------------------
-- Call this function when a '>' character is inserted. It is not recommended to
-- use this with autoTag.
--
-- ['>'] = {completeClosingTagBracket},
--------------------------------------------------------------------------------
function M.completeClosingTagBracket()
	buffer:begin_undo_action()
	local buffer = buffer
	local pos = buffer.current_pos
	buffer:insert_text(pos, ">")
	local tagName = findOpenTag()
	if tagName ~= nil then
		buffer:set_selection(pos + 1, pos + 1)
		buffer:add_text("</"..tagName..">")
	end
	buffer:set_sel(pos + 1, pos + 1)
	buffer:end_undo_action()
end

--------------------------------------------------------------------------------
-- Uses the multiple-cursor feature to close tags as you type them. It is not
-- recommended to use this with completeClosingTagBracket
--
-- ['<'] = {autoTag},
--------------------------------------------------------------------------------
function M.autoTag()
	buffer:begin_undo_action()
	local pos = buffer.current_pos
	buffer:insert_text(pos, "<></>")
	buffer:set_selection(pos + 4, pos + 4, 0)
	buffer:add_selection(pos + 1, pos + 1)
	buffer:end_undo_action()
end

local function toggleComment()
	buffer:begin_undo_action()
	local text = buffer:get_sel_text()
	local first = text:match("<!%-%-(.-)%-%->")
	if first == nil then
		buffer:replace_sel("<!--"..text.."-->")
	else
		buffer:replace_sel(first)
	end
	buffer:end_undo_action()
end

--------------------------------------------------------------------------------
-- Opens an XML/HTML comment. Use this only if using autoTag.
--
-- ['!'] = {completeComment},
--------------------------------------------------------------------------------
function M.completeComment()
	buffer:begin_undo_action()
	local text = buffer:get_sel_text()
	if #text > 0 then
		toggleComment()
	else
		local pos = buffer.current_pos
		buffer:set_selection(pos, pos + 4)
		if buffer:get_sel_text() == "></>" then
			buffer:replace_sel("!--  -->")
			buffer:set_selection(pos + 4, pos + 4)
		else
			buffer:set_selection(pos, pos)
			buffer:add_text("!")
		end
	end
	buffer:end_undo_action()
end

--------------------------------------------------------------------------------
-- Call this in response to a ? being inserted. Use this only if using autoTag.
--
-- ['?'] = {completePHP},
--------------------------------------------------------------------------------
function M.completePHP()
	buffer:begin_undo_action()
	local pos = buffer.current_pos
	buffer:set_selection(pos, pos + 4)
	if buffer:get_sel_text() == "></>" then
		buffer:replace_sel("?php  ?>")
		buffer:set_selection(pos + 5, pos + 5)
	else
		buffer:set_selection(pos, pos)
		buffer:add_text("?")
	end
	buffer:end_undo_action()
end

--------------------------------------------------------------------------------
-- Bind this to a '/' character being inserted. This cancels the above function
-- for tags like <br/>. Use this only if using autoTag.
--
-- ['/'] = {singleTag},
--------------------------------------------------------------------------------
function M.singleTag()
	buffer:begin_undo_action()
	if buffer.selections > 1 then
		local pos = buffer.current_pos
		buffer:set_sel(pos - 1, pos)
		if buffer:get_sel_text() =="<" then
			buffer:set_selection(pos, pos + 4)
			if buffer:get_sel_text() == "></>" then
				buffer:replace_sel("/>")
				buffer:set_selection(pos + 1, pos + 1)
				buffer:end_undo_action()
				return
			else
				buffer:set_selection(pos, pos)
			end
		else
			buffer:set_selection(pos, pos)
		end
		buffer:set_sel(pos, pos + 2)
		local text = buffer:get_sel_text()
		if text == "><" then
			local doKill = true
			while text:find("></[^>%s]+>") == nil do
				if buffer.selection_end == buffer.line_end_position then
					doKill = false
				end
				buffer:char_right_extend()
				text = buffer:get_sel_text()
			end
			buffer:replace_sel("/>")
			buffer:set_selection(pos, pos)
		else
			buffer:set_selection(pos, pos)
			buffer:add_text("/")
		end
	else
		buffer:add_text("/")
	end
	buffer:end_undo_action()
end

function M.handleBackspace()
	if buffer.selections == 2 then
		buffer:begin_undo_action()
		local pos1 = buffer.current_pos
		buffer:rotate_selection()
		local pos2 = buffer.current_pos
		buffer:set_sel(pos1 - 1, pos1 + 5)
		if buffer:get_sel_text() == "<></>" then
			buffer:replace_sel("")
			buffer:goto_pos(pos1)
			buffer:end_undo_action()
		else
			buffer:set_sel(pos2, pos2)
			buffer:add_selection(pos1, pos1)
			buffer:end_undo_action()
			return false
		end
	else
		return false
	end
end

--------------------------------------------------------------------------------
-- Call this when the spacebar is pressed. Use this only if using autoTag.
--
-- [' '] = {handleSpace},
--------------------------------------------------------------------------------
function M.handleSpace()
	buffer:begin_undo_action()
	local pos = buffer.current_pos
	if buffer.selections > 1 then
		buffer:clear_selections()
		buffer:set_sel(pos, pos)
		buffer:add_text(" ")
	else
		if #buffer:get_sel_text() > 0 then
			buffer:replace_sel(" ")
		else
			buffer:add_text(" ")
		end
	end
	buffer:end_undo_action()
end

--------------------------------------------------------------------------------
-- Enclose the selection in a tag
--------------------------------------------------------------------------------
function M.encloseTag()
	buffer:begin_undo_action()
	local text = buffer:get_sel_text()
	local start = buffer.selection_start
	buffer:replace_sel("<>"..text.."</>")
	local leftCursorPos = start + 1
	local rightCursorPos = start + 4 + #text
	buffer:set_selection(rightCursorPos, rightCursorPos)
	buffer:add_selection(leftCursorPos, leftCursorPos)
	buffer:end_undo_action()
end

--------------------------------------------------------------------------------
-- Toggles line comments on the selected lines
--------------------------------------------------------------------------------
function M.toggleLineComment()
	buffer:begin_undo_action()
	local initial = buffer:line_from_position(buffer.current_pos)
	local first = initial
	local last = buffer:line_from_position(buffer.anchor)
	if first > last then first, last = last, first end
	for i = first, last do
		buffer:goto_line(i)
		buffer:home()
		buffer:line_end_extend()
		toggleComment()
	end
	buffer:goto_line(initial)
	buffer:end_undo_action()
end

local pcall = pcall
local highlightMatchingTagName = highlightMatchingTagName

-- This variable helps prevent stack overflows
local lockdepth = 0
function highlightEvent()
	local buffer = buffer
	lockdepth = lockdepth + 1
	if lockdepth == 1 then
		local ok, lexLang = pcall(buffer.get_lexer, buffer)
		if lexLang == "xml" or lexLang == "hypertext" or lexLang == "php" then
			-- Use pcall because it's impossible to guarantee that the buffer
			-- will be valid when calling highlightMatchingTagName
			pcall(highlightMatchingTagName)
		end
	end
	lockdepth = lockdepth - 1
end
events.connect(events.UPDATE_UI, highlightEvent)

return M
