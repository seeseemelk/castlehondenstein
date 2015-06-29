---
-- This class contains everything to respond to clicks, presses, ...
-- @class table
-- @name Controllable
class "Controllable"

local controllables = {}

--- Constructor
function Controllable:Controllable()
	-- Add to the controllables list
	controllables[#controllables + 1] = self
end

--- Destructor
function Controllable:_Controllable()
	-- Remove from the controllables list
	for index, controllable in ipairs(controllables) do
		if controllable == self then
			controllables[index] = controllables[#controllables]
			controllables[#controllables] = nil
			break
		end
	end
end

--- Callback when key pressed down
-- @param key The key pressed
-- @param isRepeat Whether this keypress event is a repeat
-- @see https://love2d.org/wiki/KeyConstant for the keys
function Controllable:onKeyPressed(key, isRepeat)
end

--- Callback when a key is released
-- @param key The key released
-- @see https://love2d.org/wiki/KeyConstant for the keys
function Controllable:onKeyReleased(key)
end

--- Callback when the window loses or receives focus
-- @param focus True if it gained focus, false if it lost focus
function Controllable:onMouseFocus(focus)
end

--- Callback when the mouse is moved
-- @param x The current x coordinate
-- @param y The current y coordinate
-- @param dx The amount it moved along the x-axis since last time
-- @param dy The amount it moved along the y-axis since last time
function Controllable:onMouseMoved(x, y, dx, dy)
end

--- Callback when a mouse button is pressed
-- @param x X coordinate of the mouse
-- @param y Y coordinate of the mouse
-- @param button Button that is pressed (l | m | r | wd | wu | x1 | x2)
-- @see https://love2d.org/wiki/MouseConstant for the button constants
function Controllable:onMousePressed(x, y, button)
end

--- Callback when a mouse button is released
-- @param x X coordinate of the mouse
-- @param y Y coordinate of the mouse
-- @param button Button that is released (l | m | r | wd | wu | x1 | x2)
-- @see https://love2d.org/wiki/MouseConstant for the button constants
function Controllable:onMouseReleased(x, y, button)
end

--- Callback when the user has typed somthing
-- This function handles UTF-8. Use this for
-- input box such as a chat box.
-- @param text Text that has been entered
function Controllable:onTextInput(text)
end


function love.keypressed(key, isRepeat)
	for _, c in ipairs(controllables) do
		c:onKeyPressed(key, isRepeat)
	end
end

function love.keyreleased(key)
	for _, c in ipairs(controllables) do
		c:onKeyReleased(key, isRepeat)
	end
end

function love.mousepressed(x, y, button)
	for _, c in ipairs(controllables) do
		c:onMousePressed(x, y, button)
	end
end

function love.mousereleased(x, y, button)
	for _, c in ipairs(controllables) do
		c:onMouseReleased(x, y, button)
	end
end

function love.mousemoved(x, y, dx, dy)
	for _, c in ipairs(controllables) do
		c:onMouseMoved(x, y, dx, dy)
	end
end