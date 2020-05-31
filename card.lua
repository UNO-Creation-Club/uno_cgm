local u = require('utility')
local anim = require('anim')

local function _build_quads(card_sheet_image)
  local suits = {'R', 'Y', 'G', 'B'} 
  local ranks = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'S', 'R', 'D'}

  local card_quads = {}

  local j = 0
  for _, suit in ipairs(suits) do
    local i = 0
    for _, rank in ipairs(ranks) do
      card_quads[suit .. rank] = love.graphics.newQuad(i, j, 240, 360, card_sheet_image:getDimensions())
      i = i + 240
    end
    j = j + 360
  end
  card_quads['W1'] = love.graphics.newQuad(13 * 240, 0 * 360, 240, 360, card_sheet_image:getDimensions())
  card_quads['W4'] = love.graphics.newQuad(13 * 240, 1 * 360, 240, 360, card_sheet_image:getDimensions())
  card_quads['Title'] = love.graphics.newQuad(13 * 240, 2 * 360, 240, 360, card_sheet_image:getDimensions())

  return card_quads
end

local card = {
  img = love.graphics.newImage('assets/images/uno_min.png'),
  dims = {width = 240, height = 360},

  __tostring = function(c) return c.l_props.value end,
}
card.__index = card

card.quads = _build_quads(card.img)

function card:create(l_props, d_props)
  d_props = d_props or {}
  return setmetatable({
    l_props = {
      value = l_props.value,
      belongs_to = l_props.belongs_to,
      id = l_props.id, -- index if belongs_to == 'player'
    },
    d_props = {
      img = d_props.img or card.img,
      quad = d_props.quad or card.quads[l_props.value],
      x = d_props.x or 0,
      y = d_props.y or 0,
      r = d_props.r or 0,
      sx = d_props.sx or -0.5,
      sy = d_props.sy or 0.5,
      ox = d_props.ox or card.dims.width / 2,
      oy = d_props.oy or card.dims.height / 2,
      kx = d_props.kx or 0,
      ky = d_props.ky or 0}
  }, card)
end

function card:draw() -- format can be 'hidden', 'grey', 'visible'
  -- if  == 'grey' then
  --   love.graphics.setColor(u.normalize(127, 127, 127, 127))
  -- end
  love.graphics.draw(self.d_props.img,
  self.d_props.sx <= 0 and card.quads['Title'] or self.d_props.quad,
  self.d_props.x,
  self.d_props.y,
  self.d_props.r,
  self.d_props.sx,
  self.d_props.sy,
  self.d_props.ox,
  self.d_props.oy,
  self.d_props.kx,
  self.d_props.ky)
  love.graphics.setColor(u.normalize(255, 255, 255))
end

function card:change_d_props(params)
  for k, v in pairs(params) do
    self.d_props[k] = v
  end
  return self
end

function card:hide()
  anim:move{obj = self, to = {sx = - 0.5}, fn = anim.fn.COS}
end

function card:show()
  anim:move{obj = self, to = {sx = 0.5}, fn = anim.fn.COS}
end

function card:change_l_props(params)
  for k, v in pairs(params) do
    self.l_props[k] = v
  end
  return self
end

function card:get_width()
  return card.dims.width
end

function card:get_height()
  return card.dims.height
end

function card:get_suit()
  return self.l_props.value:sub(1, 1)
end

function card:get_rank()
  return self.l_props.value:sub(2, 2)
end

function card:get_value()
  return self.l_props.value
end

return card