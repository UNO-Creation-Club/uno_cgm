----------------------------------
--[[

Designed to check for collisions!
Divides the screen into user defined regions. Checks the regions for the inclusion of p = (self.x, self.y) (which can be updated via update_static_position). If p lies within a region, checks for collision with objects registered within the region by the user.


ISSUES:
---------

Google drawing of the issue.
https://docs.google.com/drawings/d/1xjeflPBGy4S9wuBNr44daN6scS4e8MBrZO-1qp8vvBs/edit?usp=sharing

Scaling + origin shifting messes with collision detection. If we push the origin to the center of the card (needed for simplifying the process of centering a hand properly), and then scale it down to half size, all 4 corners of the card shrink about new origin. This means that we cannot simply check for (self.x >= object.d_props.x and self.x <= object.d_props.x + obj:get_width()) and (same for y axis).
]]



----------------------------------
local u = require('utility')

local hitbox = {
  x = 0, y = 0,
  mx = 0, my = 0,
  regions = {},
  objects = {},
  deactivated_regions = {},
  deactivated_objects = {},
  entered = {},
  _pending_purges = {},
  message = 0 -- message added for debugging purposes
}

function hitbox:define_region(id, region)
  self.regions[id] =  region
  self.deactivated_objects[id] = {}
  self:deactivate_region(id)
end

function hitbox:deactivate_region(id)
  self.deactivated_regions[id] = true
end

function hitbox:activate_region(id)
  self.deactivated_regions[id] = false
end

function hitbox:deactivate_object(id, index)
  self.deactivated_objects[id][index] = true
end

function hitbox:place(params) -- places 'obj' in region with id 'id'
  local obj = params.obj
  if params.on_click then 
    obj.on_click = params.on_click 
  else
    obj.on_click = function(self) end
  end
  if params.on_enter then 
    obj.on_enter = params.on_enter 
  else
    obj.on_enter = function(self) end
  end
  if params.on_exit then 
    obj.on_exit = params.on_exit
  else
    obj.on_exit = function(self) end
  end
  if not params.id then params.id = #self.objects + 1 end
  if self.objects[params.id] then
    table.insert(self.objects[params.id], 1, obj)
  else
    self.objects[params.id] = {obj}
  end
end

function hitbox:purge_empty_region_object_tables() -- purge object lists which are empty
  for id, object_list in pairs(self.objects) do
    if #object_list == 0 then
      self.objects[id] = nil
      self.deactivated_objects[id] = nil
    end
  end
  
end

function hitbox:draw_regions()
  local count = 1
  for id, region in pairs(self.regions) do
    if not self.deactivated_regions[id] then
      love.graphics.setColor(u.normalize((122 * count)%256, (54 * count)%256, (127 * count)%256, 100)) -- random color values
      love.graphics.rectangle('fill', region.x, region.y, region.width, region.height)
      count = count + 1
    end
  end
  love.graphics.setColor(u.normalize(255, 255, 255)) -- resetting color so other drawn items are not tinted
end

function hitbox:update(dt)
  for id, region in pairs(self.regions) do
    if not self.deactivated_regions[id] then
      local click_inside_region = (self.x >= region.x and self.x <= region.x + region.width) and
                            (self.y >= region.y and self.y <= region.y + region.height)
      if click_inside_region and self.objects[id] then -- collides + region has at least 1 object
        for index, obj in ipairs(self.objects[id]) do
          if not self.deactivated_objects[id][index] then
            local inside_obj = self.x >= (obj.d_props.x - obj.d_props.sx * obj.d_props.ox) and 
                               self.x <= (obj.d_props.x - obj.d_props.sx * obj.d_props.ox) + obj:get_width() * obj.d_props.sx and
                               self.y >= (obj.d_props. y- obj.d_props.sy * obj.d_props.oy) and 
                               self.y <= (obj.d_props.y - obj.d_props.sy * obj.d_props.oy) + obj:get_height() * obj.d_props.sy
            if inside_obj then
              if obj.on_click then obj:on_click() end
              self.x, self.y = -1, -1 -- push the pointer offscreen
              table.remove(self.objects[id], index)
              break
            end
          end
        end
      end
      local hover_inside_region = (self.mx >= region.x and self.mx <= region.x + region.width) and
                                  (self.my >= region.y and self.y <= region.y + region.height)
      if hover_inside_region and self.objects[id] then
        if not self.entered[id] then
          for index, obj in ipairs(self.objects[id]) do
            local inside_obj = self.mx >= (obj.d_props.x - obj.d_props.sx * obj.d_props.ox) and 
                              self.mx <= (obj.d_props.x - obj.d_props.sx * obj.d_props.ox) + obj:get_width() * obj.d_props.sx and
                              self.my >= (obj.d_props.y - obj.d_props.sy * obj.d_props.oy) and 
                              self.my <= (obj.d_props.y - obj.d_props.sy * obj.d_props.oy) + obj:get_height() * obj.d_props.sy
            if inside_obj then
              -- self.message = index
              self.entered[id] = {index = index, obj = obj}
              obj:on_enter()
            end
          end
        else -- if entered something
          local obj = self.entered[id].obj
          local inside_obj = self.mx >= (obj.d_props.x - obj.d_props.sx * obj.d_props.ox) and 
                            self.mx <= (obj.d_props.x - obj.d_props.sx * obj.d_props.ox) + obj:get_width() * obj.d_props.sx and
                            self.my >= (obj.d_props.y - obj.d_props.sy * obj.d_props.oy) and 
                            self.my <= (obj.d_props.y - obj.d_props.sy * obj.d_props.oy) + obj:get_height() * obj.d_props.sy
          if not inside_obj then
            obj:on_exit()
            self.entered[id] = nil
            -- self.message = 'nil'
            break
          else
            for i = 1, self.entered[id].index-1 do
              local obj = self.objects[id][i]
              local inside_obj = self.mx >= (obj.d_props.x - obj.d_props.sx * obj.d_props.ox) and self.mx <= (obj.d_props.x - obj.d_props.sx * obj.d_props.ox) + obj:get_width() * obj.d_props.sx and
                                self.my >= (obj.d_props. y- obj.d_props.sy * obj.d_props.oy) and self.my <= (obj.d_props.y - obj.d_props.sy * obj.d_props.oy) + obj:get_height() * obj.d_props.sy
              if inside_obj then
                self.entered[id].obj:on_exit()
                -- self.message = i
                self.entered[id] = {index = i, obj = obj}
                obj:on_enter()
                break
              end
            end
          end
        end
      end
    end
  end
  self:purge_empty_region_object_tables()
end

function hitbox:update_static_position(x, y)
  self.x, self.y = x, y
end

function hitbox:update_dynamic_position(x, y)
  self.mx, self.my = x, y
end

return hitbox