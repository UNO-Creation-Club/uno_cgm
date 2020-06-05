local u = require('utility')
local enums = require('enums')

local color_buttons = {
  d_props = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2},
  opacity_controller = {d_props = {ca = 0, bgca = 0, bgcr = 100, bgcb = 100, bgcg = 100}}
}

color_buttons.red_d_props_default = {x = color_buttons.d_props.x - 90, y = color_buttons.d_props.y - 90, width = 90, height = 90, rx = 0, ry = 0, cr = 242, cg = 71, cb = 65, sx = 1, sy = 1, ox = 0, oy = 0}
color_buttons.red_d_props_deactivated = {x = color_buttons.d_props.x - 90, y = color_buttons.d_props.y - 90, width = 90, height = 90, rx = 0, ry = 0, cr = 242, cg = 71, cb = 65, sx = 1, sy = 1, ox = 0, oy = 0}
color_buttons.red_d_props_activated = {x = color_buttons.d_props.x - 90, y = color_buttons.d_props.y - 90, width = 90, height = 90, rx = 15, ry = 15, cr = 255, cg = 129, cb = 125, sx = 1, sy = 1, ox = 0, oy = 0}

color_buttons.blue_d_props_default = {x = color_buttons.d_props.x, y = color_buttons.d_props.y - 90, width = 90, height = 90, rx = 0, ry = 0, cr = 59, cg = 74, cb = 237, sx = 1, sy = 1, ox = 0, oy = 0}
color_buttons.blue_d_props_deactivated = {x = color_buttons.d_props.x, y = color_buttons.d_props.y - 90, width = 90, height = 90, rx = 0, ry = 0, cr = 59, cg = 74, cb = 237, sx = 1, sy = 1, ox = 0, oy = 0}
color_buttons.blue_d_props_activated = {x = color_buttons.d_props.x, y = color_buttons.d_props.y - 90, width = 90, height = 90, rx = 15, ry = 15, cr = 125, cg = 136, cb = 255, sx = 1, sy = 1, ox = 0, oy = 0}

color_buttons.green_d_props_default = {x = color_buttons.d_props.x - 90, y = color_buttons.d_props.y, width = 90, height = 90, rx = 0, ry = 0, cr = 43, cg = 201, cb = 40, sx = 1, sy = 1, ox = 0, oy = 0}
color_buttons.green_d_props_deactivated = {x = color_buttons.d_props.x - 90, y = color_buttons.d_props.y, width = 90, height = 90, rx = 0, ry = 0, cr = 43, cg = 201, cb = 40, sx = 1, sy = 1, ox = 0, oy = 0}
color_buttons.green_d_props_activated = {x = color_buttons.d_props.x - 90, y = color_buttons.d_props.y, width = 90, height = 90, rx = 15, ry = 15, cr = 104, cg = 242, cb = 102, sx = 1, sy = 1, ox = 0, oy = 0}

color_buttons.yellow_d_props_default = {x = color_buttons.d_props.x, y = color_buttons.d_props.y, width = 90, height = 90, rx = 0, ry = 0, cr = 250, cg = 234, cb = 55, sx = 1, sy = 1, ox = 0, oy = 0}
color_buttons.yellow_d_props_deactivated = {x = color_buttons.d_props.x, y = color_buttons.d_props.y, width = 90, height = 90, rx = 0, ry = 0, cr = 250, cg = 234, cb = 55, sx = 1, sy = 1, ox = 0, oy = 0}
color_buttons.yellow_d_props_activated = {x = color_buttons.d_props.x, y = color_buttons.d_props.y, width = 90, height = 90, rx = 15, ry = 15, cr = 255, cg = 244, cb = 122, sx = 1, sy = 1, ox = 0, oy = 0}

color_buttons.red_button = {d_props = color_buttons.red_d_props_default, get_height = function(self) return self.d_props.height end, get_width = function(self) return self.d_props.width end, h_props = {}}
color_buttons.blue_button = {d_props = color_buttons.blue_d_props_default, get_height = function(self) return self.d_props.height end, get_width = function(self) return self.d_props.width end, h_props = {}}
color_buttons.green_button = {d_props = color_buttons.green_d_props_default, get_height = function(self) return self.d_props.height end, get_width = function(self) return self.d_props.width end, h_props = {}}
color_buttons.yellow_button = {d_props = color_buttons.yellow_d_props_default, get_height = function(self) return self.d_props.height end, get_width = function(self) return self.d_props.width end, h_props = {}}

function color_buttons:_animate_background_to(color)
  self.anim:move{obj = self.state.bg, to = {r = enums.colors[color][1], g = enums.colors[color][2], b = enums.colors[color][3], a = enums.colors[color][4]}}
end

