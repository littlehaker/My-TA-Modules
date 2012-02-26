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

local c = _SCINTILLA.constants

---
-- Returns a list of the start and end locations of the occurrences of the word
-- under the caret
function find_all_occurrences()
  local locations = {}
  local buffer = buffer
  local s, e = buffer.selection_start, buffer.selection_end
  if s == e then
    s, e = buffer:word_start_position(s), buffer:word_end_position(s)
  end
  local word = buffer:text_range(s, e)
  if word == '' then return end
  buffer.search_flags = c.SCFIND_WHOLEWORD + c.SCFIND_MATCHCASE
  buffer.target_start = 0
  buffer.target_end = buffer.length
  while buffer:search_in_target(word) > 0 do
    table.insert(locations, {buffer.target_start, buffer.target_end})
    buffer.target_start = buffer.target_end
    buffer.target_end = buffer.length
  end
  return locations
end

return M
