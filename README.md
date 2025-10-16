# rbx-destructor (i.e., Destructor)

## Overview

A minimalist, utilitarian, and lightweight **Luau (Roblox) Class** providing a *practical* API for **destructing values** of the following supported types:
- `Instance (& Tween)`
- `RBXScriptConnection`
- `Function (Callback / Thunk)`
- `Dictionary (Class Object)`*
- `Thread (& Coroutine)`

This Class serves as a general-purpose, expandable *convenience* utility that eliminates the need to manually reference and handle object destruction in your code. Simply instantiate a `Destructor` object, add your values as you go, and call the `Destruct` or `Destroy` method when you are done. You can even recycle the object for repeated destruction cycles.

If you do a lot of Luau programming, we encourage you to give it a try; we’re confident you’ll be hooked!

## API

The **API schema** (i.e., implementation) consists of the following **8 members**:

```lua
IsDestructor: (value: any) -> boolean,                                    -- Returns a *boolean* indicating whether `value` is a *Destructor*.
new: () -> Destructor,                                                    -- Returns a new *Destructor* object.
Extend: (self: Destructor, once: boolean?) -> Destructor,                 -- Returns a new sub-*Destructor* object that calls `Destruct` when the parent *Destructor* `self` calls `Destruct`. If `once` is *true*, `Destruct` will only be called once.
Add: <Value>(self: Destructor, value: Value, ...any) -> Value,            -- Adds `value` to the *Destructor*. If `value` is a *function*, it will be thunked with varargs `...`, and will throw an error if `Destruct` is executing.
Remove: <Value>(self: Destructor, value: Value, all: boolean?) -> ...any, -- Removes the first value matching `value` from the *Destructor* and returns it if found. If `all` is *true*, all values matching `value` will be removed and returned, not just the first.
Clear: (self: Destructor) -> (),                                          -- Removes all values from the *Destructor* without destructing them.
Destruct: (self: Destructor) -> (),                                       -- Destructs and removes all values from the *Destructor*. Throws an error if called during execution.
Destroy: *Destruct                                                        -- Alias for the `Destruct` method.
```

---

## Details

- Instead of nesting destructors with `DestructorObject:Add(Destructor.new())`, use `Destructor:Extend()` for syntactic sugar.
- You can schedule callbacks to execute during destruction by calling `Destructor:Add` with a function and its variadic arguments.
- While destruction is in progress, adding callbacks with `Destructor:Add` and calling `Destructor:Destruct` throws an error. This prevents infinite loops where callbacks re-add themselves.
- You can remove all instances of a value in a destructor using `Destructor:Remove(<Value>, true)`. Additionally, you can remove all values without destructing them by calling `Destructor:Clear`.
- Tweens are stopped with `Tween:Pause()` before their associated `Instance` is destroyed.
- By default, if a value does not have a destructor for its type, a warning will be thrown. This behavior can be toggled via the constant near the top of the Source. We recommend resolving these warnings, as adding indestructible values increases memory pressure.
- `Destructor:Destruct` uses a function pool map (a dictionary of destructors indexed by their associated type names) instead of an `if-elseif` chain for more consistent compute times across supported types.
- This Class was inspired by similar utilities such as [Maid](https://github.com/Quenty/NevermoreEngine/blob/main/src/maid/src/Shared/Maid.lua), [Janitor](https://github.com/howmanysmall/Janitor), and [Trove](https://github.com/Sleitnick/RbxUtil/blob/main/modules/trove/init.luau). It was written in spring 2024 to satisfy my own needs, including some conservative wants.

**By default, dictionaries are destructed by invoking their `Destroy` or `Destruct` key with themselves as the argument, if such a key exists and is a function. You may change these keys via the constant near the top of the Source.*

---

> **Note:** I haven’t benchmarked this module’s performance. Identifying and implementing micro-optimizations to shave off a few microseconds of compute time wasn’t a priority during writing. If you have reasonable optimizations or bug fixes, please submit a Pull Request, and it may be merged. *Thank you.*

---

## Example Usage

Below is an excerpt from the Source of a Box Selection Tool Script in **Baja Builders — Roblox**, where `Destructor` is used heavily, showcasing its utility in practice:

```lua
local enabledChangedDestructor = Destructor.new()

(tool.Enabled :: ValueWrapper.ValueWrapper<boolean>).Changed:Connect(function(enabled: boolean)
	enabledChangedDestructor:Destruct()

	if not enabled then
		return
	end

	Marquee.GroupColor3 = COLOR

	local marqueeModeDisabledDestructor = enabledChangedDestructor:Add(Destructor.new())

	enabledChangedDestructor:Add(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= MARQUEE_MODE_KEY then
			return
		end

		local mouseButton1UpDestructor = marqueeModeDisabledDestructor:Add(Destructor.new())

		marqueeModeDisabledDestructor:Add(Mouse.Button1Down:Connect(function()
			local began = UserInputService:GetMouseLocation()
			local ended = began

			mouseButton1UpDestructor:Add(Mouse.Move:Connect(@native function()
				ended = UserInputService:GetMouseLocation()

				Marquee.AnchorPoint = (began - ended):Sign() * 2 - Vector2.one
				Marquee.Size = UDim2.fromOffset(math.abs(ended.X - began.X), math.abs(ended.Y - began.Y))
			end))

			mouseButton1UpDestructor:Add(Mouse.Move:Once(function()
				Marquee.Position = UDim2.fromOffset(began.X, began.Y)
				Marquee.GroupTransparency = 0
				Marquee.Visible = true

				mouseButton1UpDestructor:Add(UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
						return
					end

					local assets = GetAssetCentroidsInRect(Rect.new(began:Min(ended), began:Max(ended)))

					print(`[{script}]: Selected {#assets} Asset(s).`)

					if UserInputService:IsKeyDown(INVERT_MODE_KEY) then
						selector:InvertSelection(assets)
					else
						selector:SetSelection(assets)
					end
				end))

				mouseButton1UpDestructor:Add(HideTween.Play, HideTween)
			end))
		end))

		marqueeModeDisabledDestructor:Add(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseButton1UpDestructor:Destruct()
			end
		end))
	end))

	enabledChangedDestructor:Add(UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == MARQUEE_MODE_KEY then
			marqueeModeDisabledDestructor:Destruct()
		end
	end))
end)
```

> **Note:** The above Source excerpt is outdated and does not exemplify the new `Extend` and `Clear` methods. An updated Source will be published as soon as it’s available.
