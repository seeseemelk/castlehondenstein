class "Player" (Character, Controllable, Timer)

local images = {}
images.shot = love.graphics.newImage("resources/graphics/shot.png")
images.player = love.graphics.newImage("resources/graphics/player.png")
images.playerdead = love.graphics.newImage("resources/graphics/body.png")
images.playershootup = love.graphics.newImage("resources/graphics/player_shoot_up.png")
images.playershootdown = love.graphics.newImage("resources/graphics/player_shoot_down.png")
images.playershootleft = love.graphics.newImage("resources/graphics/player_shoot_left.png")
images.playershootleftup = love.graphics.newImage("resources/graphics/player_shoot_left_up.png")
images.playershootleftdown = love.graphics.newImage("resources/graphics/player_shoot_left_down.png")

local shotLocations = {
	{{-26,-18}, { 18,-18}, { 26,-18}},
	{{-32, -2}, {  0,  0}, { 32,  -2}},
	{{-26, 14}, { 14, 14}, { 26, 14}}
}

local maxGrabDistance = math.sqrt(3^2 + 3^2)

function Player:Player(map)
	assert(map, "No map given to the Player")
	self.x, self.y = map:findRandomPlace()

	self.spawn = {
		x = self.x,
		y = self.y,
		roomX = game.map.x,
		roomY = game.map.y
	}

	Character.Character(self, self.x, self.y)
	Controllable.Controllable(self)
	Timer.Timer(self)

	self.speedx, self.speedy = 0, 0
	self.aimDirection = ""
	self.map = map
	self.lastMessage = ""

	self.aimX, self.aimY = 0, 0
	self.lastShot = 0

	self.bullets = 10
	self.grenades = 3
	self.alive = true

	self.viewingMinimap = false

	game:addChild(self)
	self:addTimer(.15, "walk")
end

function Player:_Player()
	Character._Character(self)
	Controllable._Controllable(self)
	Timer._Timer()
end

function Player:draw()
	local img = "player"
	local invert = false

	if self.alive then
		love.graphics.setColor(255, 255, 255)
		if self.aimX ~= 0 or self.aimY ~= 0 then
			-- Please do not look at the next line, it is ugly.
			img = img .. "shoot" .. ((self.aimX < 0 and "left") or (self.aimX > 0 and
				(function() invert=true; return "left" end)()) or "")
			img = img .. ((self.aimY < 0 and "up") or (self.aimY > 0 and "down") or "")
		end

		if invert then
			love.graphics.draw(images[img], (self.x + 3) * 16, self.y * 16, 0, -1, 1)
		else
			love.graphics.draw(images[img], self.x * 16, self.y * 16)
		end

		if (self.aimX ~= 0 or self.aimY ~= 0) and love.timer.getTime() - self.lastShot < .05 then
			love.graphics.draw(images.shot, self.x*16 + shotLocations[self.aimY+2][self.aimX+2][1]+16,
				self.y*16 + shotLocations[self.aimY+2][self.aimX+2][2]+16)
		end
	else
		love.graphics.setColor(179, 236, 145)
		love.graphics.draw(images.playerdead, self.x * 16, self.y * 16)
	end

	love.graphics.setColor(255, 255, 255)
	love.graphics.print("Höndenstein version over 9000", -380, -280)
	love.graphics.print("Bullets: " .. self.bullets, -320, 270)
	love.graphics.print("Grenades: " .. self.grenades, -320, 285)
	love.graphics.print(self.lastMessage, -200, 270)
	local living = game.map.rooms.livingEnemies
	local total = game.map.rooms.totalEnemies
	love.graphics.print("Enemies left: " .. living .. "/" .. total, -200, 285)

	if self.viewingMinimap then
		self:drawMinimap()
	end
end

function Player:drawMinimap()
	local done = {}

	-- Draw doorways
	for x, row in pairs(game.map.rooms) do
		if type(x) == "number" then
			for y, doors in pairs(row) do
				love.graphics.setColor(255, 0, 0)
				if doors.up then
					love.graphics.rectangle("fill", (x - .2) * 20, (y - 1) * 20, 5, 10)
				end
				if doors.left then
					love.graphics.rectangle("fill", (x - 1) * 20, (y - .2) * 20, 10, 5)
				end
			end
		end
	end

	-- Draw room
	for x, row in pairs(game.map.rooms) do
		if type(x) == "number" then
			for y, room in pairs(row) do
				if game.map.x == x and game.map.y == y then
					love.graphics.setColor(255, 255, 0)
				elseif room.entered then
					love.graphics.setColor(0, 255, 0)
				else
					love.graphics.setColor(255, 0, 0)
				end
				love.graphics.rectangle("fill", (x - .5) * 20, (y - .5) * 20, 16, 16)
			end
		end
	end

end

