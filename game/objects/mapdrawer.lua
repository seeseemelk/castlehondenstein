class "MapDrawer" (Drawable)

local images = {}
images.wall = love.graphics.newImage("resources/graphics/wall.png")

function MapDrawer:MapDrawer(map)
	assert(map, "No map given to MapDrawer")
	self.map = map
	game:addChild(self)

	Drawable.Drawable(self, 0, 0)
end

function MapDrawer:_MapDrawer()
	Drawable._Drawable(self)
end

function MapDrawer:draw()
	love.graphics.setColor(255, 255, 255)
	local room = self.map.currentRoom

	-- Draw walls
	for x = room.startX, room.endX do
		for y = room.startY, room.endY do
			local obj = room[x][y]

			if obj == "wall" then
				love.graphics.draw(images.wall, x * 16, y * 16)
			end
		end
	end
end