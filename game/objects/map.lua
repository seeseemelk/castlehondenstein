class "Map"

function Map:Map()
	-- Properties for room generator
	self.roomHeight = 30
	self.roomWidth = 40
	self.maxEnemies = 20
	-- End of properties

	self.levels = {}
	self.rooms = {}
	self.currentRoom = {}
	self.x, self.y = 0, 0
end

function Map:_Map()
	self.levels = nil
	self.rooms = nil
	self.currentRoom = nil
end

function Map:generateLevel()
	print("Generating level")
	local map = self:createRoomMap()
	local rooms = {}
	rooms.totalEnemies = 0
	rooms.livingEnemies = 0

	-- Set the current level to the new level
	self.rooms = rooms

	-- Make a few rooms
	for x, row in pairs(map) do
		rooms[x] = {}
		for y, doors in pairs(row) do
			local room = self:generateRoom {
				left = doors.left, right = doors.right,
				up = doors.up, down = doors.down
			}
			rooms[x][y] = room
			--generateRooms(doors.left, doors.right, doors.up, doors.down)
		end
	end

	-- Add the level to the level list
	self.levels[#self.levels + 1] = rooms


	-- Set the current room to room (0, 0)
	self.currentRoom = self.rooms[0][0]
	self.currentRoom.entered = true
	self.x, self.y = 0, 0
end

-- Just create a map that says where the doors should be
function Map:createRoomMap()
	local map = {}
	map[0] = {}
	self:stepRoomMap(map, 0, 0, 0)

	-- In some cases doors will not be created when they should be made.
	-- This will solve these cases
	for ix, row in pairs(map) do
		for iy, doors in pairs(row) do
			if doors.left then
				map[ix-1][iy].right = true
			end
			if doors.right then
				map[ix+1][iy].left = true
			end
			if doors.up then
				map[ix][iy-1].down = true
			end
			if doors.down then
				map[ix][iy+1].up = true
			end
		end
	end

	return map
end

function Map:stepRoomMap(map, x, y, depth)
	map[x] = map[x] or {}
	map[x-1] = map[x-1] or {}
	map[x+1] = map[x+1] or {}

	map[x][y] = {
		up = not map[x][y-1] and ((math.random() > .5 and true or false) and depth < 10) or map[x][y-1],
		down = not map[x][y+1] and ((math.random() > .5 and true or false) and depth < 10) or map[x][y+1],
		left = not map[x-1][y] and ((math.random() > .5 and true or false) and depth < 10) or map[x-1][y],
		right = not map[x+1][y] and ((math.random() > .5 and true or false) and depth < 10) or map[x+1][y]
	}

	if map[x][y].left and not map[x-1][y] then
		self:stepRoomMap(map, x-1, y, depth + 1)
	end
	if map[x][y].right and not map[x+1][y] then
		self:stepRoomMap(map, x+1, y, depth + 1)
	end
	if map[x][y].up and not map[x][y-1] then
		self:stepRoomMap(map, x, y-1, depth + 1)
	end
	if map[x][y].down and not map[x][y+1] then
		self:stepRoomMap(map, x, y+1, depth + 1)
	end
end

function Map:generateRooms(left, right, up, down)

	local rooms = {}
	rooms[0] = {}

	local room = self:generateRoom({
		left = left, right = right,
		up = up, down = down
	})

	rooms[0][0] = room
	return rooms
end

function Map:generateRoom(doors)

	local room = {}
	room.objects = {}
	room.entered = false

	for name, value in pairs(doors) do
		room[name] = value
	end

	local endX = self.roomWidth / 2
	local endY = self.roomHeight / 2
	local startX = -endX
	local startY = -endY

	room.startX = startX
	room.startY = startY
	room.endX = endX
	room.endY = endY

	-- Fill the room with empty
	for x = startX, endX do
		room[x] = {}
		for y = startY, endY do
			room[x][y] = "empty"
		end
	end

	-- Create 4 walls
	for x = startX, endX do
		if not (doors.up and x >= -2 and x <= 2) then
			room[x][startY] = "wall"
		else
			room[x][startY] = "doorup"
		end
		if not (doors.down and x >= -2 and x <= 2) then
			room[x][endY] = "wall"
		else
			room[x][endY] = "doordown"
		end
	end

	for y = startY, endY do
		if not (doors.left and y >= -2 and y <= 2) then
			room[startX][y] = "wall"
		else
			room[startX][y] = "doorleft"
		end
		if not (doors.right and y >= -2 and y <= 2) then
			room[endX][y] = "wall"
		else
			room[endX][y] = "doorright"
		end
	end

	-- Create 4 walls naively
	for i = 1, math.random(9, 20) do
		local direction = math.random(0, 1)
		if direction < .5 then
			direction = "vertical"
		else
			direction = "horizontal"
		end

		local startPos, endPos
		if direction == "horizontal" then
			-- Generate some locations
			local startPos = math.random(room.startX, room.endX)
			local endPos = math.random(room.startX, room.endX)
			local y = math.random(room.startY + 1, room.endY - 1)

			-- Place the walls
			for x = startPos, endPos do
				if not self:isNearDoor(x, y, room) then
					room[x][y] = "wall"
				end
			end
		else
			local startPos = math.random(room.startY, room.endY)
			local endPos = math.random(room.startY, room.endY)
			local x = math.random(room.startX + 1, room.endX - 1)

			-- Place the walls
			for y = startPos, endPos do
				if not self:isNearDoor(x, y, room) then
					room[x][y] = "wall"
				end
			end
		end
	end

	room.chests = {}
	room.nazi = {}

	-- Create 1 to 3 chests
	for i = 1, math.random(1, 3) do
		local x, y = self:findRandomPlace(room)
		room.chests[#room.chests + 1] = Chest(x, y)
	end

	-- Create baddies 0 to 3 baddies
	for i = 1, math.random(1, 3) do
		local x, y = self:findRandomPlace(room)
		room.nazi[#room.nazi + 1] = Nazi(x, y, room)
	end

	return room
end

function Map:moveTo(x, y)
	self:disableRoom()
	self.x, self.y = x, y
	self.currentRoom = self.rooms[x][y]
	self.currentRoom.entered = true
	self:enableRoom()
end

function Map:addObject(object, room)
	room = room or self.currentRoom
	room.objects[#room.objects + 1] = object
end

function Map:removeObject(object, room)
	room = room or self.currentRoom
	for index, obj in ipairs(room.objects) do
		if obj == object then
			room.objects[index] = room.objects[#room.objects]
			room.objects[#room.objects] = nil
			return
		end
	end
end

function Map:findRandomPlace(room)
	room = room or self.currentRoom

	local x, y
	repeat
		local placeable = true
		x = math.random(room.startX + 1, room.endX - 3)
		y = math.random(room.startY + 1, room.endY - 3)

		-- Check if there is room to place the anything
		for ix = x, x + 2 do
			for iy = y, y + 2 do
				if room[ix][iy] == "wall" or self:isChestAt(ix, iy, room) or
					self:isNaziAt(ix, iy, true, room) then
					placeable = false
					break
				end
			end

			if not placeable then
				break
			end
		end

		-- Check if it is near a door, because we don't want to block it
		if self:isNearDoor(x, y, room) then
			placeable = false
		end
	until placeable

	return x, y
end

function Map:enableRoom(room)
	room = room or self.currentRoom

	for _, nazi in ipairs(room.nazi) do
		nazi:enable()
	end

	for _, chest in ipairs(room.chests) do
		chest:enable()
	end
end

function Map:disableRoom(room)
	room = room or self.currentRoom

	for _, nazi in ipairs(room.nazi) do
		nazi:disable()
	end

	for _, chest in ipairs(room.chests) do
		chest:disable()
	end
end

function Map:isChestAt(x, y, room)
	local chests = (room or self.currentRoom).chests

	for _, chest in ipairs(chests) do
		local dx = x - chest.x
		local dy = y - chest.y
		if dx >= 0 and dx <= 2 and dy >= 0 and dy <= 2 then
			return chest
		end
	end
	return false
end

function Map:isNaziAt(x, y, onlyAlive, room, exclude)
	local nazies = (room or self.currentRoom).nazi

	for _, nazi in ipairs(nazies) do
		if nazi ~= exclude then
			local dx = x - nazi.x
			local dy = y - nazi.y
			if dx >= 0 and dx <= 2 and dy >= 0 and dy <= 2 then
				if onlyAlive and nazi.alive or not onlyAlive then
					return nazi
				end
			end
		end
	end
	return false
end

function Map:isObjectAt(x, y, room, exclude)
	local objects = (room or self.currentRoom).objects

	for _, object in ipairs(objects) do
		if object ~= exclude then
			local dx = x - object.x
			local dy = y - object.y
			local w = object.w or 1 - 1
			local h = object.h or 1 - 1
			if dx >= 0 and dx <= w and dy >= 0 and dy <= h then
				return object
			end
		end
	end
	return false
end

function Map:isInBounds(x, y)
	local hw = self.roomWidth / 2
	local hh = self.roomHeight / 2

	if x >= -hw or x <= hw or y >= hh or y <= hh then
		return true
	else
		return false
	end
end

function Map:isNearDoor(x, y, room)
	room = room or self.currentRoom

	-- Check for door left/right
	for ix = x - 3, x + 3 do
		if room[ix] and room[ix][y]:sub(1,4) == "door" then
			return true
		end
	end

	-- Check for door up/down
	for iy = y - 3, y + 3 do
		if room[x][iy] and room[x][iy]:sub(1,4) == "door" then
			return true
		end
	end
end

function Map:isAnythingAt(x, y, room, exclude)
	room = room or self.currentRoom

	if not self:isInBounds(x, y) then
		return false
	end

	assert(room[x], "Invalid x coordinate (" .. tostring(x) .. ")")
	assert(room[x][y], "Invalid y coordinate (" .. tostring(y) .. ")")

	if room[x][y] ~= "empty" then
		return true, "wall", room[x][y]
	else
		if self:isChestAt(x, y, room, exclude) then
			local chest = self:isChestAt(x, y, room, exclude)
			return true, "chest", chest
		elseif self:isNaziAt(x, y, false, room, exclude) then
			local nazi = self:isNaziAt(x, y, false, room, exclude)
			return true, "nazi", nazi
		elseif self:isObjectAt(x, y, room, exclude) then
			local object = self:isObjectAt(x, y, room, exclude)
			return true, "object", object
		end
	end

	return false
end