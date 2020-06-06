local final_points = {
  d_props = {points = 0}
}

function final_points:initialize(params)
  for k, v in pairs(params) do
    self[k] = v
  end
  self.anim:add_fn('CUBE', function(x) return (x^(1/6))/6 end, 0, 1)
end

function final_points:set(points)
  self.anim:move{obj = self, to = {points = points}, seconds = 1.2, fn = self.anim.fn.CUBE}
end

function final_points:get()
  return self.d_props.points
end

return final_points