function Player:onKeyPressed(key)
	-- Minimap
	if key == "m" then
		self.viewingMinimap = not self.viewingMinimap
	end

	if not self.alive then
		if key == "return" then
			self.bullets = 0
			self.grenades = 0
			self.x = self.spawn.x
			self.y = self.spawn.y
			self.aimX, self.aimY = 0, 0
			self.speedx, self.speedy = 0, 0
			game.map:moveTo(self.spawn.roomX, self.spawn.roomY)
			self.alive = true
		end
		return
	end

	-- Walking
	if key == "r" then
		self.speedy = -1
		self.speedx = 0
	elseif key == "v" then
		self.speedy = 1
		self.speedx = 0
	elseif key == "d" then
		self.speedy = 0
		self.speedx = -1
	elseif key == "g" then
		self.speedy = 0
		self.speedx = 1
	elseif key == "e" then
		self.speedy = -1
		self.speedx = -1
	elseif key == "t" then
		self.speedy = -1
		self.speedx = 1
	elseif key == "b" then
		self.speedy = 1
		self.speedx = 1
	elseif key == "c" then
		self.speedy = 1
		self.speedx = -1
	elseif key == "f" then
		self.speedy = 0
		self.speedx = 0
	end

	---[[
	-- Aiming
	local aimKeys = {
		{"kp7","kp8","kp9"},
		{"kp4","kp5","kp6"},
		{"kp1","kp2","kp3"}
	}
	for y, keys in ipairs(aimKeys) do
		for x, k in ipairs(keys) do
			if k == key then
				self.aimX = x - 2
				self.aimY = y - 2
				break
			end
		end
	end
	
	-- Shooting and throwing grenades
	if key == "kp+" and self.bullets > 0 then
		self.lastShot = love.timer.getTime()
		self.bullets = self.bullets - 1
		self:shoot()
	elseif key == "a" and self.grenades > 0 then
		self.grenades = self.grenades - 1
		self:throwGrenade()
	end

	-- Looting
	if key == " " then
		local hit, distance, name, object = self:find {noPlayer = true, noWall = true, onlyDead = true}

		if name == "nazi" or name == "chest" then
			if distance <= maxGrabDistance then
				self:loot(object)
			end
		end
	end
end

function Player:loot(object)
	local loot = object:loot()

	if loot.bullets then
		print("Found " .. loot.bullets .. " bullets")
		if loot.bullets > self.bullets then
			object:give("bullets", self.bullets)
			self.bullets = loot.bullets
			print("Grabbed new bullets")
			self.lastMessage = "Grabbed clip. You now have " .. self.bullets .. " bullets."
		else
			object:give("bullets", loot.bullets)
		end
	end

	if loot.grenades then
		print("Found " .. loot.grenades .. " grenades")
		self.grenades = self.grenades + loot.grenades
		self.lastMessage = "Grabbed " .. loot.grenades .. " grenades"
	end
end

function Player:shoot()
	local hit, distance, name, object = self:find {noPlayer = true, onlyAlive = true}

	if name == "nazi" then
		object:kill()
	end
end

function Player:throwGrenade()
	local grenade = Grenade(self.x + 1 + self.aimX * 2, self.y + 1 + self.aimY * 2,
		self.aimX, self.aimY)
end

function Player:walk()
	if not self.alive then
		return
	end

	local room = self.map.currentRoom

	local newY = self.y + self.speedy
	local newX = self.x + self.speedx

	local canMove = true

	local room = game.map.currentRoom
	local inDoor, inWall = nil, false
	for x = newX, newX + 2, 2 do
		for y = newY, newY + 2, 2 do
			if room[x][y]:sub(1,4) == "door" then
				inDoor = room[x][y]:sub(5)
			elseif room[x][y] == "wall" then
				inWall = true
				break
			end
		end

		if inWall then
			break
		end
	end

	if not inWall and inDoor then
		local direction = inDoor
		local hw = game.map.roomWidth / 2
		local hh = game.map.roomHeight / 2

		if direction == "up" then
			game.map:moveTo(game.map.x, game.map.y - 1)
			self.y = hh - 3
		elseif direction == "down" then
			game.map:moveTo(game.map.x, game.map.y + 1)
			self.y = -hh + 1
		elseif direction == "left" then
			game.map:moveTo(game.map.x - 1, game.map.y)
			self.x = hw - 3
		elseif direction == "right" then
			game.map:moveTo(game.map.x + 1, game.map.y)
			self.x = -hw + 1
		end

		self.speedx, self.speedy = 0, 0

		return
	end

	for x = newX, newX + 2 do
		for y = newY, newY + 2 do
			if room[x][y] ~= "empty" or self.map:isChestAt(x, y)
				or self.map:isNaziAt(x, y, true) then
				canMove = false
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

---
-- Check if an object is colliding with the player
function Player:collides(x, y)
	local dx = x - self.x
	local dy = y - self.y
	if dx >= 0 and dx <= 2 and dy >= 0 and dy <= 2 then
		return true
	end
end

function Player:kill()
	print("You got shot")
	self.alive = false
	self.lastMessage = "You died. Press <ENTER> to respawn"
end