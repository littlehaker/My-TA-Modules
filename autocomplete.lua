events.connect('char_added', function(code)
  if code ~= 13 or code ~= 32 then
    _M.textadept.editing.autocomplete_word('%w_')
  end
end)
