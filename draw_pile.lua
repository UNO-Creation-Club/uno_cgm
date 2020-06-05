local draw_pile = {
  d_props = {x = 100, y = 450, r = 0}
}
draw_pile.__index = draw_pile

draw_pile.normal_d_props = draw_pile.d_props
draw_pile.elevated_d_props = draw_pile.d_props
draw_pile.elevated_d_props.y = draw_pile.elevated_d_props.y - 20

function draw_pile:initialize(params)
  for k, v in pairs(params) do
    draw_pile[k] = v
  end
end

function _shuffled_and_moved(deck)
  local shuffled_deck = {}

  shuffled_deck[1] = deck[1]
  for i = 2, #deck do
    table.insert(shuffled_deck, math.random(#shuffled_deck), deck[i])
  end

  shuffled_deck[1]:change_d_props(draw_pile.d_props)
  for i = 2, #shuffled_deck do
    shuffled_deck[i]:change_d_props{
      x = shuffled_deck[i-1].d_props.x - 0.15,
      y = shuffled_deck[i-1].d_props.y - 0.15,
      r = 0
    }
  end
  return shuffled_deck
end

function draw_pile:create(deck)
  return setmetatable({
    cards = _shuffled_and_moved(deck)
  }, draw_pile)
end

function draw_pile:add(new_card)
  self.anim:move{
    obj = new_card, 
    to = {
      x = self.cards[#self.cards].d_props.x - 0.15,
      y = self.cards[#self.cards].d_props.y - 0.15,
    }
  }
  self.cards[#self.cards+1] = new_card
end

function draw_pile:add_to_bottom(card)
  self.anim:move{obj = card, to = self.d_props}
  table.insert(self.cards, 1, card)
  for i = 2, #self.cards do
    self.anim:move{
      obj = self.cards[i],
      to = {
        x = self.cards[i-1].d_props.x - 0.15,
        y = self.cards[i-1].d_props.y - 0.15
      }
    }
  end
end

function draw_pile:remove()
  if #self.cards <= 1 then
    self.cards = _shuffled_and_moved(self.state.discard_pile:get_all_cards())
  end
  self.hitbox:remove{
    id = 'draw_pile',
    obj = self.cards[#self.cards]
  }
  local c = table.remove(self.cards)
  self:prime_top()
  return c
end

function draw_pile:prime_top() -- for collision
  self.hitbox:place{
    obj = self:peek(),
    id = 'draw_pile'
  }
  self:peek():change_h_props{
    on_click = function(c)
      self.state.curr_player:add(self:remove())
      c:show()
      self:prime_top()
      self.event_handler:dispatch{name = 'card_picked', type = c}
    end
  }
end

function draw_pile:peek()
  return self.cards[#self.cards]
end

function draw_pile:draw()
  for i, card in ipairs(self.cards) do
    card:draw()
  end
end

function draw_pile:activate()
  self.hitbox:activate_region('draw_pile')
end

function draw_pile:deactivate()
  self.hitbox:deactivate_region('draw_pile')
end

return draw_pile