function color_buttons:initialize(params)
  for k, v in pairs(params) do
    self[k] = v
  end

  self.hitbox:define_region(
    'color_buttons',
    {
      x = self.d_props.x - 200,
      y = self.d_props.y - 200,
      width = 400,
      height = 400
    }
  )
  self.hitbox:place{
    id = 'color_buttons',
    obj = self.red_button,
    on_click = function(button)
      self:_animate_background_to('R')
      self.event_handler:dispatch({name = 'color_selected', type = 'R'})
    end,
    on_enter = function(button)
      self.anim:move{obj = button, to = self.red_d_props_activated, seconds = 0.2}
    end,
    on_exit = function(button)
      self.anim:move{obj = button, to = self.red_d_props_deactivated, seconds = 0.2}
    end
  }
  self.hitbox:place{
    id = 'color_buttons',
    obj = self.blue_button,
    on_click = function(button)
      self:_animate_background_to('B')
      self.event_handler:dispatch({name = 'color_selected', type = 'B'})
    end,
    on_enter = function(button)
      self.anim:move{obj = button, to = self.blue_d_props_activated, seconds = 0.2}
    end,
    on_exit = function(button)
      self.anim:move{obj = button, to = self.blue_d_props_deactivated, seconds = 0.2}
    end
  }
  self.hitbox:place{
    id = 'color_buttons',
    obj = self.green_button,
    on_click = function(button)
      self:_animate_background_to('G')
      self.event_handler:dispatch({name = 'color_selected', type = 'G'})
    end,
    on_enter = function(button)
      self.anim:move{obj = button, to = self.green_d_props_activated, seconds = 0.2}
    end,
    on_exit = function(button)
      self.anim:move{obj = button, to = self.green_d_props_deactivated, seconds = 0.2}
    end
  }
  self.hitbox:place{
    id = 'color_buttons',
    obj = self.yellow_button,
    on_click = function(button)
      self:_animate_background_to('Y')
      self.event_handler:dispatch({name = 'color_selected', type = 'Y'})
    end,
    on_enter = function(button)
      self.anim:move{obj = button, to = self.yellow_d_props_activated, seconds = 0.2}
    end,
    on_exit = function(button)
      self.anim:move{obj = button, to = self.yellow_d_props_deactivated, seconds = 0.2}
    end
  }

end

function color_buttons:show()
  self.hitbox:activate_region('color_buttons')
  self.anim:move{obj = self.opacity_controller, to = {ca = 255, bgca = 100, bgcr = 100, bgcg = 100, bgcb = 100}}
end

function color_buttons:hide()
  self.hitbox:deactivate_region('color_buttons')
  self.anim:move{obj = self.opacity_controller, to = {ca = 0, bgca = 0, bgcr = 255, bgcg = 255, bgcb = 255}}
end

function color_buttons:draw()
  love.graphics.setColor(u.normalize(self.opacity_controller.d_props.bgcr, self.opacity_controller.d_props.bgcg, self.opacity_controller.d_props.bgcb, self.opacity_controller.d_props.bgca))
  love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setColor(u.normalize(self.red_button.d_props.cr, self.red_button.d_props.cg, self.red_button.d_props.cb, self.opacity_controller.d_props.ca))
  love.graphics.rectangle('fill', self.red_button.d_props.x, self.red_button.d_props.y, self.red_button.d_props.width, self.red_button.d_props.height, self.red_button.d_props.rx, self.red_button.d_props.ry)
  love.graphics.setColor(u.normalize(self.blue_button.d_props.cr, self.blue_button.d_props.cg, self.blue_button.d_props.cb, self.opacity_controller.d_props.ca))
  love.graphics.rectangle('fill', self.blue_button.d_props.x, self.blue_button.d_props.y, self.blue_button.d_props.width, self.blue_button.d_props.height, self.blue_button.d_props.rx, self.blue_button.d_props.ry)
  love.graphics.setColor(u.normalize(self.green_button.d_props.cr, self.green_button.d_props.cg, self.green_button.d_props.cb, self.opacity_controller.d_props.ca))
  love.graphics.rectangle('fill', self.green_button.d_props.x, self.green_button.d_props.y, self.green_button.d_props.width, self.green_button.d_props.height, self.green_button.d_props.rx, self.green_button.d_props.ry)
  love.graphics.setColor(u.normalize(self.yellow_button.d_props.cr, self.yellow_button.d_props.cg, self.yellow_button.d_props.cb, self.opacity_controller.d_props.ca))
  love.graphics.rectangle('fill', self.yellow_button.d_props.x, self.yellow_button.d_props.y, self.yellow_button.d_props.width, self.yellow_button.d_props.height, self.yellow_button.d_props.rx, self.yellow_button.d_props.ry)
  love.graphics.setColor(u.normalize(255, 255, 255))
end

return color_buttons