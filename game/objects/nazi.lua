class "Nazi" (Character, Timer)

local images = {}
images.nazileft = love.graphics.newImage("resources/graphics/baddie_left.png")
images.naziright = love.graphics.newImage("resources/graphics/baddie_right.png")
images.deadnazi = love.graphics.newImage("resources/graphics/body.png")
images.shot = love.graphics.newImage("resources/graphics/shot.png")

function Nazi:Nazi(x, y, room)
	Character.Character(self, x, y)
	Timer.Timer(self)

	self.running = false
	self.alive = true
	self.room = room

	self.walkingDirection = (math.random(0, 1) - .5) * 2
	self.direction = 1
	self.lastShot = 0

	self.inventory = {
		bullets = math.random(0, 10),
		grenades = math.random(0, 1)
	}

	game.map.rooms.totalEnemies = game.map.rooms.totalEnemies + 1
	game.map.rooms.livingEnemies = game.map.rooms.livingEnemies + 1

	self:addTimer(.3, "ai")
	game:addChild(self)
end

function Nazi:_Nazi()
	Character._Character(self)
	Timer._Timer(self)
end

function Nazi:enable()
	self.walkingDirection = self:findWalkingPath()
	self.running = true
end

function Nazi:disable()
	self.running = false
end

function Nazi:draw()
	if self.running then
		love.graphics.setColor(255, 255, 255)
		if self.alive then
			-- Draw living nazi
			if self.direction == -1 then
				love.graphics.draw(images.nazileft, self.x * 16, self.y * 16)
			else
				love.graphics.draw(images.naziright, self.x * 16, self.y * 16)
			end
		else
			-- Draw dead nazi
			love.graphics.setColor(213, 223, 124)
			love.graphics.draw(images.deadnazi, self.x * 16, self.y * 16)
		end

		-- Draw gun shot
		if love.timer.getTime() - self.lastShot < .1 then
			love.graphics.draw(images.shot, self.x * 16 + 16, self.y * 16 + 16)
		end
	end
end

function Nazi:isColliding(offsetX, offsetY)
	local hw = game.map.roomWidth / 2
	local hh = game.map.roomHeight / 2

	for ix = self.x - 1 + offsetX, self.x + 1 + offsetX do
		for iy = self.y - 1 + offsetY, self.y + 1 + offsetY do
			if ix >= hw or ix <= -hw or iy >= hh or iy <= -hh or
				game.map:isAnythingAt(ix, iy, self.room, self) then
				return true
			end
		end
	end
	return false
end

function Nazi:findWalkingPath()
	local horizontalDistance = 0
	local verticalDistance = 0
	local done

	-- Get horizontal distance
	local right, left = 0, 0
	-- Find maximum distance to the right
	done = false
	repeat
		right = right + 1
		if self:isColliding(right, 0) then
			done = true
			break
		end
	until done

	-- Find maximum distance to the left
	done = false
	repeat
		left = left + 1
		if self:isColliding(-left, 0) then
			done = true
			break
		end
	until done	

	horizontalDistance = left + right

	-- Get maximum vertical distance
	local down, up = 0, 0
	-- Find maximum distance to the right
	done = false
	repeat
		down = down + 1
		if self:isColliding(0, down) then
			done = true
			break
		end
	until done

	-- Find maximum distance to the left
	done = false
	repeat
		up = up + 1
		if self:isColliding(0, -up) then
			done = true
			break
		end
	until done	

	verticalDistance = up + down

	local direction
	if horizontalDistance > verticalDistance then
		direction = "horizontal"
	else
		direction = "vertical"
	end

	return direction
end

function Nazi:ai()
	-- Dead nazi don't do anything
	if not self.alive or not self.running then
		return
	end

	-- Check if in front of the player
	self.aimX = self.walkingDirection == "horizontal" and self.direction or 0
	self.aimY = self.walkingDirection == "vertical" and self.direction or 0

	local hit, distance, name, object = self:find {noNazi = true, noChest = true, noWall = true}
	if name == "player" then
		if self.inventory.bullets > 0 and distance < 10 and object.alive then
			self.inventory.bullets = self.inventory.bullets - 1
			self.lastShot = love.timer.getTime()
			if math.random() < 1 / distance then
				object:kill()
				return
			end
		end
	end

	-- Walk random direction
	local newX = self.x + (self.walkingDirection == "horizontal" and self.direction or 0)
	local newY = self.y + (self.walkingDirection == "vertical" and self.direction or 0)

	local canMove = true
	local room = game.map.currentRoom

	for x = newX, newX + 2 do
		for y = newY, newY + 2 do
			if game.map:isAnythingAt(x, y, nil, self) then
				canMove = false
				local hit, distance, name, object = self:find {noNazi = true, noChest = true, noWall = true}
				if name ~= "player" then
					self.direction = -self.direction
				end
				break
			end
		end
		if not canMove then
			break
		end
	end

	if canMove then
		self.x, self.y = newX, newY
	end
end

function Nazi:kill()
	if self.alive then
		self.alive = false
		game.map.rooms.livingEnemies = game.map.rooms.livingEnemies - 1
	end
end

function Nazi:loot()
	local inventory = self.inventory
	self.inventory = {}
	return inventory
end

function Nazi:give(name, amount)
	self.inventory[name] = self.inventory[name] or 0 + amount
end