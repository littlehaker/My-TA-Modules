-- Copyright 2012 littlehaker

local M = {}

--[[ This comment is for LuaDoc.
---
-- Text-based buffer list for the textadept module.

module('_M.textadept.buffer_list')]]

function M.bufferlist()
  local current_buffer = _BUFFERS[buffer]
  local buffer

  for i, val in ipairs(_BUFFERS) do
    if val._type == '[Buffer List]' then
      buffer = _BUFFERS[i]
      view:goto_buffer(i)
      break;
    end
  end

  if not buffer then
    buffer = new_buffer()
    buffer._type = '[Buffer List]'
  end

  buffer.read_only = false
  buffer:clear_all()
  for i, val in ipairs(_BUFFERS) do
    local filename = val.filename or val._type
    if filename then
      buffer:add_text(i..'\t\t')
      --The current buffer
      if i == current_buffer then
        buffer:add_text('%')
      else
        buffer:add_text(' ')
      end
      --The buffer is dirty
      if val.dirty then
        buffer:add_text('*')
      else
        buffer:add_text(' ')
      end
      buffer:add_text('\t\t'..filename..'\n')
    end
  end
  buffer:set_save_point()
  buffer.read_only = true
  buffer:goto_line(current_buffer - 1)
end

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

_G.keys['f1'] = M.bufferlist

return M
