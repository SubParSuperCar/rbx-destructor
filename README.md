# rbx-destructor
A Lua<i>u</i> (Roblox) Object-Oriented Class for Destructing Values of the following supported Types:
<ul>
  <li>Function</li>
  <li>Dictionary (OOP)*</li>
  <li>Thread</li>
  <li>RBXScriptConnection</li>
  <li>Instance</li>
</ul>

`Destructor.Destruct` Indexes a Function Pool Map (Dictionary of Functions Indexed by their Type Names) instead of Traversing an `if-elseif` Chain for shorter and more consistent Compute Times. For example, all supported Types will have similar Performance. Additionally, the Class Destructs Tweens by Calling `Cancel` before Calling `Destroy`.

* Dictionaries are Destructed by Calling Index `Destroy` or `Destruct` if they are Functions.
