----------------------------------------------------------------

-- TO DO LIST:

--[[

> while initializing players, set their (x, y) via set_position(x, y).


]]
----------------------------------------------------------------
local card = require('card')
local player = require('player')
local discard_pile = require('discard_pile')
local draw_pile = require('draw_pile')
local color_buttons = require('color_buttons')

local hitbox = require('hitbox')
local anim = require('anim')
local event_handler = require('event_handler')

local enums = require('enums')
local u = require('utility')

local game = {
  -- phase = 'development',
  state = {},
  messages = {}
}

-- Initialization routines

draw_pile:initialize{
  state = game.state,
  hitbox = hitbox,
  anim = anim,
  event_handler = event_handler,
}

discard_pile:initialize{
  state = game.state,
  hitbox = hitbox,
  anim = anim,
  event_handler = event_handler,
}

player:initialize{
  state = game.state,
  hitbox = hitbox,
  anim = anim,
  event_handler = event_handler,
}

card:initialize{
  state = game.state,
  hitbox = hitbox,
  anim = anim,
  event_handler = event_handler,
}

color_buttons:initialize{
  state = game.state,
  hitbox = hitbox,
  anim = anim,
  event_handler = event_handler,
}

local function build_deck() 
  local suits = {'R', 'Y', 'G', 'B'}
  local ranks = {'1', '2', '3', '4', '5', '6', '7', '8', '9', 'S', 'R', 'D'}

  local deck = {}

  for _, suit in ipairs(suits) do
      table.insert(deck, card:create({value = suit .. '0'}))
    end
    
    for _, suit in ipairs(suits) do
      for _, rank in ipairs(ranks) do
        table.insert(deck, card:create({value = suit .. rank}))
        table.insert(deck, card:create({value = suit .. rank}))
      end
    end

    for i = 1, 4 do
      table.insert(deck, card:create({value = 'W1'}))
      table.insert(deck, card:create({value = 'W4'}))
    end

  return deck
end

local function get_next_player_id(state)
  -- returns the next player on the basis of state.direction
  if state.direction == enums.direction.CLOCKWISE then
    return state.curr_player_id == #state.players and 1 or state.curr_player_id + 1
  else
    return state.curr_player_id == 1 and #state.players or state.curr_player_id - 1
  end
end

local function set_curr_player(state, player_id)
  state.curr_player_id = player_id
  state.curr_player = state.players[state.curr_player_id]
end

local function get_curr_player(state)
  return state.curr_player
end

local function get_next_player(state)
  return state.players[get_next_player_id(state)]
end

local function initialize_players(state, player_names)
  state.players = {}

  -- drawing regions
  local random_coordinates = {
    {x = love.graphics.getWidth() * 3 / 5, y = love.graphics.getHeight() * 4 / 5},
    {x = love.graphics.getWidth() * 1 / 4, y = 150},
    {x = love.graphics.getWidth() * 3 / 4, y = 150}
  }

  -- hitbox regions
  hitbox:define_region(string.format('player_%s', player_names[1]), {x = 200, y = 320, width =  600, height = 260})
  hitbox:define_region(string.format('player_%s', player_names[2]), {x = 0, y = 0, width =  400, height = 260})
  hitbox:define_region(string.format('player_%s', player_names[3]), {x = 400, y = 0, width = 400, height = 260})
  hitbox:define_region('draw_pile', {x = 0, y = 320, width = 200, height = 260})
  
  for i, name in ipairs(player_names) do
    local cards = {}
    for j = 1, 7 do
      cards[j] = state.draw_pile:remove()
    end
    state.players[i] = player:create{
      name = name,
      id = i,
      cards = cards,
      position = random_coordinates[i]
    }
  end
  
  set_curr_player(state, 1)

  for i, c in ipairs(game.state.curr_player.cards) do
    c:show()
  end

  -- activating draw_pile and current player
  hitbox:activate_region(string.format('player_%s', game.state.curr_player.name))
  hitbox:activate_region('draw_pile')
