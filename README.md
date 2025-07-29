# rbx-destructor
A Lua*u* (Roblox) Object-Oriented Class for Destructing Values of the following supported Types:
* Function
* Dictionary (OOP)*
* Thread
* RBXScriptConnection
* Instance

# API
The API Schema comprises 5 Members and is as follows:
```lua
IsDestructor: (value: any) -> boolean                         -- Returns a <strong>boolean</strong> indicating whether <code>Value</code> is a <strong>Destructor</strong>.
new: () -> Destructor                                         -- Returns a new <strong>Destructor</strong> object.
Add: <Value>(self: Destructor, value: Value, ...any) -> Value -- Adds <code>Value</code> to the <strong>Destructor</strong>.
Remove: (self: Destructor, value: any) -> ()                  -- Removes <code>Value</code> from the <strong>Destructor</strong>.
Destruct: (self: Destructor) -> ()                            -- Destructs all <strong>Values</strong> in the <strong>Destructor</strong>.
```

# Notes
`Destructor.Destruct` Indexes a Function Pool Map (Dictionary of Functions Indexed by their Type Names) instead of Traversing an `if-elseif` Chain for shorter and more consistent Compute Times. For example, all supported Types will have similar Performance. You can Schedule Callbacks to Execute during Destruction by Calling `Add` with the Variadic Function and Variable Arguments. Additionally, the Class Destructs Tweens by Calling `Cancel` before Calling `Destroy`.

*Dictionaries are Destructed by Calling Index `Destroy` or `Destruct` if they are Functions.
