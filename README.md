# rbx-destructor (I.e. Destructor)

## Overview

A simple, utilitarian, and lightweight **Lua*u* (Roblox) Class** for **destructing values** of the following supported types:
- `Function (Callback)`
- `Dictionary (OOP)`*
- `Thread`
- `RBXScriptConnection`
- `Instance`

---

## API

The API schema (i.e., implementation) is comprised of the following 5 members:

```lua
IsDestructor: (value: any) -> boolean                         -- Returns a *boolean* indicating whether `value` is a *Destructor*.
new: () -> Destructor                                         -- Returns a new *Destructor* object.
Add: <Value>(self: Destructor, value: Value, ...any) -> Value -- Adds `value` to the *Destructor* and returns it. If `value` is a *function*, it will be thunked with varargs `...`, and it will error if `Destruct` is executing.
Remove: <Value>(self: Destructor, value: Value) -> Value      -- Removes `value` from the *Destructor* and returns it if found.
Destruct: (self: Destructor) -> ()                            -- Destructs and removes all values in the *Destructor*. It cannot be called while it is executing.
Destroy: <*Destruct>                                          -- Alias for Destruct.
```

---

## Info

- You can schedule callbacks to execute during destruction by calling `Destructor.Add` with a function and its arguments (variadic).

- Tweens are destructed by using `Tween:Pause()` before `Instance:Destroy()`.

- While destruction is in progress, `Destructor.Add` (with callbacks) and `Destructor.Destruct` cannot be called. This prevents infinite cyclic loops caused by callbacks re-adding themselves.

- `Destructor.Destruct` uses a function pool map (a dictionary of destructors indexed by their associated type names) instead of an `if-elseif` statement chain for more consistent compute times across supported types.

- This class was inspired by other similar alternatives such as [Maid](https://github.com/Quenty/NevermoreEngine/blob/main/src/maid/src/Shared/Maid.lua), [Janitor](https://github.com/howmanysmall/Janitor), and [Trove](https://github.com/Sleitnick/RbxUtil/blob/main/modules/trove/init.luau). It was written in the Spring of 2024 to satisfy my own needs, including some conservative wants.

---

> **Note:** I haven't benchmarked this module's performance. Identifying and implementing micro-optimizations to shave off a few microseconds of compute time wasn't a priority during writing. If you have any reasonable optimizations, please submit a Pull Request, and it may be merged. *Thank you.*

---

**Dictionaries are destructed by invoking their `Destroy` or `Destruct` key with itself as the argument if it exists and is a function.*

---

## Example Usage

Below is an excerpt from the Source of a Box Selection Tool Script in **Baja Builders — Roblox** where `Destructor` is used heavily, showcasing its utility in practice:

```lua
local enabledChangedDestructor = Destructor.new();

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
