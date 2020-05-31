local utility = {}

function utility.lerp(x, a, b, af, bf)  -- linear interpolation
  return af + ((x - a) / (b - a)) * (bf - af)
end

function utility.normalize(r, g, b, a)
  return r / 255, g / 255, b / 255, a and a / 255 or 1
end

function utility.table_string_nr(t)
  -- return '{' .. table.concat(t, ', ') .. '}'
  local s = '{'
  for i, item in ipairs(t) do
    s = s .. tostring(item) .. (next(t, i) ~=nil and ', ' or '')
  end
  s = s .. '}'
  return s
end

function table_string(t)
  local s = '{'
  for k, item in t do
      if type(item) == 'table' then
          s = s .. table_string(item)
      else
          s = s .. string.format('%s', item)
      end
      if next(t, k) then
          s = s .. ', '
      end
  end
  s = s .. '}'
  return s
end
utility.table_string = table_string

return utility