local mt = {}
local smt = {}

function mt.__call(tbl, ...)
	local obj = {}
	obj.__parent = tbl
	setmetatable(obj, smt)

	obj[tbl.__name](obj, ...)
	return obj
end

function smt.__index(tbl, key)
	return tbl.__parent[key]
end

local function class(name)
	_G[name] = {}
	_G[name].__name = name

	setmetatable(_G[name], mt)

	return function(...)
		local parents = {...}
		for _, parent in ipairs(parents) do
			for key, value in pairs(parent) do
				if key ~= "__name" and key ~= "__parent" and
					key ~= parent.__name and key ~= parent["_" .. parent.__name] then
						_G[name][key] = value
				end
			end
		end
	end
end

local function delete(class)
	return class["_" .. class.__name](class)
end

return {
	class = class,
	delete = delete
}