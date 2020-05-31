----------------------------------------------------------------

-- TO DO LIST:

--[[

> while initializing players, set their (x, y) via set_position(x, y).


]]
----------------------------------------------------------------
local card = require('card')
local player = require('player')
local hitbox = require('hitbox')
local anim = require('anim')
local u = require('utility')

local game = {
  -- phase = 'development'
}

--[[

game : table<dynamic>

game.state : table<dynamic>

game.state.players : table<player : {name : string, cards : table<string>}>

game.state.curr_player : number
game.state.draw_pile : table<string>
game.state.discard_pile : table<string>
game.state.direction : game.direction<enum> : {CLOCKWISE = 1, ANTI_CLOCKWISE = 2}
game.state.deck_suit : string
game.state.phase : string : {'running', 'over'}


game.client_info : table<dynamic>
game.client_info.player_id : number

]]

-- Enumerations

local direction = {CLOCKWISE = 1, ANTI_CLOCKWISE = 2}
local anim_locs = {
  discard_pile = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2, r = u.lerp(math.random(), 0, 1, 0, math.pi)},
  draw_pile = {x = 100, y = 450}
}
local colors = {
  W = {u.normalize(255, 255, 255)},
  R = {u.normalize(255, 202, 186)},
  B = {u.normalize(191, 203, 255)},
  G = {u.normalize(180, 255, 156)},
  Y = {u.normalize(255, 255, 179)}
}

-- Card getters


