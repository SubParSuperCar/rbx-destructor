--!strict
--!native
local DICTIONARY_DESTRUCTOR_KEYS = {"Destruct", "Destroy"} -- Key(s) to index dictionary for callable destructor.

type Integer = number
type VarArgs<Type> = Type -- Sugar for variable arguments.

type Iterator = (Destructor, Integer?) -> (Integer?, any)

type Destruct = (self: Destructor) -> ()

type Implementation = {
	__index: Implementation,
	__len: (self: Destructor) -> Integer,
	__iter: (self: Destructor) -> Iterator,
	IsDestructor: (value: any) -> boolean,
	new: () -> Destructor,
	Add: <Value>(self: Destructor, value: Value, ...VarArgs<any>) -> Value,
	Remove: <Value>(self: Destructor, value: Value) -> Value,
	Destruct: Destruct,
	Destroy: Destruct -- Alias for Destruct method. (*1)
}

type Properties = {
	_Values: {any},
	_Destructing: boolean -- Mutex-like behavior to prevent infinite cyclic re-entry hangs. (*2)
}

export type Destructor = typeof(
	setmetatable(
		{} :: Properties,
		{} :: Implementation
	)
)

local Destructor = {} :: Implementation
Destructor.__index = Destructor

function Destructor:__len(): Integer
	return #self._Values
end

function Destructor:__iter(): Iterator
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

function Destructor:Add<Value>(value: Value, ...: VarArgs<any>): Value
	local entry: any = value

	if type(value) == "function" then
		-- *2
		assert(not self._Destructing, `Called method 'Add' on {self} with argument 'Value' as {value} and not a function or while property '_Destructing' is {self._Destructing} and not falsy.`)

		-- table.pack return comprises key 'n' indicating arity; ignored by unpack.
		local varargs = table.pack(...)

		-- Only wrap if varargs are provided to minimize compute time & memory pressure.
		if varargs.n ~= 0 then
			-- Define on separate line from entry assignment to preserve function name for traceback.
			local function _DestructorThunkWrapper()
				value(unpack(varargs))
			end

			entry = _DestructorThunkWrapper
		end
	end

	table.insert(self._Values, entry)

	-- Always return value argument, never wrapper if assigned to entry.
	return value
end

function Destructor:Remove<Value>(value: Value): Value
	local values = self._Values
	local index = table.find(values, value)

	-- Return entry if found.
	return index and table.remove(values, index) :: any
end

type TypeNames = string
type Destructors = (any) -> ()

-- Function pool map of destructors indexed by type name for compute time consistency.
local Destructors: {[TypeNames]: Destructors}

do
	local function _InstanceDestructor(instance: Instance)
		-- Pause if Tween; Destroy does not halt playback.
		if instance:IsA("Tween") then
			instance:Pause()
		end

		instance:Destroy()
	end

	local function _ConnectionDestructor(connection: RBXScriptConnection)
		connection:Disconnect()
	end

	-- Error handler for destructors calling provided callbacks.
	local function _DestructorErrorHandler(message: string)
		warn(debug.traceback(message))
	end

	type Callback = (...any) -> ...any

	local function _CallbackDestructor(callback: Callback)
		xpcall(callback, _DestructorErrorHandler)
	end

	type Dictionary = {[any]: any}

	local Iterator = ipairs({})

	local function _DictionaryDestructor(dictionary: Dictionary)
		-- Ignore if array or mixed table; only index dictionaries.
		if Iterator(dictionary, 0) then
			return
		end

		-- Call first found destructor.
		for _, key in DICTIONARY_DESTRUCTOR_KEYS do
			if
				select(2, xpcall(function()
					local value = dictionary[key]

					if value and type(value) == "function" then
						value(dictionary)

						return true
					end

					return false
				end, _DestructorErrorHandler))
			then
				return
			end
		end
	end

	local function _ThreadDestructor(thread: thread)
		-- Call in protected mode; throws error if thread is running [[nested] coroutine(s)].
		pcall(task.cancel, thread)
	end

	Destructors = {
		Instance = _InstanceDestructor,
		RBXScriptConnection = _ConnectionDestructor,
		["function"] = _CallbackDestructor,
		table = _DictionaryDestructor,
		thread = _ThreadDestructor
	}
end

function Destructor:Destruct()
	-- *2
	assert(not self._Destructing, `Called method 'Destruct' on {self} while property '_Destructing' is {self._Destructing} and not falsy.`)

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

-- *1
Destructor.Destroy = Destructor.Destruct

return Destructor
