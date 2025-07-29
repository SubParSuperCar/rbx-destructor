# rbx-destructor (Destructor)

## Description

A simple and useful **Lua*u* (Roblox)** Object-Oriented class for **destructing values** of the following supported types:
- `Function (Callback)`
- `Dictionary (OOP)`*
- `Thread`
- `RBXScriptConnection`
- `Instance`

---

## API

The API schema comprises 5 members:

```lua
IsDestructor: (value: any) -> boolean                         -- Returns a boolean indicating whether `value` is a Destructor.
new: () -> Destructor                                         -- Returns a new Destructor object.
Add: <Value>(self: Destructor, value: Value, ...any) -> Value -- Adds `value` to the Destructor.
Remove: (self: Destructor, value: any) -> ()                  -- Removes `value` from the Destructor.
Destruct: (self: Destructor) -> ()                            -- Destructs and removes all values in the Destructor.
```

---

## Notes

`Destructor.Destruct` uses a function pool map (a dictionary of destructors indexed by type name) instead of an `if-elseif` chain for more consistent compute times across supported types.

You can schedule callbacks to execute during destruction by calling `Destructor.Add` with a function and its arguments.

Tweens are destructed by using `Tween:Cancel()` before `Instance:Destroy()`.

The class was inspired by similar alternatives like [Maid](https://github.com/Quenty/NevermoreEngine/blob/main/src/maid/src/Shared/Maid.lua), [Janitor](https://github.com/howmanysmall/Janitor), and [Trove](https://github.com/Sleitnick/RbxUtil/blob/main/modules/trove/init.luau), but written in Q1 2024 as a spin-off to fit my own needs.

> **Note:** This module was never benchmarked. Microseconds weren’t a priority during writing. If you have optimizations, please submit a pull request.

---

**Dictionaries are destructed by invoking their `Destroy` or `Destruct` key if it exists and is a function.
If stored as a method, use `Dictionary:Destroy()` or `Dictionary:Destruct()`.
If stored as a plain function, call `Dictionary.Destroy(Dictionary)` or `Dictionary.Destruct(Dictionary)`.*

---

## Example Usage

Below is a code excerpt from a box selection tool in **Baja Builders — Roblox** where `Destructor` is used heavily, showcasing it's utility:

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
