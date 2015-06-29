math.randomseed(os.time())

require("game.objects.map")
require("game.objects.mapdrawer")
require("game.objects.chest")
require("game.objects.grenade")
require("game.objects.character")
require("game.objects.player")
require("game.objects.nazi")

class "Game"

function Game:Game()
	self.camera = Camera(0, 0)
end

function Game:_Game()
end

function Game:initialize()
	self.map = Map()
	self.map:generateLevel()
	self.mapDrawer = MapDrawer(self.map)
	self.player = Player(self.map)
	self.map:enableRoom(self.map.currentRoom)
end

function Game:addChild(object)
	self.camera:addChild(object)
end

function Game:removeChild(object)
	self.camera:removeChild(object)
end


-- Creating game object
_G.game = Game()
game:initialize()
