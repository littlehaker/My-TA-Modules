-- Copyright 2012 littlehaker

local M = {}

--[[ This comment is for LuaDoc.
---
-- VI key binding for textadept.

module('_M.vi')]]


--[[
events.connect('char_added', function(code)
  if not (buffer._type or ''):match('^%[Buffer List%]') then
    return
  end

  local line_num = buffer:line_from_position(buffer.current_pos)
  local buffer_num = buffer:get_line(line_num):match('([%d]+).')

  --space to switch buffer
  if code == 32 or code == 13 then
    if buffer_num then
      view:goto_buffer(buffer_num)
    end
  --'x' or 'd' to close buffer
  elseif code == 120 or code == 100 then
    if buffer_num then
      view:goto_buffer(buffer_num)
      buffer:close()
      M.bufferlist()
    end
  end
end)
]]

--[[
events.connect('keypress', function(code, shift, ctrl, alt, meta)
  gui.print(code, shift, ctrl, alt, meta)
end
)
]]

function changeToInsert()
  buffer.mode = 'insert'
  buffer.read_only = false
  buffer.caret_style = M.old_caret_style or buffer.caret_style
end

function changeToNormal()
  buffer.mode = 'normal'
  buffer.read_only = true
  M.old_caret_style = buffer.caret_style
  buffer.caret_style = 2
end

function insert()
  changeToInsert()
  --buffer:delete_back_not_line()
end

function change_word()
  changeToInsert()
  buffer:del_word_right()
end

function change_in_word()
  change_word()
  buffer:del_word_left()
end

function delete_char()
  buffer.read_only = false
  buffer:char_right()
  buffer:delete_back_not_line()
  buffer.read_only = true
end

function undo()
  buffer.read_only = false
  buffer:undo()
  buffer.read_only = true
end

function insert_after()
  insert()
  buffer:char_right()
end

function insert_line_end()
  insert()
  buffer:line_end()
end

function insert_line_start()
  insert()
  buffer:line_up()
  buffer:line_end()
  buffer:char_right()
end

M.vi_keys = {
  normal = {
    ['i'] = insert,
    ['I'] = insert_line_start,
    ['a'] = insert_after,
    ['A'] = insert_line_end,
    ['cw'] = change_word,
    ['ciw'] = change_in_word,
    ['j'] = buffer.line_down,
    ['k'] = buffer.line_up,
    ['h'] = buffer.char_left,
    ['l'] = buffer.char_right,
    ['x'] = delete_char,
    ['u'] = undo,
    ['/'] = gui.find.focus,
    ['b'] = buffer.word_left,
    ['w'] = buffer.word_right,
    ['e'] = buffer.word_right_end,
    [':'] = gui.command_entry.focus
  },
  insert = {
    ['jj'] = changeToNormal,
  },
  visual = {}
}

--按键序列
M.char_seq = ''

events.connect('char_added', function(code)
--events.connect('keypress', function(code)
--  --普通模式
--  if buffer.mode == 'normal' then
--    M.char_seq = M.char_seq or '' .. string.char(code)
--
--    local f = M.vi_keys.normal[M.char_seq]
--    if f then
--      f()
--    else
--
--    end
--  --return false
--  --插入模式
--  elseif (not buffer.mode) or buffer.mode == 'insert' then
--    M.char_seq = M.char_seq .. string.char(code)
--    --gui.print(buffer.char_seq)
--    local f = M.vi_keys.insert[M.char_seq]
--   --gui.print(M.char_seq, f)
--    if f then
--      f()
--    else
--
--    end
--  --选择模式
--  elseif buffer.mode == 'visual' then
--  end

  if not buffer.mode then
    buffer.mode = 'insert'
    --buffer.read_only = true
  end

  if code > 0 and code < 128 then
    M.char_seq = M.char_seq .. string.char(code)
  end

  local f = M.vi_keys[buffer.mode][M.char_seq]
  if f then
    for i = 1, #M.char_seq do
      buffer:delete_back_not_line()
    end

    f()
    M.char_seq = ''
  else
    local start = false

    for k, _ in pairs(M.vi_keys[buffer.mode]) do
--      gui.print(k)
--      gui.print(M.char_seq)
--      gui.print(string.find(k, M.char_seq))
      if string.find(k, M.char_seq) == 1 then
        start = true
        break
      end
    end
    if not start then M.char_seq = '' end
--    gui.print(M.char_seq)
  end

end)

return M

