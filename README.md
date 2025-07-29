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
IsDestructor: (value: any) -> boolean                         -- Returns a <strong>boolean</strong> indicating whether <code>value</code> is a <strong>Destructor</strong>.
new: () -> Destructor                                         -- Returns a new <strong>Destructor</strong> object.
Add: <Value>(self: Destructor, value: Value, ...any) -> Value -- Adds <code>value</code> to the <strong>Destructor</strong>.
Remove: (self: Destructor, value: any) -> ()                  -- Removes <code>value</code> from the <strong>Destructor</strong>.
Destruct: (self: Destructor) -> ()                            -- Destructs all <strong>values</strong> in the <strong>Destructor</strong>.
```

---

## Example

Below is a **code excerpt** for a box selection tool where **Destructor** is used heavily:

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

---

## Notes

`Destructor.Destruct` uses a **function pool map** (a dictionary of destructors indexed by type name) rather than an `if-elseif` chain. This ensures more consistent compute times across supported types.

You can **schedule callbacks** to execute during destruction by calling `Destructor.Add` with a function and its arguments.

**Tweens** are destructed by calling `Tween:Cancel()` before `Instance:Destroy()`.

The class was **inspired by** similar alternatives like [**Maid**](https://github.com/Quenty/NevermoreEngine/blob/main/src/maid/src/Shared/Maid.lua), [**Janitor**](https://github.com/howmanysmall/Janitor), and [**Trove**](https://github.com/Sleitnick/RbxUtil/blob/main/modules/trove/init.luau), but written around a year and a half ago as a spin-off to fit my own needs.

> **Note:** This module was **never benchmarked**. Microseconds weren't a priority during writing. If you have optimizations, please submit a pull request.

---

*Dictionaries are destructed by invoking their `Destroy` or `Destruct` key with the dictionary as the argument if it exists and is a function.
