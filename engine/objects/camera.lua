---
-- The camera class. A camera will render anything
-- that you add to it with relative to its own
-- x and y coordinate
-- @class table
-- @name Camera
class "Camera"

-- This table contains all cameras to draw
-- Normally only used by love.draw and Camera
local cameras = {}

---
-- Constructor
-- @param x The X coordinate of the camera
-- @param y The Y coordinate of the camera
function Camera:Camera(x, y)
	self.x = -x + love.graphics.getWidth() / 2
	self.y = -y + love.graphics.getHeight() / 2
	self.children = {}

	-- Add to list of cameras
	cameras[#cameras + 1] = self
end

---
-- Destructor
function Camera:_Camera()
	-- Remove from list of cameras
	for index, camera in ipairs(cameras) do
		if camera == self then
			cameras[index] = cameras[#cameras]
			cameras[#cameras] = nil
			break
		end
	end
end

---Deze functie zorgt ervoor dat de camera kan bewegen.
-- @param x de x coordinaat van de camera
-- @param y de y coordinaat van de camera
function Camera:translate(x, y)
	self.x = -x + love.graphics.getWidth() / 2
	self.y = -y + love.graphics.getHeight() / 2
end

---
-- Draw the cameras children
-- Automatically called by love.draw
function Camera:draw()
	love.graphics.translate(self.x, self.y)
	for _, child in ipairs(self.children) do
		child:draw()
	end
end

---
-- Add a child to the camera
-- @param child Child to add
-- @return The newly added child
function Camera:addChild(child)
	assert(child, "Can't add nil to the camera")
	assert(child ~= self, "Can't add self to camera")

	self.children[#self.children + 1] = child
	return child
end

---
-- Remove a child from the camera
-- @param child Child to remove
-- @return The removed child
function Camera:removeChild(child)
	for index, childb in ipairs(self.children) do
		if childb == child then
			self.children[index] = self.children[#self.children]
			self.children[#self.children] = nil
			return child
		end
	end
end

function love.draw()
	for _, camera in ipairs(cameras) do
		camera:draw()
	end
end