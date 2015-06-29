class "Grenade" (Drawable, Timer)

local images = {}
images.shot = love.graphics.newImage("resources/graphics/shot.png")
images.grenade = love.graphics.newImage("resources/graphics/grenade.png")

function Grenade:Grenade(x, y, speedX, speedY)
	Drawable.Drawable(self, x, y)
	Timer.Timer(self)

	self.x, self.y = x, y
	self.speedX, self.speedY = speedX, speedY
	self.exploding = false
	self.explosionRadius = 3

	self:addTimer(.2, "move")
	self.explodeTimer = self:addTimer(3, "explode")
	game:addChild(self)
	game.map:addObject(self)
end

function Grenade:_Grenade()
	game:removeChild(self)
	game.map:removeObject(self)
	Drawable._Drawable(self)
	Timer._Timer(self)
end

function Grenade:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(images.grenade, self.x * 16, self.y * 16)

	if self.exploding then
		for i = 0, 4 do
			love.graphics.draw(images.shot,
				self.x * 16 + math.random(-16, 16),
				self.y * 16 + math.random(-16, 16))
		end
	end
end

function Grenade:move()
	local newX = self.x + self.speedX
	local newY = self.y + self.speedY

	if game.map:isAnythingAt(newX, newY) then
		self.speedX, self.speedY = 0, 0
	else
		self.x, self.y = newX, newY
	end
end

function Grenade:explode()
	print("Exploded")
	self.exploding = true
	self.speedX, self.speedY = 0, 0

	self:removeTimer(self.explodeTimer)
	self.explodeTimer = self:addTimer(.5, "stopExplode")
end

function Grenade:stopExplode()
	-- Destroy wall
	local startX = math.max(self.x - 5, -game.map.roomWidth / 2 + 1)
	local endX = math.min(self.x + 5, game.map.roomWidth / 2 - 1)
	local startY = math.max(self.y - 5, -game.map.roomHeight / 2 + 1)
	local endY = math.min(self.y + 5, game.map.roomHeight / 2 - 1)

	for ix = startX, endX do
		for iy = startY, endY do
			local dx = math.abs(self.x - ix)
			local dy = math.abs(self.y - iy)
			local distance = math.sqrt(dx^2 + dy^2)

			if distance <= self.explosionRadius then
				game.map.currentRoom[ix][iy] = "empty"
			end
		end
	end

	-- Kill nazi scumbag
	for _, nazi in ipairs(game.map.currentRoom.nazi) do
		for ix = nazi.x, nazi.x + 2, 2 do
			for iy = nazi.y, nazi.y + 2, 2 do
				local dx = math.abs(self.x - ix)
				local dy = math.abs(self.y - iy)
				local distance = math.sqrt(dx^2 + dy^2)

				if distance <= self.explosionRadius then
					nazi:kill()
				end
			end
		end
	end

	delete(self)
end