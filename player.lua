local u = require('utility')

local player = {
  _global_id = 0,
}
player.__index = player

function player:initialize(params)
  for k, v in pairs(params) do
    self[k] = v
  end
end

function player:create(params)
  assert(params.name, 'CUSTOM_ERROR: Player name HAS to be provided!')
  
  if not params.id then
    params.id = self._global_id + 1
    self._global_id = self._global_id + 1
  end

  local p =  setmetatable({
    name = params.name,
    id = params.id,
    cards = params.cards or {},
    selected_card_id = 1,
    valid_card_indices = {},
    card_drawn = false,
    d_props = {x = params.position and params.position.x or 0, y = params.position and params.position.y or 0}
  }, player)

  p.normal_card_height = {y = p.d_props.y}
  p.elevated_card_height = {y = p.d_props.y - 40}

  p:place(p.d_props.x, p.d_props.y)
  return p
end

local function _get_card_separation(n)
  -- math.floor(self.separation * (0.91^(n-1)))
  return n <= 7 and 300 / 7 or 300 / n
end

function player:_get_index(card)
  for i, c in ipairs(self.cards) do
    if c == card then
      return i
    end
  end
end

function player:place(x, y)
  self.d_props.x, self.d_props.y = x, y
  local n = #self.cards
  local sep = _get_card_separation(n)

  local c_x = x - (n-1) * sep / 2
  for i, card in ipairs(self.cards) do
    self.anim:move{obj = card, to = {x = c_x, y = y}}
    self.hitbox:place{
      id = string.format('player_%s', self.name),
      obj = card
    }
    card:change_h_props{
      on_click = function(card)
        self.event_handler:dispatch({name = 'card_played', type = card})
      end,
      on_enter = function(card)
        self.anim:move{obj = card, to = self.elevated_card_height}
      end,
      on_exit = function(card)
        self.anim:move{obj = card, to = self.normal_card_height}
      end
    }
    c_x = c_x + sep
  end
end

function player:add(new_card)
  local draw_pile = self.state.draw_pile
  local x, y = self.d_props.x, self.d_props.y
  local n = #self.cards+1
  local sep = _get_card_separation(n)

  self.hitbox:place{
    id = string.format('player_%s', self.name),
    obj = new_card
  }
  new_card:change_h_props{
    on_click = function(card)
      self.event_handler:dispatch({name = 'card_played', type = card})
    end,
    on_enter = function(card)
      self.anim:move{obj = card, to = self.elevated_card_height}
    end,
    on_exit = function(card)
      self.anim:move{obj = card, to = self.normal_card_height}
    end
  }

  local c_x = x - (n-1) * sep / 2
  for i, c in ipairs(self.cards) do
    self.anim:move{obj = c, to = {x = c_x, y = y}}
    c_x = c_x + sep
  end

  table.insert(self.cards, new_card)
  self.anim:move{obj = new_card, to = {x = c_x, y = y}}
end

function player:remove(card) -- game rules happen
  local x, y = self.d_props.x, self.d_props.y
  local n = #self.cards-1
  local sep = _get_card_separation(n)

  local card = table.remove(self.cards, self:_get_index(card))

  local c_x = x - (n-1) * sep / 2
  for i, c in ipairs(self.cards) do
    self.anim:move{obj = c, to = {x = c_x, y = y}}
    c_x = c_x + sep
  end

  self.hitbox:remove{
    id = string.format('player_%s', self.name),
    obj = card
  }
  return card
end

function player:draw()
  for i, card in ipairs(self.cards) do
    -- if not self.valid_card_indices[i] then
    --   self:deactivate_card(card)
    --   love.graphics.setColor(u.normalize(100, 100, 100))
    -- end
    card:draw()
    -- love.graphics.setColor(u.normalize(255, 255, 255))
  end
  love.graphics.printf(self.name, self.d_props.x, self.d_props.y - 120, 100, 'center')
end

function player:show_cards()
  for i, card in ipairs(self.cards) do
    card:show()
  end
end

function player:hide_cards()
  for i, card in ipairs(self.cards) do
    card:hide()
  end
end

function player:activate()
  self.hitbox:activate_region(string.format('player_%s', self.name))
  self:show_cards()
end

function player:deactivate()
  self.hitbox:deactivate_region(string.format('player_%s', self.name))
  self:hide_cards()
end

function player:activate_card(card)
  self.hitbox:deactivate_card(string.format('player_%s', self.name), card)
end

function player:deactivate_card(card)
  self.hitbox:deactivate_object(string.format('player_%s', self.name), card)
end

return player