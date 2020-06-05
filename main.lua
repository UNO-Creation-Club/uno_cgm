local game = require('game')

_coroutine_resume = coroutine.resume
function coroutine.resume(...)
	local state,result = _coroutine_resume(...)
	if not state then
		error( tostring(result), 2 )	-- Output error message
	end
	return state,result
end

function love.load()
  -- math.randomseed( os.time() )

  love.window.setTitle('UNO')
  font = love.graphics.newImageFont("assets/images/image_font.png",
    " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"{}_")
  love.graphics.setFont(font)

  game:load({'Chintu', 'Mintu', 'Bunty'})
end

function love.update(dt)
  game:update(dt)
end

function love.draw()
  game:draw()
end

function love.mousepressed(x, y)
  game:mousepressed(x, y)
end

function love.mousemoved(x, y)
  game:mousemoved(x,  y)
end

-- function love.keypressed(key)
--   game:keypressed(key)
-- end

--------------
-- COMMENTS --
--------------

--[[

  1. (DONE) Load the card sheet image.
  2. (DONE) Cut out individual cards from it!
  3. (DONE) 'draw' them on the screen.
  4. Drawing Player's hand of cards and top card
  5. Acc. to how the game proceeds display of valid cards for the user to drop
 
  New work
  1. Highlight the card on hovering
  2. Dropping of card into discard_pile with displaying the card dropped 
  3. Restructing the player's hand everytime a card is dropped or drawn or when +2/+4.
  4. Drawing a card from draw pile



]]



-- sample_card = {value = 'R0', d_props = {x = 0, y = 0, r = 0, quad, ...}}
-- player = {name, cards = {'R0', 'G1', 'BD', 'W1'}}
