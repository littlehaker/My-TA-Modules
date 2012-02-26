function newline_after()
  buffer:line_end()
  buffer:new_line()
end

function newline_before()
  buffer:line_up()
  newline_after()
end

_G.keys['ao'] = {newline_after}
_G.keys['aO'] = {newline_before}
_G.keys['al'] = {buffer.char_right}
_G.keys['ah'] = {buffer.char_left}
_G.keys['aj'] = {buffer.line_down}
_G.keys['ak'] = {buffer.line_up}