end

-- Rules enforcement

local function change_direction(state)
    if state.direction == enums.direction.CLOCKWISE then
        state.direction = enums.direction.ANTI_CLOCKWISE
    else
        state.direction = enums.direction.CLOCKWISE
    end
end

-- TODO
local function update_player(state)
  state.curr_player.card_drawn = false
  state.curr_player_id = get_next_player_id(state)
  state.curr_player:deactivate()
  state.curr_player = state.players[state.curr_player_id]
  state.curr_player:activate()
end

-- COMPLETE
local function is_card_playable(card, top_card, deck_suit)
    -- added to ensure only the the card matching the deck_suit is played when a W card is the top_card
    if top_card:get_suit() == "W" then
        return card:get_suit() == deck_suit or card:get_suit() == "W"
    else
        return card:get_suit() == deck_suit or card:get_rank() == top_card:get_rank() or card:get_suit() == 'W'
    end
end

-- TODO
-- valid_card_indices needs to be an empty table for each player so creating it inside generate_valid_card_indices
local function generate_valid_card_indices(player, top_card, deck_suit)
  -- gives valid moves for the curr_player
  player.valid_card_indices = {}
  for i = 1, #player.cards do
      if is_card_playable(player.cards[i], top_card, deck_suit) then
          player.valid_card_indices[i] = true
      end
  end
  player.selected_card_id = 1
end

-- TODO
apply_rules_first_time = coroutine.create(function (state)
  -- if it's draw 2, give state.curr_player 2 cards and skip his turn
  -- if it's a skip, skip state.curr_player's turn
  -- if it's a reverse, change direction. curr_player remains same
  -- if it's a wild 4, return the card to the bottom of the draw_pile
  -- if it's a wild, curr_player chooses the color
  state.phase = 'first time'
  local initial_top_card = state.discard_pile:peek_top_card()

  if initial_top_card:get_rank() == "D" then
    for i=1, 2 do
      state.curr_player:add(state.draw_pile:remove())
    end
    update_player(state)
  elseif initial_top_card:get_rank() == "S" then
    update_player(state)
  elseif initial_top_card:get_rank() == "R" then
    change_direction(state)
  elseif initial_top_card:get_value() == "W4" then
    state.draw_pile:add_to_bottom(state.discard_pile:remove())
    local c = state.draw_pile:remove()
    state.discard_pile:add(c)
  elseif initial_top_card:get_value() == "W1" then
    event_handler:dispatch{name = 'halt_game'}
    -- state.deck_suit = coroutine.yield()
    coroutine.yield()
    state.phase = 'running'
  end
  generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
end)

-- TODO
function apply_rules(state)
-- if it's draw 2, give next player 2 cards and skip his turn
-- if it's a skip, skip next player's turn
-- if it's a reverse, change direction
-- if it's a wild 4, attempt to give the next player 4 cards, allow him to challenge the current player, current player chooses the color
-- if it's a wild, curr_player chooses the deck_suit
  local top_card = state.discard_pile:peek_top_card()
  if top_card:get_rank() == "D" then
    update_player(state)
    for i=1, 2 do 
      state.curr_player:add(draw_pile:remove())
    end
  elseif top_card:get_rank() == "S" then
    update_player(state)
  elseif top_card:get_rank() == "R" then
    change_direction(state)
  elseif top_card:get_suit() == "W" then
    if game.state.phase == 'running' then
      game.state.phase = 'halted'
      return event_handler:dispatch({name = 'halt_game'})
    end
    game.state.phase = 'running'
    if top_card:get_rank() == "4" then
      for i = 1, 4 do
        get_next_player(state):add(draw_pile:remove())
      end
    end
    -- Colour Choosing -- Update deck_suit --
  end
  update_player(state) 
  generate_valid_card_indices(state.curr_player, top_card, state.deck_suit)
