--!strict
--!native
local DICTIONARY_DESTRUCTOR_KEYS = {"Destruct", "Destroy"} -- Key(s) to index dictionary for successful destructor.
local PERSISTER_MAX_DEPTH = 3 -- Persister call limit to prevent cyclic re-entry hangs. (*1)

type Integer = number
type VarArgs<Type> = Type -- Sugar for variable arguments.

type Values = {any}

type Iterator = (Destructor, Integer?) -> (Integer?, any)
type Destruct = (self: Destructor) -> ()

type Implementation = {
	__index: Implementation,
	__len: (self: Destructor) -> Integer,
	__iter: (self: Destructor) -> Iterator,
	IsDestructor: (value: any) -> boolean, -- Returns a *boolean* indicating whether `value` is a *Destructor*.
	new: (_values: Values?) -> Destructor, -- Returns a new *Destructor* object.
	Extend: (self: Destructor) -> Destructor, -- Returns a new sub-*Destructor* object that calls `Destruct` when the parent *Destructor* `self` calls `Destruct`.
	Add: <Value>(self: Destructor, value: Value, ...VarArgs<any>) -> Value, -- Adds `value` to the *Destructor*. If `value` is a *function*, it will be thunked with varargs `...`, and will throw an error if `Destruct` is executing.
	Remove: <Value>(self: Destructor, value: Value) -> Value, -- Removes `value` from the *Destructor* and returns it if found.
	Destruct: Destruct, -- Destructs and removes all values from the *Destructor*. Throws an error if called while executing.
	Destroy: Destruct -- Alias for the `Destruct` method. (*2)
}

type Properties = {
	_Values: {any}
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

function Destructor.new(_values: Values?): Destructor
	return setmetatable({
		_Values = _values or {}
	}, Destructor)
end

function Destructor:Extend(): Destructor
	local destructor = Destructor.new({self})
	local persister: Persister

	-- Define on separate line from assignment to preserve function name for traceback. (*4)
	local function _DestructorEntryPersister(depth: Integer?)
		local depth = depth or 1

		task.defer(xpcall, function()
			self:Add(destructor)
			self:Add(persister)
		end, function(message: string)
			warn(debug.traceback(message))

			-- *1
			if depth ~= PERSISTER_MAX_DEPTH then
				persister(depth + 1)

				return
			end

			warn(`Variable 'Depth' is {depth} and equal to constant 'PERSISTER_MAX_DEPTH' as {PERSISTER_MAX_DEPTH}.`)
		end)
	end

	persister = _DestructorEntryPersister
	destructor:Add(persister)

	type Persister = typeof(persister)

	return destructor
end

-- Mutex-like behavior to prevent cyclic re-entry hangs. *1 -> (*3)
local IsDestructing = false

function Destructor:Add<Value>(value: Value, ...: VarArgs<any>): Value
	local entry: any = value

	if type(value) == "function" then
		-- *3
		assert(not IsDestructing, `Called method 'Add' on {self} with argument 'Value' as {value} and not a function or while variable 'IsDestructing' is {IsDestructing} and not falsy.`)

		-- table.pack return comprises key 'n' indicating arity; ignored by unpack.
		local varargs = table.pack(...)

		-- Only wrap if varargs are provided to minimize compute time & memory pressure.
		if varargs.n ~= 0 then
			-- *4
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

	local function _DictionaryDestructor(dictionary: Dictionary)
		-- Ignore if array or mixed table; only index dictionaries.
		if ipairs(dictionary)(dictionary, 0) then
			return
		end

		-- Call first found successful destructor.
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
	-- *3
	assert(not IsDestructing, `Called method 'Destruct' on {self} while variable 'IsDestructing' is {IsDestructing} and not falsy.`)

	IsDestructing = true

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

	IsDestructing = false
end

-- *2
Destructor.Destroy = Destructor.Destruct

return Destructor
