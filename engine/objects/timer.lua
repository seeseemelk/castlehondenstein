---
-- Timer class. Does stuff at intervals
-- @class table
-- @name Timer
class "Timer"

local timers = {}

--- Constructor
function Timer:Timer()
	-- Add to the controllables list
	if not self.timers then
		timers[#timers + 1] = self
		self.timers = {}
	end
end

--- Destructor
function Timer:_Timer()
	-- Remove from the controllables list
	for index, timer in ipairs(timers) do
		if timer == self then
			timers[index] = timers[#timers]
			timers[#timers] = nil
			break
		end
	end
end

---
-- Call a method every n seconds
-- @param time Interval in seconds
-- @param callback Method to call (string)
-- @return A timer handle
function Timer:addTimer(interval, callback)
	self.timers[#self.timers + 1] = {
		interval = interval,
		callback = callback,
		object = self,
		left = interval
	}
	return self.timers[#self.timers]
end

---
-- Remove a timer
-- @param handle The timer handle to remove
function Timer:removeTimer(handle)
	for index, timer in ipairs(self.timers) do
		if timer == handle then
			self.timers[index] = nil
			return
		end
	end
end

---
-- Callback that is called right before every frame
-- @param dt Deltatime, time passed since last frame in seconds
function Timer:update(dt)
	for _, timer in ipairs(self.timers) do
		timer.left = timer.left - dt
		if timer.left <= 0 then
			timer.object[timer.callback](timer.object)
			timer.left = timer.left + timer.interval
		end
	end
end

function love.update(dt)
	-- We still have the let the net code run
	net.client.update(dt)

	for _, timer in ipairs(timers) do
		timer:update(dt)
	end
end