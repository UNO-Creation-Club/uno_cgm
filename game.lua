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

local bg_darkener = require('bg_darkener')
local final_points = require('final_points')

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

bg_darkener:initialize{
  anim = anim,
}

final_points:initialize{
  anim = anim,
}

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
  bg_darkener = bg_darkener,
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
    {x = love.graphics.getWidth() * 3 / 5, y = love.graphics.getHeight() * 4.2 / 5},
    {x = love.graphics.getWidth() * 1 / 4, y = 125},
    {x = love.graphics.getWidth() * 3 / 4, y = 125}
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
  state.draw_pile:activate()
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
local function generate_valid_cards(player, top_card, deck_suit)
  -- gives valid moves for the curr_player
  player.valid_card_indices = {} 
  for i = 1, #player.cards do
      if not is_card_playable(player.cards[i], top_card, deck_suit) then
        player.valid_card_indices[i] = false
        player:deactivate_card(player.cards[i])
      else
          player.valid_card_indices[i] = true
          player:activate_card(player.cards[i]) -- if in previous turn it was deactivated, it will activate in new turn?
      end
  end
  player.selected_card_id = 1
end

-- TODO
function apply_rules_first_time(state)
  -- if it's draw 2, give state.curr_player 2 cards and skip his turn
  -- if it's a skip, skip state.curr_player's turn
  -- if it's a reverse, change direction. curr_player remains same
  -- if it's a wild 4, return the card to the bottom of the draw_pile
  -- if it's a wild, curr_player chooses the color
  -- state.phase = 'first time'
  if true then return event_handler:dispatch{name = 'game_over'} end
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
    state.phase = 'running'
  end
  generate_valid_cards(state.curr_player, initial_top_card, state.deck_suit)
  -- for i = 1, #state.curr_player.cards do
  --   if not is_card_playable(state.curr_player.cards[i], initial_top_card, state.deck_suit) then
  --       state.curr_player:deactivate_card(state.curr_player.cards[i])
  --   end
  -- end
end

-- TODO
function apply_rules(state)
-- if it's draw 2, give next player 2 cards and skip his turn
-- if it's a skip, skip next player's turn
-- if it's a reverse, change direction
-- if it's a wild 4, attempt to give the next player 4 cards, allow him to challenge the current player, current player chooses the color
-- if it's a wild, curr_player chooses the deck_suit
  if #state.curr_player.cards <= 0 then
    return event_handler:dispatch({name = 'game_over'})
  end
  local top_card = state.discard_pile:peek_top_card()
  if top_card:get_rank() == "D" then
    update_player(state)
    for i=1, 2 do
      state.curr_player:add(state.draw_pile:remove())
    end
  elseif top_card:get_rank() == "S" then
    update_player(state)
  elseif top_card:get_rank() == "R" then
    change_direction(state)
  elseif top_card:get_suit() == "W" then
    -- if game.state.phase == 'running' then
    --   game.state.phase = 'halted'
    event_handler:dispatch({name = 'halt_game'})
    game.state.phase = 'running'
    if top_card:get_rank() == "4" then
      for i = 1, 4 do
        get_next_player(state):add(state.draw_pile:remove())
      end
    end
    -- Colour Choosing -- Update deck_suit --
  end
  update_player(state)
  generate_valid_cards(state.curr_player, top_card, state.deck_suit)
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
  return value
end

-- COMPLETE
local function get_player_cards_value(p)
  local value = 0
  for i, c in ipairs(p.cards) do
    value = value + get_card_value(c)
  end
  return value
end

-- COMPLETE
local function get_points_for_winner(winner_id, players)
  assert(winner_id, 'winner_id not present!')
  assert(players, 'players not present!')
  local value = 0
  for i, p in ipairs(players) do
    if i ~= winner_id then
      value = value + get_player_cards_value(p)
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
    bg_darkener:activate()
  elseif event.name == 'card_played' then
    -- do things realted to card being played
    game.state.curr_player.valid_card_indices = {}
    game.state.discard_pile:add(game.state.curr_player:remove(event.type))
    game.state.draw_pile:activate()
    apply_rules(game.state)
  elseif event.name == 'color_selected' then
    game.state.deck_suit = event.type
    generate_valid_cards(game.state.curr_player, game.state.discard_pile:peek_top_card(), game.state.deck_suit)
    game.state.draw_pile:activate()
    game.state.curr_player:activate()
    color_buttons:hide()
    bg_darkener:deactivate()
    generate_valid_cards(game.state.curr_player, game.state.discard_pile:peek_top_card(), game.state.deck_suit)
  elseif event.name == 'card_picked' then
      game.state.draw_pile:deactivate()
      if not is_card_playable(event.type, game.state.discard_pile:peek_top_card(), game.state.deck_suit) then
        update_player(game.state)
      end
      generate_valid_cards(game.state.curr_player, game.state.discard_pile:peek_top_card(), game.state.deck_suit)
      
    elseif event.name == 'game_over' then
      game.state.phase = 'over'
      final_points:set(get_points_for_winner(game.state.curr_player_id, game.state.players))
      game.state.draw_pile:deactivate()
      for i, p in ipairs(game.state.players) do
        if game.state.curr_player ~= p then
          p:show_cards()
        else
          p:deactivate()
        end
      end
      color_buttons:hide()
      bg_darkener:activate()
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
  self.state.draw_pile:prime_top()
  for _, c in ipairs(game.state.curr_player.cards) do
    c:show()
  end

  apply_rules_first_time(self.state)
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

  bg_darkener:draw()
  color_buttons:draw()

  if self.state.phase == 'over' then
    love.graphics.printf(string.format('%s won by %d points!', self.state.curr_player.name, final_points:get()), love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2, 400, 'center')
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

----------

-- To be fixed --

--D 1.The deck_suit does not get updated after colour selection.
--D 2.The valid_card selection has a problem when 'W' is the top_card, 
-- as we even match the rank for selecting a valid card, cards with rank 1/4 irrespective of the deck suit get selected
--D 3.No end game happens. (Nothing happens when a player's cards run out.)
--D 4. When selection is nil, player can still play some card when space is pressed. 
      -- added a condition in game.keypressed for space, #game.state.curr_player.valid_card_indices ~= 0 -- Works


-- More features --

--D 5. if you pick a card, you cannot play any card other than that card
-- so even if you had other valid cards, after picking, they will not be counted as valid playable cards
-- 6. a 'pass' button to pass one's turn
-- 7. "UNO" option and its penalty

-- Bugs!!!

--[[

S 1. top_card is hidden
  2. the cards being drawn can't be dropped
3. when W/W4 is dropped it waits for current player only to drop another card
4. we have to have soemthing for colour selection
5. the game direction is random
6. when +2/W4 are played the cards are on top of the deck, they don't directly go to the player
7. cards get stuck up sometimes after hover
8. 

]]