local event = {}

--[[
Event types:
------------
{name='card_played', card}

]]

local function handle(e)
  if e.name == 'card_played' then
    
  elseif e.name == '' then

  end
end

local function disptch(e)
  handle(e)
end

return event