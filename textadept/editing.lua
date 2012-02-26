-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Editing commands for the textadept module.
module('_M.textadept.editing')]]

-- Markdown:
-- ## Settings
--
-- * `AUTOPAIR` [bool]: Opening `(`, `[`, `[`, `"`, or `'` characters are
--   automatically closed. The default value is `true`.
-- * `HIGHLIGHT_BRACES` [bool]: Highlight matching `()[]{}<>` characters. The
--   default value is `true`.
-- * `AUTOINDENT` [bool]: Match the indentation level of the previous line when
--   pressing the Enter key. The default value is `true`.
-- * `STRIP_WHITESPACE_ON_SAVE` [bool]: Strip trailing whitespace on file save.
--   The default value is `true`.
-- * `MARK_HIGHLIGHT_BACK` [number]: The background color used for a line
--   containing a highlighted word in `0xBBGGRR` format.
-- * `INDIC_HIGHLIGHT_BACK` [number]: The color used for an indicator for a
--   highlighted word in `0xBBGGRR` format.
-- * `INDIC_HIGHLIGHT_ALPHA` [number]: The alpha transparency value between `0`
--   (transparent) and `255` (opaque) used for an indicator for a highlighted
--   word. The default value is `100`.

M.AUTOPAIR = true
M.HIGHLIGHT_BRACES = true
M.AUTOINDENT = true
M.STRIP_WHITESPACE_ON_SAVE = true
M.MARK_HIGHLIGHT_BACK = buffer and buffer.caret_line_back or 0xEEEEEE
M.INDIC_HIGHLIGHT_BACK = 0x4D99E6
M.INDIC_HIGHLIGHT_ALPHA = 100

---
-- Comment strings for various lexer languages.
-- Used for the `block_comment()` function. Keys are lexer language names and
-- values are the line comment delimiters for the language. This table is
-- typically populated by language-specific modules.
-- @class table
-- @name comment_string
-- @see block_comment
M.comment_string = {}