end

local function check_game_termination(state)
    if #state.curr_player.cards == 0 then
        -- terminating game if player has no cards --
        state.phase = "over"
    end
end

-- Points calculation

-- COMPLETE
local function get_card_value(card)
  local value = 0
  if card:get_suit() == "W" then value = 50
  elseif string.match(card:get_rank(), '[DSR]') then value = 20
  elseif string.match(card:get_rank(), '[0-9]') then value = tonumber(card:get_rank())
  end
end

-- COMPLETE
local function get_player_cards_value(player)
  local value = 0
  for i, card in ipairs(player.cards) do
    value = value + get_card_value(card)
  end
  return value
end

-- COMPLETE
local function get_points_for_winner(winner_id, players)
  local value = 0
  for i, player in ipairs(players) do
    if i ~= winner_id then
      value = value + get_player_cards_value(player)
    end
  end
  return value
end

function trial(state)
  update_player(state)
end

function event_handler:on_receiving(event)
  if event.name == 'halt_game' then
    game.state.draw_pile:deactivate()
    game.state.curr_player:deactivate()
    color_buttons:show()
  elseif event.name == 'card_played' then
    -- do things realted to card being played
    game.state.discard_pile:add(game.state.curr_player:remove(event.type))
    trial(game.state)
    -- coroutine.resume(apply_rules, game.state)
  elseif event.name == 'color_selected' then
    game.state.deck_suit = event.type
    game.state.draw_pile:activate()
    if game.state.phase ~= 'first time' then
       update_player(game.state)
    end
    game.state.curr_player:activate()
    color_buttons:hide()
  end
end

-- Love2D integration functions
function game:load(players_names)
  self.state.bg = {d_props = {r = enums.colors.W[1], g = enums.colors.W[2], b = enums.colors.W[3], a = enums.colors.W[4]}, while_animating = function(self) love.graphics.setBackgroundColor(self.d_props.r, self.d_props.g, self.d_props.b, self.d_props.a) end}
  player_names = player_names or {'A', 'B', 'C'} -- if nothing is passed, we'll assume these 3 random names
  
  self.state.direction = enums.direction.CLOCKWISE
  self.state.phase = 'running'
  local deck = build_deck()
  self.state.draw_pile = draw_pile:create(deck)
  initialize_players(self.state, players_names)
  self.state.discard_pile = discard_pile:create(self.state.draw_pile:remove())
  coroutine.resume(apply_rules_first_time, self.state)
  self.state.draw_pile:prime_top()

  for _, c in ipairs(game.state.curr_player.cards) do
    c:show()
  end
end

-- TODO
function game:update(dt)
  anim:update(dt)
  hitbox:update(dt)
  event_handler:update(dt)
end

-- PARTIALLY COMPLETE
function game:draw()
  self.state.draw_pile:draw()
  self.state.discard_pile:draw()
  for i, p in ipairs(self.state.players) do
    p:draw()
  end

  color_buttons:draw()

  if self.state.phase == 'over' then
    -- show final score
  end

  if game.phase == 'development' then
    love.graphics.printf(self.state.deck_suit, 200, 200, 300)
    hitbox:draw_regions() -- debugging purposes, will show what regions we have defined


    love.graphics.print(string.format('(%s, %s)', love.mouse.getX(), love.mouse.getY()), 0, 0)
    love.graphics.print(string.format('%s\n%s\n%s\n%s', u.table_string_nr(self.state.curr_player.cards), u.table_string_nr(self.state.draw_pile), u.table_string_nr(self.state.discard_pile), hitbox.message), love.mouse.getX() + 10, love.mouse.getY())
  end

  love.graphics.printf(table.concat(game.messages, '\n'), 100, 100, 300)
end

function game:mousepressed(x, y)
  hitbox:update_click_position(x, y)
end

function game:mousemoved(x, y)
  hitbox:update_hover_position(x, y)
end

return game