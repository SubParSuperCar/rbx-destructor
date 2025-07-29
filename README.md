# rbx-destructor

A simple and useful **Lua*u* (Roblox)** Object-Oriented class for **destructing values** of the following supported types:  
- `Function`
- `Dictionary (OOP)`*
- `Thread`
- `RBXScriptConnection`
- `Instance`

---

## API

The **API schema** comprises **5 members**:

```lua
IsDestructor: (value: any) -> boolean                         -- Returns a <strong>boolean</strong> indicating whether <code>Value</code> is a <strong>Destructor</strong>.
new: () -> Destructor                                         -- Returns a new <strong>Destructor</strong> object.
Add: <Value>(self: Destructor, value: Value, ...any) -> Value -- Adds <code>Value</code> to the <strong>Destructor</strong>.
Remove: (self: Destructor, value: any) -> ()                  -- Removes <code>Value</code> from the <strong>Destructor</strong>.
Destruct: (self: Destructor) -> ()                            -- Destructs all <strong>Values</strong> in the <strong>Destructor</strong>.
```

---

## Notes

`Destructor.Destruct` uses a **function pool map** (a dictionary of destructors indexed by type name) rather than an `if-elseif` chain. This ensures more consistent compute times across supported types.  

You can **schedule callbacks** to execute during destruction by calling `Destructor.Add` with a function and its arguments.  

The class also **destructs Tweens** by calling `Tween.Cancel` before `Instance.Destroy`.  

This module was **inspired by** similar alternatives like [**Maid**](https://github.com/Quenty/NevermoreEngine/blob/main/src/maid/src/Shared/Maid.lua), [**Janitor**](https://github.com/howmanysmall/Janitor), and [**Trove**](https://github.com/Sleitnick/RbxUtil/blob/main/modules/trove/init.luau), but written as a spin-off to fit my own needs.  

> **Note:** The class was **never benchmarked**. Microseconds weren't a priority during writing. If you have optimizations, please submit a pull request.

---

*Dictionaries are destructed by invoking their `Destroy` or `Destruct` key if it exists and is a function.
