class "Nil"

function Nil:Nil()
end

function Nil:_Nil()
end

local meta = getmetatable(Nil)
meta.__index = function(tbl, key)
	return function() end
end