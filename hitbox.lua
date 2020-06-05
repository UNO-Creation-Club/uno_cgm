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
  click_entered_region = nil,
  click_entered_region_id = nil,
  hover_entered_region = nil,
  hover_entered_region_id = nil,
  entered_object = nil,
  entered_object_id = nil,
  prev_hover_obj = nil,
  _pending_placements = {},
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
  if id == 'draw_pile' then
    self.message = id
  end
  self.deactivated_regions[id] = false
end

function hitbox:deactivate_object(id, obj)
  self.deactivated_objects[id][obj] = true
end

function hitbox:place(params)
  table.insert(self._pending_placements, params)
end

function hitbox:place_objects()
  for i, params in ipairs(self._pending_placements) do
    self:_place_actual(params)
    self._pending_placements[i] = nil
  end
  -- for i = 1, #self._pending_placements do
  --   self._pending_placements[i] = nil
  -- end
end

function hitbox:_place_actual(params) -- places 'obj' in region with id 'id'
  local obj = params.obj
  if (not obj.h_props.on_click) and params.on_click then
    obj.h_props.on_click = params.on_click
  elseif not obj.h_props.on_click then
    obj.h_props.on_click = function(self) end
  end
  if (not obj.h_props.on_enter) and params.on_enter then
    obj.h_props.on_enter = params.on_enter 
  elseif not obj.h_props.on_enter then
    obj.h_props.on_enter = function(self) end
  end
  if (not obj.h_props.on_exit) and params.on_exit then
    obj.h_props.on_exit = params.on_exit
  elseif not obj.h_props.on_exit then
    obj.h_props.on_exit = function(self) end
  end
  if not params.id then params.id = #self.objects + 1 end
  if self.objects[params.id] then
    table.insert(self.objects[params.id], 1, obj)
  else
    self.objects[params.id] = {obj}
  end
end

function hitbox:remove(params)
  params.obj.h_props.on_click, 
  params.obj.h_props.on_enter, 
  params.obj.h_props.on_exit = 
  function() end, 
  function() end, 
  function() end
  table.insert(self._pending_purges, {region_id = params.id, obj = params.obj})
end

function hitbox:remove_objects()
  for i, purge in ipairs(self._pending_purges) do
    if self.objects[purge.region_id] then
      for j, obj in ipairs(self.objects[purge.region_id]) do
        if obj == purge.obj then
          table.remove(self.objects[purge.region_id], j)
          break
        end
      end
    end
  end
end

function hitbox:purge_empty_object_tables() -- purge object lists which are empty
  for id, object_list in pairs(self.objects) do
    if #object_list == 0 then
      self.objects[id] = nil
      self.deactivated_objects[id] = nil
    end
  end
end

function hitbox:draw_regions()
  for id, region in pairs(self.regions) do
    if not self.objects[id] then
      love.graphics.setColor(u.normalize(245, 228, 73, 100))
    elseif self.deactivated_regions[id] then
      love.graphics.setColor(u.normalize(127, 127, 127, 100))
    elseif self.click_entered_region_id == id then
      love.graphics.setColor(u.normalize(214, 77, 182, 140))
    else
      love.graphics.setColor(u.normalize(247, 126, 219, 100))
    end
    love.graphics.rectangle('fill', region.x, region.y, region.width, region.height)
  end
  love.graphics.setColor(u.normalize(255, 255, 255)) -- resetting color so other drawn items are not tinted
end

function hitbox:update(dt)

  -- click checks
  self.click_entered_region_id = nil
  self.click_entered_region = nil
  for id, region in pairs(self.regions) do
    if not self.deactivated_regions[id] then
      local click_inside_region = (self.x >= region.x and self.x <= region.x + region.width) and
                            (self.y >= region.y and self.y <= region.y + region.height)
      if click_inside_region and self.objects[id] then -- collides + region has at least 1 object
        self.click_entered_region_id = id
        self.click_entered_region = region
        break
      end
    end
  end
  if self.click_entered_region then
    for id, obj in ipairs(self.objects[self.click_entered_region_id]) do
      local inside_obj = self.x >= (obj.d_props.x - math.abs(obj.d_props.sx * obj.d_props.ox)) and 
                         self.x <= (obj.d_props.x - math.abs(obj.d_props.sx * obj.d_props.ox)) + obj:get_width() * math.abs(obj.d_props.sx) and
                         self.y >= (obj.d_props. y- math.abs(obj.d_props.sy * obj.d_props.oy)) and 
                         self.y <= (obj.d_props.y - math.abs(obj.d_props.sy * obj.d_props.oy)) + obj:get_height() * math.abs(obj.d_props.sy)
      if inside_obj and not self.deactivated_objects[self.click_entered_region_id][obj] then
        obj.h_props.on_click(obj)
        self.x, self.y = -1, -1 -- push the pointer offscreen to prevent same things happening over and over again
        break
      end
    end
  end

  -- hover checks
  hover_entered_region = nil
  hover_entered_region_id = nil
  for id, region in pairs(self.regions) do
    if not self.deactivated_regions[id] then
      local hover_inside_region = self.mx >= region.x and
                                  self.mx <= region.x + region.width and
                                  self.my >= region.y and
                                  self.my <= region.y + region.height
      if hover_inside_region and self.objects[id] then -- collides + region has at least 1 object
        self.hover_entered_region_id = id
        self.hover_entered_region = region
        break
      end
    end
  end
  self.entered_object = nil
  if self.hover_entered_region then
    -- self.message = self.hover_entered_region_id .. '\n'
    -- for i = 1, #self.objects[self.hover_entered_region_id] do
    --   self.message = self.message .. tostring(self.objects[self.hover_entered_region_id][i]) .. '\n'
    -- end
    for id, obj in ipairs(self.objects[self.hover_entered_region_id]) do
      local inside_obj = self.mx >= (obj.d_props.x - math.abs(obj.d_props.sx * obj.d_props.ox)) and 
                         self.mx <= (obj.d_props.x - math.abs(obj.d_props.sx * obj.d_props.ox)) + obj:get_width() * math.abs(obj.d_props.sx) and
                         self.my >= (obj.d_props.y - math.abs(obj.d_props.sy * obj.d_props.oy)) and 
                         self.my <= (obj.d_props.y - math.abs(obj.d_props.sy * obj.d_props.oy)) + obj:get_height() * math.abs(obj.d_props.sy)
      if inside_obj then
        self.entered_object = obj
        break
      end
    end
  end
  if self.prev_hover_obj ~= self.entered_object then
    if self.prev_hover_obj then
      self.prev_hover_obj.h_props.on_exit(self.prev_hover_obj)
    end
    if self.entered_object then
      self.entered_object.h_props.on_enter(self.entered_object)
    end
    self.prev_hover_obj = self.entered_object
  end
  if #self._pending_purges > 0 then
    self:remove_objects()
  end
  if #self._pending_placements > 0 then
    self:place_objects()
  end
  -- self:purge_empty_object_tables()
end

function hitbox:update_click_position(x, y)
  self.x, self.y = x, y
end

function hitbox:update_hover_position(x, y)
  self.mx, self.my = x, y
end

return hitbox