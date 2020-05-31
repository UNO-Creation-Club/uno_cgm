local anim = require('anim')
local u = require('utility')

local player = {}
player.__index = player

function player:create(name, id, cards, position)
  local p =  setmetatable({
    name = name,
    id = id,
    cards = cards,
    card_drawn = false,
    d_props = {x = position and position.x or 0, y = position and position.y or 0}
  }, player)
  p:set_position(p.d_props.x, p.d_props.y)
  return p
end

local function _get_card_separation(n)
  -- math.floor(self.separation * (0.91^(n-1)))
  return n <= 7 and 300 / 7 or 300 / n
end

function player:set_position(x, y)
  self.d_props.x, self.d_props.y = x, y
  -- Set the player around (self.d_props.x, self.d_props.y) (along with their cards of course)
  local n = #self.cards
  local sep = _get_card_separation(n)

  local c_x = x - (n-1) * sep / 2
  for i, card in ipairs(self.cards) do
    card
    :change_d_props{x = c_x, y = y}
    :change_d_props{y_init = y, y_final = y - 40}
    c_x = c_x + sep
  end
end

function player:add_card(new_card)
  -- restructure positions
  -- add card to player (referenced by self)
  local x, y = self.d_props.x, self.d_props.y
  local n = #self.cards+1
  local sep = _get_card_separation(n)

  local c_x = x - (n-1) * sep / 2
  for i, c in ipairs(self.cards) do
    -- c:change_d_props{x = c_x, y = y}:change_l_props{belongs_to=self.name, player_id = self.id}
    c:change_l_props{belongs_to=self.name, player_id = self.id}
    anim:move{obj = c, to = {x = c_x, y = y}}
    c_x = c_x + sep
  end
  table.insert(self.cards, new_card:change_l_props{card_id = n})
  anim:move{obj = new_card, to = {x = c_x, y = y}}
end

function player:remove_card(card)
  -- restructure positions
    local x, y = self.d_props.x, self.d_props.y
    local n = #self.cards-1
    local sep = _get_card_separation(n)

    table.remove(self.cards, card.l_props.card_id)
    card:change_l_props{belongs_to = 'discard_pile'}
    local c_x = x - (n-1) * sep / 2
    for i, c in ipairs(self.cards) do
      -- c:change_d_props{x = c_x, y = y}:change_l_props{card_id = i}
      c:change_l_props{card_id = i}
      anim:move{obj = c, to = {x = c_x, y = y}}
      c_x = c_x + sep
    end
    card.on_exit = function() end
    anim:move{obj = card, to = {x = love.graphics.getWidth() / 2 + (math.random(50) - 25), y = love.graphics.getHeight() / 2+ (math.random(50) - 25), r = u.lerp(math.random(), 0, 1, 0, math.pi)}}
end

function player:draw()
  -- draw player (referenced by self)
  for i, card in ipairs(self.cards) do
    card:draw()
  end
  -- love.graphics.setColor(u.normalize(0, 0, 0, 255))
  love.graphics.printf(self.name, self.d_props.x, self.d_props.y - 120, 100, 'center')
  -- love.graphics.setColor(u.normalize(255, 255, 255, 255))
end

return player