# rbx-destructor

A **Lua*u* (Roblox)** Object-Oriented class for destructing values of the following supported types:  
- `Function`
- `Dictionary (OOP)`*
- `Thread`
- `RBXScriptConnection`
- `Instance`

---

## API

The API schema comprises **5 members**:

```lua
IsDestructor: (value: any) -> boolean                         -- Returns a <strong>boolean</strong> indicating whether <code>Value</code> is a <strong>Destructor</strong>.
new: () -> Destructor                                         -- Returns a new <strong>Destructor</strong> object.
Add: <Value>(self: Destructor, value: Value, ...any) -> Value -- Adds <code>Value</code> to the <strong>Destructor</strong>.
Remove: (self: Destructor, value: any) -> ()                  -- Removes <code>Value</code> from the <strong>Destructor</strong>.
Destruct: (self: Destructor) -> ()                            -- Destructs all <strong>Values</strong> in the <strong>Destructor</strong>.
```

---

## Notes

`Destructor.Destruct` uses a **function pool map** (a dictionary of destructors indexed by type name) instead of a traditional `if-elseif` chain, resulting in more consistent compute times across supported types.

You can also schedule callbacks to execute during destruction by calling `Add` with a function and its arguments.

Additionally, the class automatically **destructs Tweens** by calling `Cancel` before `Destroy`.

---

\*Dictionaries are destructed by invoking their `Destroy` or `Destruct` key if it exists and is a function.
