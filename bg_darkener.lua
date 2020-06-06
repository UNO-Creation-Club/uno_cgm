local u = require('utility')

local bg_darkener = {
  d_props = {ca = 0, bgca = 0, bgcr = 100, bgcb = 100, bgcg = 100}
}

function bg_darkener:initialize(params)
  for k, v in pairs(params) do
    self[k] = v
  end
end

function bg_darkener:activate()
  self.anim:move{obj = self, to = {ca = 255, bgca = 100, bgcr = 100, bgcg = 100, bgcb = 100}}
end

function bg_darkener:deactivate()
  self.anim:move{obj = self, to = {ca = 0, bgca = 0, bgcr = 255, bgcg = 255, bgcb = 255}}
end

function bg_darkener:draw()
  love.graphics.setColor(u.normalize(self.d_props.bgcr, self.d_props.bgcg, self.d_props.bgcb, self.d_props.bgca))
  love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setColor(u.normalize(255, 255, 255))
end

return bg_darkener