--!strict
--!native
local Destructor = {} :: DestructorImplementation
Destructor.__index = Destructor

type DestructorImplementation = {
	__index: DestructorImplementation,
	__len: (self: Destructor) -> number,
	__iter: (self: Destructor) -> (Destructor, number?) -> (number?, any),
	IsDestructor: (value: any) -> boolean,
	new: () -> Destructor,
	Add: <Value>(self: Destructor, value: Value, ...any) -> Value,
	Remove: (self: Destructor, value: any) -> (),
	Destruct: (self: Destructor) -> ()
}

type DestructorProperties = {
	_Values: {any}
}

export type Destructor = typeof(
	setmetatable(
		{} :: DestructorProperties,
		{} :: DestructorImplementation
	)
)

local Destructors = {
	["function"] = function(callback: (...any) -> (...any))
		callback()
	end,
	table = function(source: {[any]: any})
		local destruct = source.Destruct

		if type(destruct) == "function" then
			destruct(source)

			return
		end

		local destroy = source.Destroy

		if type(destroy) == "function" then
			destroy(source)
		end
	end,
	thread = function(thread: thread)
		pcall(task.cancel, thread)
	end,
	RBXScriptConnection = function(connection: RBXScriptConnection)
		connection:Disconnect()
	end,
	Instance = function(instance: Instance)
		if instance:IsA("Tween") then
			instance:Cancel()
		end

		instance:Destroy()
	end
}

function Destructor:__len(): number
	return #self._Values
end

function Destructor:__iter(): (Destructor, number?) -> (number?, any)
	return next, self._Values
end

function Destructor.IsDestructor(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Destructor
end

function Destructor.new(): Destructor
	return setmetatable({
		_Values = {}
	}, Destructor)
end

function Destructor:Add<Value>(value: Value, ...: any): Value
	if type(value) == "function" then
		local arguments = {...}

		table.insert(self._Values, function()
			value(unpack(arguments))
		end)
	else
		table.insert(self._Values, value)
	end

	return value
end

function Destructor:Remove(value: any)
	local values = self._Values
	local index = table.find(values, value)

	if index then
		table.remove(values, index)
	end
end

function Destructor:Destruct()
	local values = self._Values
	local index, value = next(values)

	while value ~= nil do
		values[index :: any] = nil

		local destructor = Destructors[typeof(value)]

		if destructor then
			destructor(value)
		end

		index, value = next(values)
	end
end

return Destructor
