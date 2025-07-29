# rbx-destructor
A Lua*u* (Roblox) Object-Oriented Class for Destructing Values of the following supported Types:
* Function
* Dictionary (OOP)*
* Thread
* RBXScriptConnection
* Instance

`Destructor.Destruct` Indexes a Function Pool Map (Dictionary of Functions Indexed by their Type Names) instead of Traversing an `if-elseif` Chain for shorter and more consistent Compute Times. For example, all supported Types will have similar Performance. Additionally, the Class Destructs Tweens by Calling `Cancel` before Calling `Destroy`.

*Dictionaries are Destructed by Calling Index `Destroy` or `Destruct` if they are Functions.
