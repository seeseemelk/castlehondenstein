class "Collidable"

function Collidable:Collidable(options)
	options = options or {}
	self.collision = {}
	self.collision.static = options.static or false
	self.collision.mass = options.mass --assert(options.mass, "No mass")

	assert(self.x, "No X coordinate")
	assert(self.y, "No Y coordinate")
	assert(self.width, "No width")
	assert(self.height, "No height")
end

function Collidable:_Collidable()
end

---
-- Checks if two objects are colliding using AABB
-- @param self Object to test
-- @param object Second object to test
-- @returns Bool, true if colliding, false otherwise
-- @usage object:collidesWith(otherObject)
-- @usage Collidable.collidesWith(object, otherObject)
function Collidable:collidesWith(object)
	--print(self.x, self.y, object.x, object.y)
	if self.x >= object.x and self.y >= object.y and
		self.x + self.width <= object.x + object.width and
		self.y + self.height <= object.y + object.height then
			return true
	end
	return false
end

---
-- Resolve a collision between two objects
-- @param self Object to move
-- @param dispX Amount of displacement on the X for self
-- @param dispY Amount of displacement on the Y for self
-- @param object Object that you collide with
-- @param dispBX Amount of displacement on the X for self
-- @param dispBY Amount of displacement on the Y for self
-- @usage object:collidesWith(otherObject)
-- @usage Collidable.collidesWith(object, otherObject)
function Collidable:resolve(dispX, dispY, object, dispBX, dispBY)
	if self:collidesWith(object) then
		local aX = self.x - dispX
		local aY = self.y - dispY
		local aW = self.width
		local aH = self.height

		local bX = object.x - dispBX
		local bY = object.y - dispBY
		local bW = object.width
		local bH = object.height

		local cX, cY = aX, aY

		if (aX + aW < bX or aX > bX + bW) and
		(aX + aW + dispX > bX or aX + dispX < bX + bW) then
			if dispX > 0 then
				cX = bX - aW
			else
				cX = bX + bW
			end
		elseif (aY + aH < bY or aY > bY + bH) and
		(aY + aH + dispY > bY or aY + dispY < bY + bH) then
			if dispY > 0 then
				cY = bY - aH
			else
				cY = bY + bH
			end
		end

		self.x = cX
		self.y = cY
	end
end