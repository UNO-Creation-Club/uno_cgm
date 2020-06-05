local u = require('utility')

local enums = {}

enums.direction = {CLOCKWISE = 1, ANTI_CLOCKWISE = 2}

enums.colors = {
  W = {u.normalize(255, 255, 255)},
  R = {u.normalize(255, 202, 186)},
  B = {u.normalize(191, 203, 255)},
  G = {u.normalize(180, 255, 156)},
  Y = {u.normalize(255, 255, 179)}
}

return enums