local function peek_top_of_draw_pile(state)
  return state.draw_pile[#state.draw_pile]
end

local function animate_background_to(color)
  anim:move{obj = game.bg, to = {r = colors[color][1], g = colors[color][2], b = colors[color][3], a = colors[color][4]}}
end

-- COMPLETE
local function get_card_from_draw_pile(state) -- return_type: string
  -- get top card from draw_pile
  -- when draw_pile is finished, reshuffle the cards from the discard pile into the draw_pile, and make the discard_pile empty. then return a new card from draw_pile
  local draw_pile, discard_pile = state.draw_pile, state.discard_pile
  if #draw_pile < 1 then -- draw_pile is empty! time to reshuffle the discard_pile and make it the draw_pile
    table.insert(draw_pile, table.remove(discard_pile, 1))
    while #discard_pile > 1 do -- we'll take every card except the top one i.e. last one
      table.insert(draw_pile, math.random(#draw_pile), table.remove(discard_pile, 1))
    end
  end
  local c = table.remove(draw_pile)
  c:change_d_props{r = 0}
  hitbox:place{ -- place a hitbox on the next card in line
    id = 'draw pile', 
    obj = peek_top_of_draw_pile(state),
    on_click = function (c) 
      get_card_from_draw_pile(state)
      state.curr_player:add_card(c)
    end,
  }
  return c
end

-- COMPLETE
local function get_top_card(discard_pile)
  -- the last card is the top one
  return discard_pile[#discard_pile]
end

-- COMPLETE
local function set_top_card(card, state)
  -- place card on state.discard_pile
  -- update state.deck_suit
  table.insert(state.discard_pile, card)
  state.deck_suit = card:get_suit()
end

-- Initialization routines

-- COMPLETE, TESTED
local function build_deck() -- return_type : table
  -- return an UNO deck
  -- {'R0', 'R1', ... 'G0', 'G1', 'G2', ... 'W1', 'Wri1', ...}

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
  if state.direction == direction.CLOCKWISE then
    return state.curr_player_id == #state.players and 1 or state.curr_player_id + 1
  else
    return state.curr_player_id == 1 and #state.players or state.curr_player_id - 1
  end
end

local function get_next_player(state)
  return state.players[get_next_player_id(state)]
end

-- COMPLETE
local function initialize_players(state, players_names)
  state.players = {}
  local random_coordinates = {
    {x = love.graphics.getWidth() * 3 / 5, y = love.graphics.getHeight() * 4 / 5},
    {x = love.graphics.getWidth() * 1 / 4, y = 150},
    {x = love.graphics.getWidth() * 3 / 4, y = 150}
  }

  for i, name in ipairs(players_names) do
    local random_hand = {}
    for j = 1, 7 do
      random_hand[j] = get_card_from_draw_pile(state)
                       :change_l_props{belongs_to = name, player_id = i, card_id = j}
      hitbox:place{
        id = string.format('player %d cards', i),
        obj = random_hand[j],
        on_click = function(self)
          -- logic
          set_top_card(self, state)
          state.players[self.l_props.player_id]:remove_card(self)
          for _, c in ipairs(state.curr_player.cards) do
            c:hide()
          end
          hitbox:deactivate_region(string.format('player %d cards', state.curr_player_id))
          coroutine.resume(apply_rules, state)
          for _, c in ipairs(state.curr_player.cards) do
            c:show()
          end
          hitbox:activate_region(string.format('player %d cards', state.curr_player_id))
          -- drawing
          animate_background_to(self:get_suit())
        end,
        on_enter = function(self)
          anim:move{
            obj = self,
            to = {y = self.d_props.y_final}
          }
        end,
        on_exit = function(self)
          anim:move{
            obj = self,
            to = {y = self.d_props.y_init}
          }
        end
      }
    end
    state.players[i] = player:create(name, i, random_hand, random_coordinates[i])
    -- state.players[i]:set_position(x, y)
  end

  state.curr_player_id = 1
  state.curr_player = state.players[state.curr_player_id]
end

local function get_curr_player(state)
  return state.curr_player
end

-- COMPLETE
local function initialize_draw_pile(deck, state)
  state.draw_pile = {}
  -- insert items from deck randomly into state.draw_pile
  -- make sure deck's contents do not change
  table.insert(state.draw_pile, deck[1])
  for i = 2, #deck do
    table.insert(state.draw_pile, math.random(#state.draw_pile), deck[i])
  end
  state.draw_pile[1]:change_d_props(anim_locs.draw_pile):change_l_props({belongs_to='draw_pile'})
  for i, c in ipairs(state.draw_pile) do
    if i ~= 1 then
      c:change_d_props{x = state.draw_pile[i-1].d_props.x - 0.15, y = state.draw_pile[i-1].d_props.y - 0.15}:change_l_props{belongs_to='draw_pile'}
    end
    hitbox:place{
      id = 'draw pile', 
      obj = c, 
      on_click = function (c) get_curr_player(state):add_card(c) end
    }
  end
end

-- COMPLETE
local function initialize_discard_pile(state)
  state.discard_pile = {}
  local c = get_card_from_draw_pile(state)
  c:change_l_props{belongs_to = 'discard_pile'}:show()
  anim:move{obj = c, to = anim_locs.discard_pile}
  animate_background_to(c:get_suit())
  table.insert(state.discard_pile, c)
end

-- Rules enforcement

-- TODO 
local function change_direction(state)
    if state.direction == direction.CLOCKWISE then
        state.direction = direction.ANTI_CLOCKWISE
    else
        state.direction = direction.CLOCKWISE
    end
end


-- TODO
local function update_player(state)
  state.curr_player.card_drawn = false
  state.curr_player_id = get_next_player_id(state)
  state.curr_player = state.players[state.curr_player_id]
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
          table.insert(player.valid_card_indices, i)
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
  local initial_top_card = get_top_card(state.discard_pile)

  if initial_top_card:get_rank() == "D" then
    for i=1, 2 do 
        table.insert(
          state.curr_player.cards,
          get_card_from_draw_pile(state)
          :change_l_props{
            belongs_to = state.curr_player,
            player_id = state.curr_player_id,
            card_id = #state.curr_player.cards
          }
      )
    end
    update_player(state) 
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit) 

  elseif initial_top_card:get_rank() == "S" then
    update_player(state)
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
  elseif initial_top_card:get_rank() == "R" then
    change_direction(state)
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
  elseif initial_top_card:get_value() == "W4" then
    table.insert(state.draw_pile, 1, initial_top_card) --?
    set_top_card(get_card_from_draw_pile(state), state)
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
  elseif initial_top_card:get_value() == "W1" then
    -- halt operation, wait for user to select a suit, continue operation
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
    game.state.phase = 'halted'
    state.deck_suit = coroutine.yield()
    game.state.phase = 'running'
    generate_valid_card_indices(state.curr_player, initial_top_card, state.deck_suit)
  end
end)


-- TODO
apply_rules = coroutine.create(function (state)
  -- if it's draw 2, give next player 2 cards and skip his turn
  -- if it's a skip, skip next player's turn
  -- if it's a reverse, change direction
  -- if it's a wild 4, attempt to give the next player 4 cards, allow him to challenge the current player, current player chooses the color
  -- if it's a wild, curr_player chooses the deck_suit
  while true do
    local top_card = get_top_card(state.discard_pile)
    if top_card:get_rank() == "D" then
      update_player(state)
      for i=1, 2 do 
          table.insert(state.curr_player.cards,get_card_from_draw_pile(state))
      end

    elseif top_card:get_rank() == "S" then
      update_player(state)
    
    elseif top_card:get_rank() == "R" then
      change_direction(state)
    
    elseif top_card:get_suit() == "W" then
      -- halt hehehe
      game.state.phase = 'halted'
      game.state.deck_suit = coroutine.yield()
      game.state.phase = 'running'
      if top_card:get_rank() == "4" then
          for i = 1, 4 do
              table.insert(get_next_player(state).cards, get_card_from_draw_pile(state))
          end
      end
      -- Colour Choosing -- Update deck_suit --
    end
    update_player(state) 
    generate_valid_card_indices(state.curr_player, top_card, state.deck_suit)
    coroutine.yield()
  end
end)

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

-- Primary drawing functions (primitive implementation, just for testing and debugging) (Later on, these will be superseded by actual graphical drawing routines)

-- COMPLETE, TESTED
local function show_player(player, is_current)
  if is_current then
    player:draw()
  else
    player:draw('hidden')
  end
end

-- COMPLETE, TESTED
local function show_players(state, window_dimensions)
  local dims = window_dimensions
  local a, b = 1 / (dims.x * 2.5), dims.y / 3 -- this can be moved into game:load(...) so that we don't need to do useless calculations 60 times a second
  -- players placed in a curve : a(x-window_dimensions.x)(x) + b
  local n = #state.players
  local separation = dims.x / (n + 1)
  for i, p in ipairs(state.players) do
    local x = i * separation
    show_player(p, i == state.curr_player_id, x, a * (x - dims.x) * (x) + b, window_dimensions)
  end
end

-- COMPLETE
local function show_draw_pile(draw_pile, window_dimensions)
  -- love.graphics.printf has word_wrap and alignment as well!
  -- Here, word_wrap has been used
  for _, card in ipairs(draw_pile) do
    card:draw('hidden')
  end
  -- love.graphics.printf(string.format('draw pile: %s', 'table_string_nr(draw_pile)'), window_dimensions.x / 2 - window_dimensions.x / 3, window_dimensions.y / 2, window_dimensions.x / 3 - 5)
end

-- COMPLETE
local function show_discard_pile(discard_pile, window_dimensions)
  -- love.graphics.printf(string.format('Discard Pile: %s', 'table_string_nr(discard_pile)'), window_dimensions.x / 2 + 5, window_dimensions.y / 2, window_dimensions.x / 3 - 5)
  for i, card in ipairs(discard_pile) do
    card:draw()
  end
end

local function show_deck_suit(deck_suit, window_dimensions)
    love.graphics.print(string.format('Deck Suit: %s', deck_suit), window_dimensions.x / 2 + 5, window_dimensions.y / 2 - 20)
end

-- Selection shifting

local function move_selection_left(curr_player)
  curr_player.selected_card_id = curr_player.selected_card_id == 1 and #curr_player.valid_card_indices or curr_player.selected_card_id - 1
end

local function move_selection_right(curr_player)
  curr_player.selected_card_id = (curr_player.selected_card_id % #curr_player.valid_card_indices) + 1
end

-- Love2D integration functions

-- PARTIALLY COMPLETE
function game:load(players_names)
  math.randomseed( os.time() )

  self.bg = {d_props = {r = colors.W[1], g = colors.W[2], b = colors.W[3], a = colors.W[4]}, while_animating = function(self) love.graphics.setBackgroundColor(self.d_props.r, self.d_props.g, self.d_props.b, self.d_props.a) end}
  self.window_dimensions = {x = love.graphics.getWidth(), y = love.graphics.getHeight()}
  -- put this function in love.load()

  player_names = player_names or {'A', 'B', 'C'} -- if nothing is passed, we'll assume these 3 random names
  
  self.state = {}
  self.state.direction = direction.CLOCKWISE
  self.state.phase = 'running'
  -- Cannot initialize players without having a draw_pile first!
  local deck = build_deck()
  initialize_draw_pile(deck, self.state)
  -- Now that we have a draw pile, we'll initialize the players
  initialize_players(self.state, players_names)
  -- Finally, we add 1 card to the discard_pile
  initialize_discard_pile(self.state)
  -- At this point, we have some players with random cards; a shuffled draw_pile; a discard_pile with a card on top
  -- Other initialization tasks

  self.state.deck_suit = self.state.discard_pile[#self.state.discard_pile]:get_suit()
  coroutine.resume(apply_rules_first_time, self.state)

  -- Hitbox regions
  hitbox:define_region('player 1 cards', {x = 200, y = 320, width =  600, height = 260})
  hitbox:define_region('player 2 cards', {x = 0, y = 0, width =  400, height = 260})
  hitbox:define_region('player 3 cards', {x = 400, y = 0, width = 400, height = 260})
  hitbox:define_region('draw pile', {x = 0, y = 320, width = 200, height = 260})

  hitbox:activate_region(string.format('player %d cards', game.state.curr_player_id))
  hitbox:activate_region('draw pile')

  for _, c in ipairs(game.state.curr_player.cards) do
    c:show()
  end
end

-- TODO
function game:update(dt)
  -- put this function in love.update(dt)
  anim:update(dt)
  hitbox:update(dt)
end

-- PARTIALLY COMPLETE
function game:draw()
  -- put this function in love.draw()
  show_draw_pile(self.state.draw_pile, self.window_dimensions)
  show_discard_pile(self.state.discard_pile, self.window_dimensions)
  show_players(self.state, self.window_dimensions)
  if self.state.phase == 'over' then
    -- show final score
  end

  if game.phase == 'development' then
    show_deck_suit(self.state.deck_suit, self.window_dimensions)
    hitbox:draw_regions() -- debugging purposes, will show what regions we have defined

    love.graphics.print(string.format('(%s, %s)', love.mouse.getX(), love.mouse.getY()), 0, 0)
    love.graphics.print(string.format('%s\n%s\n%s\n%s', u.table_string_nr(self.state.curr_player.cards), u.table_string_nr(self.state.draw_pile), u.table_string_nr(self.state.discard_pile), hitbox.message), love.mouse.getX() + 10, love.mouse.getY())
  end
end

function game:mousepressed(x, y)
  hitbox:update_static_position(x, y)
end

function game:mousemoved(x, y)
  hitbox:update_dynamic_position(x, y)
end

function game:keypressed(key)
  local curr_player = game.state.curr_player
  if game.state.phase == 'running' then
    if key == 'left' then -- move card selection left for current player's valid cards
      move_selection_left(curr_player)
    elseif key == 'right' then -- move card selection right for current player's valid cards
      move_selection_right(curr_player)
      
    elseif key == 'space' and #game.state.curr_player.valid_card_indices ~= 0 then -- play the current selected card of current player and update the player (?) (this already happens in apply rules yes?) Yes ok
      -- add current selected card to the top of the discard_pile
      set_top_card(table.remove(curr_player.cards, curr_player.valid_card_indices[curr_player.selected_card_id]), game.state)
      check_game_termination(game.state)
      if game.state.phase ~= 'over' then
        coroutine.resume(apply_rules, game.state)
      end
    elseif not curr_player.card_drawn and key == 'p' then
      -- pick a card from draw_pile
      local card = get_card_from_draw_pile(game.state)
      table.insert(curr_player.cards, card)
      game.state.curr_player.card_drawn = true
      for i in pairs(game.state.curr_player.valid_card_indices) do
        game.state.curr_player.valid_card_indices[i] = nil
      end
      if is_card_playable(card, get_top_card(game.state.discard_pile), game.state.deck_suit) then 
        table.insert(curr_player.valid_card_indices, #curr_player.cards)
      end
    --   generate_valid_card_indices(curr_player, get_top_card(game.state.discard_pile), game.state.deck_suit)
      if #game.state.curr_player.valid_card_indices == 0 then
        update_player(game.state)
        generate_valid_card_indices(game.state.curr_player, get_top_card(game.state.discard_pile), game.state.deck_suit)
      end
      
    end
  elseif game.state.phase == 'halted' then
       if key == 'r' or key == 'g' or key == 'b' or key == 'y' then
            if coroutine.status(apply_rules_first_time) == 'suspended' then
                coroutine.resume(apply_rules_first_time, key:upper())
              elseif coroutine.status(apply_rules) == 'suspended' then
                coroutine.resume(apply_rules, key:upper())
            end
        end
  end
end

----------
return game


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