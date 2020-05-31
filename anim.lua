local u = require('utility')

local anim = {
  change_list = {},
  fn = {
    SIN = {fn = math.sin, fn_init = 0, fn_end = math.pi / 2},
    COS = {fn = math.cos, fn_init = 0, fn_end = math.pi / 2},
    SQR = {fn = function(x) return x * x end, fn_init = 0, fn_end = 1},
    SQRT = {fn = function(x) return math.sqrt(x) end, fn_init = 0, fn_end = 1},
  },
  pending = {}
}

local function calc_num_frames(seconds)
  return math.floor(60 * seconds) + 1 -- program executes 60 frames a second.
end

local function construct_animation_frames(old, curr, num_frames, fn_bag) -- n is the number of frames

  fn, input_init, input_end = fn_bag.fn, fn_bag.fn_init, fn_bag.fn_end
  output_init, output_end = fn(input_init), fn(input_end)

  local delta = (input_end - input_init) / num_frames

  local frames = {}

  for i = 1, num_frames do
    frames[i] = u.lerp(fn(input_init + delta * i), output_init, output_end, old, curr) -- mapping
  end

  return frames
end

function anim:move(params) -- {id, obj, props, seconds, fn}
  params.props = params.props or params.to
  params.seconds, params.fn = params.seconds or 0.5, params.fn or anim.fn.SQRT
  params.on_end = params.on_end or function() end
  local bag = {obj = params.obj, props = params.props, on_end = params.on_end}
  -- add frames to bag
  bag.frames, bag.curr_frame, bag.last_frame = {}, 0, calc_num_frames(params.seconds) -- animation not started, curr_frame is 0
  for k, v in pairs(params.props) do
    assert(params.obj.d_props[k] ~= nil, string.format('ANIM_ERROR: Drawing property \'%s\' not initialized!', k))
    bag.frames[k] = construct_animation_frames(params.obj.d_props[k], v, bag.last_frame, params.fn)
  end
  if params.id then 
    self.pending[params.id] = bag
  else
    table.insert(self.pending, bag)
  end
end

function anim:update(dt)
  for id, bag in pairs(self.change_list) do
    bag.curr_frame = bag.curr_frame + 1
    if bag.curr_frame <= bag.last_frame then
      for k, frames in pairs(bag.frames) do
        bag.obj.d_props[k] = frames[bag.curr_frame]
        if bag.obj.while_animating then bag.obj:while_animating() end
      end
    else
      -- perform on_end action
      self.change_list[id] = nil -- delete animation
      bag.on_end(bag.obj)
    end
  end
  for id, bag in pairs(self.pending) do
    self.change_list[id] = bag
  end
end

function anim:add_fn(name, fn, input_init, input_end)
  self.fn[name] = {fn = fn, fn_init = input_init, fn_end = input_end}
end

return anim