---
-- Auto-matched characters.
-- Used for auto-matching parentheses, brackets, braces, quotes, etc. Keys are
-- lexer language names and values are tables of character match pairs. This
-- table can be populated by language-specific modules. The defaults are '()',
-- '[]', '{}', '''', and '""'.
-- @class table
-- @name char_matches
-- @usage _M.textadept.editing.char_matches.hypertext = { ..., [60] = '>' }
M.char_matches = { [40] = ')', [91] = ']', [123] = '}', [39] = "'", [34] = '"' }

---
-- Highlighted brace characters.
-- Keys are lexer language names and values are tables of characters that count
-- as brace characters. This table can be populated by language-specific
-- modules. The defaults are '(', ')', '[', ']', '{', and '}'.
-- @class table
-- @name braces
-- @usage _M.textadept.editing.braces.hypertext = { ..., [60] = 1, [62] = 1 }
M.braces = { [40] = 1, [41] = 1, [91] = 1, [93] = 1, [123] = 1, [125] = 1 }

-- The current call tip.
-- Used for displaying call tips.
-- @class table
-- @name current_call_tip
local current_call_tip = {}

local events, events_connect = events, events.connect
local K = keys.KEYSYMS

-- Matches characters specified in char_matches.
events_connect(events.CHAR_ADDED, function(c)
  if not M.AUTOPAIR then return end
  local buffer = buffer
  local match = (M.char_matches[buffer:get_lexer()] or M.char_matches)[c]
  if match and buffer.selections == 1 then buffer:insert_text(-1, match) end
end)

-- Removes matched chars on backspace.
events_connect(events.KEYPRESS, function(code)
  if not M.AUTOPAIR or K[code] ~= '\b' or buffer.selections ~= 1 then return end
  local buffer = buffer
  local pos = buffer.current_pos
  local c = buffer.char_at[pos - 1]
  local match = (M.char_matches[buffer:get_lexer()] or M.char_matches)[c]
  if match and buffer.char_at[pos] == string.byte(match) then buffer:clear() end
end)

-- Highlights matching braces.
events_connect(events.UPDATE_UI, function()
  if not M.HIGHLIGHT_BRACES then return end
  local buffer = buffer
  local pos = buffer.current_pos
  if (M.braces[buffer:get_lexer()] or M.braces)[buffer.char_at[pos]] then
    local match = buffer:brace_match(pos)
    if match ~= -1 then
      buffer:brace_highlight(pos, match)
    else
      buffer:brace_bad_light(pos)
    end
  else
    buffer:brace_bad_light(-1)
  end
end)

-- Auto-indent on return.
events_connect(events.CHAR_ADDED, function(char)
  if not M.AUTOINDENT or char ~= 10 then return end
  local buffer = buffer
  local anchor, caret = buffer.anchor, buffer.current_pos
  local line = buffer:line_from_position(caret)
  local pline = line - 1
  while pline >= 0 and #buffer:get_line(pline) == 1 do pline = pline - 1 end
  if pline >= 0 then
    local indentation = buffer.line_indentation[pline]
    local s = buffer.line_indent_position[line]
    buffer.line_indentation[line] = indentation
    local e = buffer.line_indent_position[line]
    if e > s then -- move selection on
      if anchor >= s then anchor = anchor + e - s end
      if caret  >= s then caret  = caret  + e - s end
    elseif e < s then -- move selection back
      if anchor >= e then anchor = anchor >= s and anchor + e - s or e end
      if caret  >= e then caret  = caret  >= s and caret  + e - s or e end
    end
    buffer:set_sel(anchor, caret)
  end
end)

-- Autocomplete multiple selections.
events_connect(events.AUTO_C_SELECTION, function(text, position)
  local buffer = buffer
  local caret = buffer.selection_n_caret[buffer.main_selection]
  buffer:begin_undo_action()
  for i = 0, buffer.selections - 1 do
    buffer.target_start = buffer.selection_n_anchor[i] - (caret - position)
    buffer.target_end = buffer.selection_n_caret[i]
    buffer:replace_target(text)
    buffer.selection_n_anchor[i] = buffer.selection_n_anchor[i] + #text
    buffer.selection_n_caret[i] = buffer.selection_n_caret[i] + #text
  end
  buffer:end_undo_action()
  buffer:auto_c_cancel() -- tell Scintilla not to handle autocompletion normally
end)

---
-- Goes to a matching brace position, selecting the text inside if specified to.
-- @param select If `true`, selects the text between matching braces.
-- @name match_brace
function M.match_brace(select)
  local buffer = buffer
  local caret = buffer.current_pos
  local match_pos = buffer:brace_match(caret)
  if match_pos == -1 then return end
  if not select then
    buffer:goto_pos(match_pos)
  elseif match_pos > caret then
    buffer:set_sel(caret, match_pos + 1)
  else
    buffer:set_sel(caret + 1, match_pos)
  end
end

---
-- Pops up an autocompletion list for the current word based on other words in
-- the document.
-- @param word_chars String of chars considered to be part of words.
-- @return `true` if there were completions to show; `false` otherwise.
-- @name autocomplete_word
function M.autocomplete_word(word_chars)
  local buffer = buffer
  local caret, length = buffer.current_pos, buffer.length
  local completions, c_list = {}, {}
  local buffer_text = buffer:get_text(buffer.length)
  local root = buffer_text:sub(1, caret):match('['..word_chars..']+$')
  if not root or root == '' then return end
  local patt = '^['..word_chars..']+'
  buffer.target_start, buffer.target_end = 0, buffer.length
  buffer.search_flags = _SCINTILLA.constants.SCFIND_WORDSTART
  if not buffer.auto_c_ignore_case then
    buffer.search_flags = buffer.search_flags +
                          _SCINTILLA.constants.SCFIND_MATCHCASE
  end
  local match_pos = buffer:search_in_target(root)
  while match_pos ~= -1 do
    local s, e = buffer_text:find(patt, match_pos + 1)
    local match = buffer_text:sub(s, e)
    if not completions[match] and #match > #root then
      c_list[#c_list + 1], completions[match] = match, true
    end
    buffer.target_start, buffer.target_end = match_pos + 1, buffer.length
    match_pos = buffer:search_in_target(root)
  end
  if not buffer.auto_c_ignore_case then
    table.sort(c_list)
  else
    table.sort(c_list, function(a, b) return a:upper() < b:upper() end)
  end
  if #c_list > 0 then
    if not buffer.auto_c_choose_single or #c_list ~= 1 then
      buffer:auto_c_show(#root, table.concat(c_list, ' '))
    else
      -- Scintilla does not emit AUTO_C_SELECTION in this case. This is
      -- necessary for autocompletion with multiple selections.
      events.emit(events.AUTO_C_SELECTION, c_list[1], caret - #root)
    end
    return true
  end
end

---
-- Block comments or uncomments code with a given comment string.
-- @param comment The comment string inserted or removed from the beginning of
--   each line in the selection.
-- @name block_comment
function M.block_comment(comment)
  local buffer = buffer
  if not comment then
    comment = M.comment_string[buffer:get_lexer()]
    if not comment then return end
  end
  local anchor, caret = buffer.selection_start, buffer.selection_end
  local s = buffer:line_from_position(anchor)
  local e = buffer:line_from_position(caret)
  local mlines = s ~= e
  if mlines and caret == buffer:position_from_line(e) then e = e - 1 end
  buffer:begin_undo_action()
  for line = s, e do
    local pos = buffer:position_from_line(line)
    if buffer:text_range(pos, pos + #comment) == comment then
      buffer:set_sel(pos, pos + #comment)
      buffer:replace_sel('')
      caret = caret - #comment
    else
      buffer:insert_text(pos, comment)
      caret = caret + #comment
    end
  end
  buffer:end_undo_action()
  if mlines then buffer:set_sel(anchor, caret) else buffer:goto_pos(caret) end
end

---
-- Goes to the requested line.
-- @param line Optional line number to go to. If `nil`, the user is prompted for
--   one.
-- @name goto_line
function M.goto_line(line)
  if not line then
    line = tonumber(gui.dialog('standard-inputbox',
                               '--title', _L['Go To'],
                               '--text', _L['Line Number:'],
                               '--no-newline'):match('%-?%d+$'))
    if not line or line < 0 then return end
  end
  buffer:ensure_visible_enforce_policy(line - 1)
  buffer:goto_line(line - 1)
end

---
-- Prepares the buffer for saving to a file.
-- Strips trailing whitespace off of every line, ensures an ending newline, and
-- converts non-consistent EOLs.
-- @name prepare_for_save
function M.prepare_for_save()
  if not M.STRIP_WHITESPACE_ON_SAVE then return end
  local buffer = buffer
  buffer:begin_undo_action()
  -- Strip trailing whitespace.
  local line_end_position, char_at = buffer.line_end_position, buffer.char_at
  local lines = buffer.line_count
  for line = 0, lines - 1 do
    local s, e = buffer:position_from_line(line), line_end_position[line]
    local i, c = e - 1, char_at[e - 1]
    while i >= s and c == 9 or c == 32 do i, c = i - 1, char_at[i - 1] end
    if i < e - 1 then
      buffer.target_start, buffer.target_end = i + 1, e
      buffer:replace_target('')
    end
  end
  -- Ensure ending newline.
  local e = buffer:position_from_line(lines)
  if lines == 1 or lines > 1 and e > buffer:position_from_line(lines - 1) then
    buffer:insert_text(e, '\n')
  end
  -- Convert non-consistent EOLs
  buffer:convert_eo_ls(buffer.eol_mode)
  buffer:end_undo_action()
end
events_connect(events.FILE_BEFORE_SAVE, M.prepare_for_save)

---
-- Transposes characters intelligently.
-- If the caret is at the end of a line, the two characters before the caret are
-- transposed. Otherwise, the characters to the left and right are.
-- @name transpose_chars
function M.transpose_chars()
  local buffer = buffer
  local pos, c = buffer.current_pos, buffer.char_at[buffer.current_pos]
  local eol = c == 10 or c == 13 or pos == buffer.length
  if eol then pos = pos - 1 end
  buffer.target_start, buffer.target_end = pos - 1, pos + 1
  buffer:replace_target(buffer:text_range(pos - 1, pos + 1):reverse())
  buffer:goto_pos(not eol and pos or pos + 1)
end

---
-- Joins the currently selected lines.
-- If no lines are selected, joins the current line with the line below.
-- @name join_lines
function M.join_lines()
  local buffer = buffer
  buffer:target_from_selection()
  buffer:line_end()
  local line = buffer:line_from_position(buffer.target_start)
  if line == buffer:line_from_position(buffer.target_end) then
    buffer.target_end = buffer:position_from_line(line + 1)
  end
  buffer:lines_join()
end

---
-- Encloses text within a given pair of strings.
-- If text is selected, it is enclosed. Otherwise, the previous word is
-- enclosed.
-- @param left The left part of the enclosure.
-- @param right The right part of the enclosure.
-- @name enclose
function M.enclose(left, right)
  local buffer = buffer
  buffer:target_from_selection()
  local s, e = buffer.target_start, buffer.target_end
  if s == e then buffer.target_start = buffer:word_start_position(s, true) end
  buffer:replace_target(left..buffer:text_range(buffer.target_start, e)..right)
  buffer:goto_pos(buffer.target_end)
end

---
-- Selects text between a given pair of strings.
-- @param left The left part of the enclosure.
-- @param right The right part of the enclosure.
-- @name select_enclosed
function M.select_enclosed(left, right)
  local buffer = buffer
  buffer:search_anchor()
  local s, e = buffer:search_prev(0, left), buffer:search_next(0, right)
  if s >= 0 and e >= 0 then buffer:set_sel(s + 1, e) end
end

---
-- Grows the selection by a character amount on either end.
-- @param amount The amount to grow the selection on either end.
-- @name grow_selection
function M.grow_selection(amount)
  local buffer = buffer
  local anchor, caret = buffer.anchor, buffer.current_pos
  if anchor < caret then
    buffer:set_sel(anchor - amount, caret + amount)
  else
    buffer:set_sel(anchor + amount, caret - amount)
  end
end

---
-- Selects the current word under the caret.
-- @name select_word
function M.select_word(action)
  local buffer = buffer
  buffer:set_sel(buffer:word_start_position(buffer.current_pos, true),
                 buffer:word_end_position(buffer.current_pos, true))
end

---
-- Selects the current line.
-- @name select_line
function M.select_line()
  buffer:home()
  buffer:line_end_extend()
end

---
-- Selects the current paragraph.
-- Paragraphs are delimited by two or more consecutive newlines.
-- @name select_paragraph
function M.select_paragraph()
  buffer:para_up()
  buffer:para_down_extend()
end

---
-- Selects indented blocks intelligently.
-- If no block of text is selected, all text with the current level of
-- indentation is selected. If a block of text is selected and the lines to the
-- top and bottom of it are one indentation level lower, they are added to the
-- selection. In all other cases, the behavior is the same as if no text is
-- selected.
-- @name select_indented_block
function M.select_indented_block()
  local buffer = buffer
  local s = buffer:line_from_position(buffer.selection_start)
  local e = buffer:line_from_position(buffer.selection_end)
  local indent = buffer.line_indentation[s] - buffer.indent
  if indent < 0 then return end
  if buffer:get_sel_text() ~= '' and
     buffer.line_indentation[s - 1] == indent and
     buffer.line_indentation[e + 1] == indent then
    s, e, indent = s - 1, e + 1, indent + buffer.indent
  end
  while buffer.line_indentation[s - 1] > indent do s = s - 1 end
  while buffer.line_indentation[e + 1] > indent do e = e + 1 end
  s, e = buffer:position_from_line(s), buffer.line_end_position[e]
  buffer:set_sel(s, e)
end

---
-- Converts indentation between tabs and spaces.
-- @name convert_indentation
function M.convert_indentation()
  local buffer = buffer
  local line_indentation = buffer.line_indentation
  local line_indent_position = buffer.line_indent_position
  buffer:begin_undo_action()
  for line = 0, buffer.line_count do
    local s = buffer:position_from_line(line)
    local indent = line_indentation[line]
    local indent_pos = line_indent_position[line]
    current_indentation = buffer:text_range(s, indent_pos)
    if buffer.use_tabs then
      new_indentation = ('\t'):rep(indent / buffer.tab_width)
    else
      new_indentation = (' '):rep(indent)
    end
    if current_indentation ~= new_indentation then
      buffer.target_start, buffer.target_end = s, indent_pos
      buffer:replace_target(new_indentation)
    end
  end
  buffer:end_undo_action()
end

local MARK_HIGHLIGHT = _SCINTILLA.next_marker_number()
local INDIC_HIGHLIGHT = _SCINTILLA.next_indic_number()

-- Clears highlighted word indicators and markers.
local function clear_highlighted_words()
  local buffer = buffer
  buffer:marker_delete_all(MARK_HIGHLIGHT)
  buffer.indicator_current = INDIC_HIGHLIGHT
  buffer:indicator_clear_range(0, buffer.length)
end
events_connect(events.KEYPRESS, function(code)
  if K[code] == 'esc' then clear_highlighted_words() end
end)

---
-- Highlights all occurances of the word under the caret and adds markers to the
-- lines they are on.
-- @name highlight_word
function M.highlight_word()
  clear_highlighted_words()
  local buffer = buffer
  local s, e = buffer.selection_start, buffer.selection_end
  if s == e then
    s, e = buffer:word_start_position(s, true), buffer:word_end_position(s)
  end
  if s == e then return end
  local word = buffer:text_range(s, e)
  buffer.search_flags = _SCINTILLA.constants.SCFIND_WHOLEWORD +
                        _SCINTILLA.constants.SCFIND_MATCHCASE
  buffer.target_start, buffer.target_end = 0, buffer.length
  while buffer:search_in_target(word) > 0 do
    local len = buffer.target_end - buffer.target_start
    buffer:marker_add(buffer:line_from_position(buffer.target_start),
                      MARK_HIGHLIGHT)
    buffer:indicator_fill_range(buffer.target_start, len)
    buffer.target_start, buffer.target_end = buffer.target_end, buffer.length
  end
  buffer:set_sel(s, e)
end

-- Sets view properties for highlighted word indicators and markers.
local function set_highlight_properties()
  local buffer = buffer
  buffer:marker_set_back(MARK_HIGHLIGHT, M.MARK_HIGHLIGHT_BACK)
  buffer.indic_fore[INDIC_HIGHLIGHT] = M.INDIC_HIGHLIGHT_BACK
  buffer.indic_style[INDIC_HIGHLIGHT] = _SCINTILLA.constants.INDIC_ROUNDBOX
  buffer.indic_alpha[INDIC_HIGHLIGHT] = M.INDIC_HIGHLIGHT_ALPHA
end
if buffer then set_highlight_properties() end
events_connect(events.VIEW_NEW, set_highlight_properties)

return M
