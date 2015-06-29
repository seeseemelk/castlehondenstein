local c = require("engine.class")
class = c.class
delete = c.delete

net = require("engine.net")
require("engine.objects.camera")
require("engine.objects.collidable")
require("engine.objects.controllable")
require("engine.objects.drawable")
require("engine.objects.network")
require("engine.objects.timer")

function love.load(arg)
	love.window.setTitle("Twitch Makes Hondenstein")
	require("game.main")
	--[[
	local startServer, startClient, startSingle
	local options = {}

	local need

	for i, v in ipairs(arg) do
		if need == "client" then
			startClient = v
			need = false
		elseif v == "--test" then
			print("Starting unit test")
			require("test")
			love.event.quit()
		elseif v == "--server" then
			startServer = true
		elseif v == "--client" then
			need = "client"
		elseif v == "--single" then
			startSingle = true
		elseif v == "--shaders" then
			options.shaders = true
		end
	end

	_G.options = options

	if startServer then
		print("Starting server")
		net.server.init('*', 25565)
		--require("game.server")
	end
	if startClient then
		love.window.setMode(800, 600)
		require("game.main")
		net.client.init(startClient, 25565)
	end
	if startSingle then
		print("Starting single player is deprecated")
		love.event.quit()
	end
	--]]
end

function love.threaderror(thread, err)
	error("Error in thread: " .. tostring(err))
end