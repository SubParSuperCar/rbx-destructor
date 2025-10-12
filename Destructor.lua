--!strict
--!native
local DICTIONARY_DESTRUCTOR_KEYS = {"Destruct", "Destroy"} -- Key(s) to index dictionary for successful destructor.
local THROW_WARNING_NO_DESTRUCTOR = true -- Throw warning if no destructor for data type.

type UInt = number -- [0 .. ∞)
type Array = {any}

type VarArgs<Type> = Type -- Sugar for variable arguments.

type Iterator = (Array, UInt?) -> (UInt?, any)
type Destruct = (self: Destructor) -> ()

type Implementation = {
	__index: Implementation,
	__len: (self: Destructor) -> UInt,
	__iter: (self: Destructor) -> (Iterator, Array),
	IsDestructor: (value: any) -> boolean, -- Returns a *boolean* indicating whether `value` is a *Destructor*.
	new: () -> Destructor, -- Returns a new *Destructor* object.
	Extend: (self: Destructor, once: boolean?) -> Destructor, -- Returns a new sub-*Destructor* object that calls `Destruct` when the parent *Destructor* `self` calls `Destruct`. If `once` is *true*, `Destruct` will only be called once.
	Add: <Value>(self: Destructor, value: Value, ...VarArgs<any>) -> Value, -- Adds `value` to the *Destructor*. If `value` is a *function*, it will be thunked with varargs `...`, and will throw an error if `Destruct` is executing.
	Remove: <Value>(self: Destructor, value: Value, all: boolean?) -> VarArgs<Value>, -- Removes the first value matching `value` from the *Destructor* and returns it if found. If `all` is *true*, all values matching `value` will be removed and returned, not just the first.
	Clear: (self: Destructor) -> (), -- Removes all values from the *Destructor* without destructing them.
	Destruct: Destruct, -- Destructs and removes all values from the *Destructor*. Throws an error if called during execution. *2
	Destroy: Destruct -- Alias for the `Destruct` method. (*1)
}

type Properties = {
	_Values: Array,
	_IsDestructing: boolean -- Mutex-like behavior to prevent cyclic re-entry hangs. (*2)
}

export type Destructor = typeof(
	setmetatable(
		{} :: Properties,
		{} :: Implementation
	)
)

local Destructor = {} :: Implementation
Destructor.__index = Destructor

function Destructor:__len(): UInt
	return #self._Values
end

function Destructor:__iter(): (Iterator, Array)
	return next, self._Values
end

function Destructor.IsDestructor(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Destructor
end

function Destructor.new(): Destructor
	return setmetatable({
		_Values = {},
		_IsDestructing = false
	}, Destructor)
end

-- Error handler for destructors calling provided callbacks.
local function _DestructorErrorHandler(message: string)
	warn(debug.traceback(message))
end

function Destructor:Extend(once: boolean?): Destructor
	assert(not once or once == true, `Argument 'Once' to method 'Extend' on {self} is {once} and not a boolean or nil.`)

	local destructor = self:Add(Destructor.new())

	if once then
		return destructor
	end

	-- Pack table.insert arguments for brevity.
	local Persister: Persister, ArgumentPackages: {Array}

	-- Define on separate line from assignment to preserve function name for traceback. (*3)
	local function _DestructorEntryPersister()
		task.defer(function()
			for _, argumentPackage in ArgumentPackages do
				local values: Array, value = unpack(argumentPackage)

				-- Only insert if not at index.
				if values[1] ~= value then
					table.insert(values, 1, value)
				end
			end
		end)
	end

	Persister = _DestructorEntryPersister

	ArgumentPackages = {
		{self._Values, destructor},
		{destructor._Values, Persister}
	}

	Persister()

	type Persister = typeof(Persister)

	return destructor
end

function Destructor:Add<Value>(value: Value, ...: VarArgs<any>): Value
	local entry: any = value

	if type(value) == "function" then
		-- *2
		assert(not self._IsDestructing, `Called method 'Add' on {self} with argument 'Value' as {value} and not a function or while variable 'IsDestructing' is {self._IsDestructing} and not falsy.`)

		-- table.pack return comprises key 'n' indicating arity; ignored by unpack.
		local varargs = table.pack(...)

		-- Only wrap if varargs are provided to minimize compute time & memory pressure.
		if varargs.n ~= 0 then
			-- *3
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

function Destructor:Remove<Value>(value: Value, all: boolean?): ...VarArgs<Value>
	assert(not all or all == true, `Argument 'All' to method 'Remove' on {self} is {all} and not a boolean or nil.`)

	local values = self._Values

	-- Remove and return value if found.
	if not all then
		local index = table.find(values, value)

		return index and table.remove(values, index)
	end

	-- Remove and return all found values.
	local removed, lastIndex = {}, 1

	while true do
		-- Continue from last found index to minimize compute time.
		local index = table.find(values, value, lastIndex)

		if not index then
			break
		end

		table.remove(values, index)
		table.insert(removed, value)

		lastIndex = index :: any
	end

	return unpack(removed)
end

function Destructor:Clear()
	table.clear(self._Values)
end

type TypeNames = string
type Destructors = (any) -> ()

-- Function pool map of destructors indexed by type name for compute time consistency.
local Destructors: {[TypeNames]: Destructors}

do
	-- *3
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

		-- Call first successful destructor found.
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
	assert(not self._IsDestructing, `Called method 'Destruct' on {self} while variable 'IsDestructing' is {self._IsDestructing} and not falsy.`)

	self._IsDestructing = true

	local values = self._Values

	while true do
		local index, value = next(values)

		if index == nil then
			break
		end

		values[index] = nil

		local key = typeof(value)
		local destructor = Destructors[key]

		if destructor then
			destructor(value)
		elseif THROW_WARNING_NO_DESTRUCTOR then
			warn(`Called method 'Destruct' on {self} while type of argument '{value}' is {key} and index of {Destructors} is {destructor} and not a function.`)
		end
	end

	self._IsDestructing = false
end

-- *1
Destructor.Destroy = Destructor.Destruct

return Destructor
