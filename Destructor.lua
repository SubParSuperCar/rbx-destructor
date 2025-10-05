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
	Remove: <Value>(self: Destructor, value: Value) -> Value,
	Destruct: (self: Destructor) -> ()
}

type DestructorProperties = {
	_Values: {any},
	_Destructing: boolean
}

export type Destructor = typeof(
	setmetatable(
		{} :: DestructorProperties,
		{} :: DestructorImplementation
	)
)

local Destructors = {
	["function"] = function(callback: (...any) -> (...any))
		xpcall(callback, function(message: string)
			warn(debug.traceback(message))
		end)
	end,
	table = function(source: {[any]: any})
		xpcall(function()
			local destruct = source.Destruct

			if type(destruct) == "function" then
				destruct(source)

				return
			end

			local destroy = source.Destroy

			if type(destroy) == "function" then
				destroy(source)
			end
		end, function(message: string)
			warn(debug.traceback(message))
		end)
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
		_Values = {},
		_Destructing = false
	}, Destructor)
end

function Destructor:Add<Value>(value: Value, ...: any): Value
	local entry: any = value

	if type(value) == "function" then
		assert(not self._Destructing, `Called {self.Add} on {self} with argument 'Value' as {value} and not function or while property '_Destructing' is {self._Destructing} and not falsy.`)

		if select("#", ...) ~= 0 then
			local varargs = {...}

			local function _DestructorThunk()
				value(unpack(varargs))
			end

			entry = _DestructorThunk
		end
	end

	table.insert(self._Values, entry)

	return value
end

function Destructor:Remove<Value>(value: Value): Value
	local values = self._Values
	local index = table.find(values, value)

	return index and table.remove(values, index) :: any
end

function Destructor:Destruct()
	assert(not self._Destructing, `Called {self.Destruct} on {self} while property '_Destructing' is {self._Destructing} and not falsy.`)

	self._Destructing = true

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

	self._Destructing = false
end

return Destructor
