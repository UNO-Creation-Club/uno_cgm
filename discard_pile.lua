local u = require('utility')
local enums = require('enums')

local discard_pile = {}
discard_pile.__index = discard_pile

function discard_pile:d_props()
  return {x = love.graphics.getWidth() / 2 - 20 + math.random(40), y = love.graphics.getHeight() / 2  + 10  + math.random(5), r = u.lerp(math.random(), 0, 1, 0, math.pi)}
end

function discard_pile:initialize(params)
  for k, v in pairs(params) do
    self[k] = v
  end
end

function discard_pile:create(card)
  card:show()
  discard_pile.anim:move{obj = card, to = self:d_props()}
  discard_pile.state.deck_suit = card:get_suit()
  discard_pile:_animate_background_to(discard_pile.state.deck_suit)
  return setmetatable({
    cards = {card},
  }, discard_pile)
end

function discard_pile:_animate_background_to(color)
  discard_pile.anim:move{obj = discard_pile.state.bg, to = {r = enums.colors[color][1], g = enums.colors[color][2], b = enums.colors[color][3], a = enums.colors[color][4]}}
end

function discard_pile:add(new_card)
  -- logic state change
  self.state.deck_suit = new_card:get_suit()
  self.cards[#self.cards+1] = new_card

  -- drawing state change
  self.anim:move{obj = new_card, to = self:d_props()}
  new_card:show()
  self:_animate_background_to(new_card:get_suit())
end

function discard_pile:peek_top_card()
  return self.cards[#self.cards]
end
discard_pile.peek = discard_pile.peek_top_card -- aliasing

function discard_pile:remove()
  return table.remove(self.cards)
end

function discard_pile:get_all_cards()
  local cards = self.cards
  self.cards = {}
  return cards
end

function discard_pile:draw()
  for i, card in ipairs(self.cards) do
    card:draw()
  end
end

return discard_pile