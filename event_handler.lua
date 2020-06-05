local event_handler = {
  _pending = {},
}

function event_handler:dispatch(event)
  table.insert(self._pending, event)
end

function event_handler:on_receiving(event)
  -- to be defined by user
end

function event_handler:update(dt)
  local k, event = next(self._pending)
  if event then
    table.remove(self._pending, k)
    self:on_receiving(event)
  end
end

return event_handler