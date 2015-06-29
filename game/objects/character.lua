class "Character" (Drawable)

function Character:Character(x, y)
	Drawable.Drawable(self, x, y)

	self.aimX, self.aimY = 0, 0
	self.x, self.y = x, y

	game:addChild(self)
end

function Character:_Character()
end

function Character:find(options)
	options.findWall = not options.noWall
	options.findChest = not options.noChest
	options.findNazi = not options.noNazi
	options.findPlayer = not options.noPlayer

	-- Don't raycasting if player isn't aiming, or the game will hang
	if self.aimX == 0 and self.aimY == 0 then
		return
	end

	local hit = false
	local objectName
	local object

	local x, y = self.x, self.y

	repeat
		x = x + self.aimX
		y = y + self.aimY

		if x <= -(game.map.roomWidth / 2) or x >= game.map.roomWidth / 2 then
			hit = true
			objectName = "bounds"
			break
		elseif y <= -(game.map.roomHeight / 2) or y >= game.map.roomHeight / 2 then
			hit = true
			objectName = "bounds"
			break
		end

		-- Check if there is anything around the bullet (3x3 grid)
		for ix = x, x + 2 do
			for iy = y, y + 2 do
				if options.findWall and game.map.currentRoom[ix][iy] == "wall" then
					objectName = objectName or "wall"
					hit = true
				elseif options.findWall and game.map.currentRoom[ix][iy] == "door" then
					objectName = objectName or "wall"
					hit = true
				elseif options.findChest and game.map:isChestAt(ix, iy) then
					if objectName ~= "nazi" then
						objectName = "chest"
						object = game.map:isChestAt(ix, iy)
						hit = true
					end
				elseif options.findNazi and game.map:isNaziAt(ix, iy, options.onlyAlive) then
					object = game.map:isNaziAt(ix, iy, options.onlyAlive)
					if  (options.onlyAlive and object.alive) or
						(options.onlyDead and not object.alive) or
						(not options.onlyAlive and not options.onlyDead) then
						objectName = "nazi"
						hit = true
					end
				elseif options.findPlayer and game.player:collides(ix, iy) then
					objectName = "player"
					object = game.player
					hit = true
				end
			end
		end
	until hit

	local dx = math.abs(self.x - x)
	local dy = math.abs(self.y - y)
	local distance = math.sqrt(dx^2 + dy^2)		

	return hit, distance, objectName, object
end