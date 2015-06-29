---
-- This class contains some basic drawing behaviour
-- @class table
-- @name Drawable
class "Drawable"

--- Constructor
-- @param x X coordinate of the Drawable
-- @param y Y coordinate of the Drawable
function Drawable:Drawable(x, y)
	self.x, self.y = x, y
end

--- Destructor
function Drawable:_Drawable()
end

---
-- Draw callback. This is fired every frame.
-- You have to override this.
function Drawable:draw()
	love.graphics.setColor(0, 255, 0)
	love.graphics.print("Hello world!", self.x, self.y)
end