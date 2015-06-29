class "Chest" (Drawable)

local images = {}
images.closed = love.graphics.newImage("resources/graphics/chest.png")
images.open = love.graphics.newImage("resources/graphics/chest_open.png")

function Chest:Chest(x, y)
	Drawable.Drawable(self, self.x, self.y)

	self.x, self.y = x, y
	self.enabled = false
	self.open = false

	self.inventory = {
		bullets = math.random(6, 9),
		grenades = math.random(0, 3)
	}

	game:addChild(self)
end

function Chest:_Chest()
	Drawable._Drawable()
end

function Chest:draw()
	love.graphics.setColor(255, 255, 255)
	if self.enabled then
		if self.open then
			love.graphics.draw(images.open, self.x * 16, self.y * 16)
		else
			love.graphics.draw(images.closed, self.x * 16, self.y * 16)
		end
	end
end

function Chest:enable()
	self.enabled = true
end

function Chest:disable()
	self.enabled = false
end

function Chest:loot()
	local loot = self.inventory
	self.inventory = {}
	self.open = true
	return loot
end

function Chest:give(name, amount)
	self.inventory[name] = amount
end