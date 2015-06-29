local socket = require("socket")

---
-- This module contains all the low-level network stuff
local net = {}

net.server = {} --Contains server specific functions
net.client = {} --Contains client specific functions
net.common = {} --Contains common functions


--                        --
--         COMMON         --
--                        --

---
-- Serializes a table. Note it only goes 1 level deep.
-- @param tbl Table to serialize
-- @return String containing serialized table
function net.common.serialize(tbl)
	assert(type(tbl) == "table", "Can only serialize tables")
	local str = {}

	for k, v in pairs(tbl) do
		str[#str + 1] = #k .. ";"
		str[#str + 1] = k
		str[#str + 1] = type(v) == "number" and "n" or (type(v) == "boolean" and "b" or "s")
		str[#str + 1] = #tostring(v) .. ";"
		str[#str + 1] = tostring(v)
	end

	return table.concat(str)
end

---
-- Deserializes a table serialized with net.common.serialize
-- @param str String to deserialize
-- @return Deserialized table
function net.common.deserialize(str)
	assert(type(str) == "string", "Can only deserialize strings")
	local index = 1
	local tbl = {}

	while index < #str do
		local keyLength = tonumber(str:sub(index):match("^(%d*);"))
		--print("kl: " .. tostring(keyLength))
		index = index + #tostring(keyLength) + 1
		local key = str:sub(index, index + keyLength - 1)
		--print("k: " .. tostring(key))
		index = index + keyLength

		local valueType = str:sub(index, index)
		--print("t: " .. valueType)
		index = index + 1

		local valueLength = tonumber(str:sub(index):match("^(%d*);"))
		--print("vl: " .. tostring(valueLength))
		index = index + #tostring(valueLength) + 1
		local value = str:sub(index, index + valueLength - 1)
		--print("v: " .. tostring(value))
		index = index + valueLength

		if valueType == "n" then
			value = tonumber(value)
		elseif valueType == "s" then
			value = tostring(value)
		elseif valueType == "b" then
			if value == "true" then
				value = true
			else
				value = false
			end
		end

		tbl[key] = value
	end

	return tbl
end


--                        --
--         SERVER         --
--                        --

net.server.players = {} ---Contains all currently connected players. This is indexed by id (string)
net.server.pingDeadline = 10 ---Max time in which a player has to receive a ping (in seconds)
net.server.hosting = false ---True if currently hosting
net.server.events = {} ---List of all event listeners

---
-- Start the server
-- @param ip The ip the server should listen for (use '*')
-- @param port The port the server should listen for
function net.server.init(ip, port)
	local thread = love.thread.newThread(string.dump(net.server.update))
	thread:start(ip, port)
end

---
-- Handle anything server network related.
-- Does not return
function net.server.update(ip, port)
	local socket = require("socket")
	local net = require("engine.net")
	_G.net = net
	require("love.timer")
	require("game.server")

	net.server.udp = assert(socket.udp())
	net.server.udp:settimeout(.1)
	assert(net.server.udp:setsockname(ip, port))
	net.server.hosting = true
	print("[LOG] Server initialized")

	print("[LOG] Server running")
	while net.server.hosting do
		local startTime = love.timer.getTime()
		-- Handle any incoming packets
		repeat
			local tbl, ip, port = net.server.receive()
			if tbl then
				net.server.message(tbl, ip, port)
			end
		until not tbl

		-- Kick any idle players
		for id, player in pairs(net.server.players) do
			if player.ping > net.server.pingDeadline then
				net.server.kick(player, "Timeout")
			else
				player.ping = player.ping + love.timer.getTime() - startTime
			end
		end
	end
end

---
-- Receive a table from a client
-- @return Nil when nothing to receive
-- @return Table, ip, port when data received
function net.server.receive()
	local packet, ip, port = net.server.udp:receivefrom()

	if not packet then
		return nil
	else
		local tbl = net.common.deserialize(packet)
		return tbl, ip, port
	end
end

---
-- Send a table to a player
-- @param player Player to send it to
-- @param tbl Table to send
function net.server.send(player, tbl)
	local str = net.common.serialize(tbl)
	assert(net.server.udp:sendto(str, player.ip, player.port))
end

---
-- Send a table to every player
-- @param tbl Table to send
function net.server.broadcast(tbl)
	for _, player in pairs(net.server.players) do
		net.server.send(player, tbl)
	end
end

---
-- Broadcast to everyone except one person
-- @param player Player not to send to
-- @param tbl Table to send
function net.server.ebroadcast(player, tbl)
	for _, playerb in pairs(net.server.players) do
		if playerb ~= player then
			net.server.send(playerb, tbl)
		end
	end
end

---
-- Stop the server
function net.server.stop()
	for id, player in pairs(player) do
		net.server.kick(player, "Server stopped")
	end
	net.socket.udp:close()
	net.server.hosting = false
	print("[LOG] Server stopped")
end

---
-- Handle an incoming message.
-- @param tbl Deserialized message
-- @param ip Ip address of the sender
-- @param port Port of the sender
function net.server.message(tbl, ip, port)
	local player
	if tbl.action == "connect" then
		-- Player connects for the first time
		player = net.server.registerPlayer(ip, port, tbl)
		-- Send a message to everyone saying he has connected
		net.server.broadcast({
			action = "connect",
			username = player.username,
			accept = true,
			id = player.id,
			ip = player.ip,
			port = player.port
		})
		-- Send him every connected player
		for _, playerb in pairs(net.server.players) do
			if playerb ~= player then
				net.server.send(player, {
					action = "connect",
					username = playerb.username,
					id = playerb.id
				})
			end
		end
		print("[LOG] Client connected (" .. ip .. ":" .. port .. ")")

		tbl.player = player
		net.server.fireEvent(tbl)
	elseif tbl.action == "ping" then
		player = net.server.getPlayer(ip, port)
		player.ping = 0
		net.server.send(player, {
			action = "ping"
		})
	elseif tbl and net.server.getPlayer(ip, port) then
		player = net.server.getPlayer(ip, port)
		if not player then
			error("Player " .. tostring(ip) .. "-" .. tostring(port) .. " not found")
			return
		end
		net.server.ping(player)
		tbl.player = player
		tbl.id = player.id

		net.server.fireEvent(tbl)
		-- Add some stuff
	end
end

---
-- Register a newly connected player
-- @param ip Ip of the connected player
-- @param port Port of the connected player
-- @param options Table send by the player
-- @return The player object
function net.server.registerPlayer(ip, port, options)
	local player = {}
	player.username = options.username or "noname"
	player.ip = ip
	player.port = port
	player.id = ip .. "-" .. port
	player.ping = 0

	net.server.players[player.id] = player
	return player
end

---
-- Find a player with a given ip and port
-- @param ip Ip of the player
-- @param port Port of the player
-- @return Player object
function net.server.getPlayer(ip, port)
	local id = ip .. "-" .. port
	return net.server.players[id]
end

---
-- Reset ping deadline
-- @param player Player to reset ping deadline
function net.server.ping(player)
	player.ping = 0
end

---
-- Kick a player from the server
-- @param player Player to kick
-- @param reason Reason why to kick the player
function net.server.kick(player, reason)
	print("[LOG] Kicking player " .. tostring(player.username) .. " (" ..
		player.ip .. ":" .. player.port .. ") from server.")
	print("[LOG] Reason: " .. tostring(reason))
	net.server.send(player, {
		action = "kick",
		reason = reason
	})

	net.server.fireEvent({
		action = "disconnect",
		reason = reason,
		player = player,
		id = player.id
	})

	net.server.players[player.id] = nil
end

---
-- Add an event listener
-- Should only be used by the Network class
-- @param eventlistener Table with callback functions
function net.server.addEvent(eventlistener)
	net.server.events[#net.server.events + 1] = eventlistener
end

---
-- Remove an event listener
-- Should only be used by the Network class
-- @param eventlistener Table which should be removed
function net.server.removeEvent(eventlistener)
	for index, event in ipairs(net.server.events) do
		if event == eventlistener then
			net.server.events[index] = net.server.events[#net.server.events]
			net.server.events[#net.server.events] = nil
			break
		end
	end
end

---
-- Fire an event to all event listeners
-- Note: Should only be used by net itself
-- @param event Event to fire
function net.server.fireEvent(event)
	for _, eventl in ipairs(net.server.events) do
		if event.action == "connect" then
			eventl:onConnect(event)
		elseif event.action == "disconnect" then
			eventl:onDisconnect(event)
		else
			eventl:onAction(event)
		end
	end
end

--                        --
--         CLIENT         --
--                        --

net.client.username = "testplayer-86_64" ---Username
net.client.id = nil
net.client.connected = false
net.client.events = {}
net.client.players = {}
net.client.timeout = 0
net.client.pingTime = 0

---
-- Start as a client and connect to a server
-- @param ip The ip the client should connect to
-- @param port The port the client should connect to
function net.client.init(ip, port)
	print("[LOG] Connecting to " .. ip .. ":" .. port)
	net.client.udp = assert(socket.udp())
	assert(net.client.udp:setpeername(ip, port))

	-- Send initial connect packet
	net.client.send {
		action = "connect",
		username = net.client.username
	}

	net.client.udp:settimeout(5)
	local packet = net.client.receive()
	if packet and packet.accept == true then
		assert(net.client.udp:settimeout(0))
		net.client.connected = true
		net.client.id = packet.id
		net.client.players[packet.id] = {
			username = packet.username,
			id = packet.id
		}
		print("[LOG] Connected to server")
		net.client.fireEvent(packet)
	else
		print("[ERR] Connection refused")
		if not packet then
			print("[ERR] Reason: Connection timeout")
		else
			print("[ERR] Reason: " .. (packet.reason or "Not accepted"))
		end
	end

end

---
-- Handle anything server network related.
-- Should be called in the update loop.
function net.client.update(dt)
	if net.client.connected then
		net.client.pingTime = net.client.pingTime + dt
		if net.client.pingTime >= 2 then
			net.client.send({action = "ping"})
			net.client.pingTime = 0
		end

		repeat
			local packet = net.client.receive()
			if packet then
				net.client.handle(packet)
				net.client.timeout = 0
			end
		until not packet

		net.client.timeout = net.client.timeout + dt
		if net.client.timeout > 10 then
			print("[ERR] Connection terminated")
			print("[ERR] Reason: Timeout")
			net.client.disconnect()
		end
	end
end

---
-- Send a table to the server
-- @param tbl Table to send
function net.client.send(tbl)
	local str = net.common.serialize(tbl)
	net.client.udp:send(str)
end

---
-- Receive a table from the server
-- @return Table received from server
function net.client.receive()
	local packet = net.client.udp:receive()

	if not packet then
		return nil
	else
		local tbl = net.common.deserialize(packet)
		return tbl
	end
end

---
-- Handle a packet received from the server
-- @param tbl Table to handle
function net.client.handle(tbl)
	if tbl.action == "ping" then
		net.client.timeout = 0
	elseif tbl.action == "kick" and tbl.id == net.client.id then
		print("[ERR] Player kicked from the server")
		print("[ERR] Reason: " .. tbl.reason)
		net.client.disconnect()
	elseif tbl.action == "connect" then
		-- Convenience tabel for server.lua
		net.client.players[tbl.id] = {
			username = tbl.username,
			id = tbl.id
		}
		net.client.fireEvent(tbl)
	elseif tbl.action == "kick" then
		for index, tbl in pairs(net.client.players) do
			if index == tbl.id then
				net.client.players[index] = net.client.players[#net.client.players]
				net.client.players[#net.client.players] = nil
				break
			end	
		end 
		net.client.fireEvent(tbl)
	else
		net.client.fireEvent(tbl)
	end
end

---
-- Disconnect from the server
function net.client.disconnect()
	net.client.udp:close()
	net.client.connected = false
end

---
-- Add an event listener
-- Should only be used by the Network class
-- @param eventlistener Table with callback functions
function net.client.addEvent(eventlistener)
	net.client.events[#net.client.events + 1] = eventlistener
end

---
-- Remove an event listener
-- Should only be used by the Network class
-- @param eventlistener Table which should be removed
function net.client.removeEvent(eventlistener)
	for index, event in ipairs(net.client.events) do
		if event == eventlistener then
			net.client.events[index] = net.client.events[#net.client.events]
			net.client.events[#net.client.events] = nil
			break
		end
	end
end

---
-- Fire an event to all event listeners
-- Note: Should only be used by net itself
-- @param event Event to fire
function net.client.fireEvent(event)
	event.handle = net.client.players[event.id]
	for _, eventl in ipairs(net.client.events) do
		if event.action == "connect" then
			eventl:onConnect(event)
		elseif event.action == "disconnect" then
			eventl:onDisconnect(event)
		else
			eventl:onAction(event)
		end
	end
end

return net