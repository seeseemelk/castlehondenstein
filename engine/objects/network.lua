---
-- Network class
-- @class table
-- @name Network
class "Network"

--- Constructor
-- @param asServer Bool, true if server hooks have to be used, false otherwise
function Network:Network(asServer)
	self.asServer = asServer

	if self.asServer then
		net.server.addEvent(self)
	else
		net.client.addEvent(self)
	end
end

--- Desctructor
function Network:_Network()
	if self.asServer then
		net.server.removeEvent(self)
	else
		net.client.removeEvent(self)
	end
end

---
-- This callback is fired everytime a player connects
-- This callback is also fired for your own client
-- @param event The event containing more information
function Network:onConnect(event)
end

---
-- This callback is fired everytime a player disconnects
-- This callback is also fired for your own client
-- @param event The event containing more information
function Network:onDisconnect(event)
end

---
-- This callback is fired everytime a player does an action
-- This callback is also fired for your own client
-- @param event The event containing more information
function Network:onAction(event)
end