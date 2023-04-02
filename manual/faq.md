# Frequently Asked Questions

## I installed the plugin but I don't see the state charts nodes!

Make sure you enabled the plugin in the project settings. In the menu go to _Project_ -> _Project Settings_. This opens the project settings dialog. There select the _Plugins_ tab and tick the _Enable_ checkbox near the _Godot State Charts_ plugin.

## Can you backport the library to Godot 3?

I'm afraid not. While it technically would be totally possible to do so, I don't have the bandwidth for maintaining two versions of the library. I prefer to focus on the latest version of Godot, which is currently 4.

## Can I use this library with C#?

Yes, but you'll need to call the methods on the `StateChart` node through `Call`, as it is not a C# class. If you get an instance of the StateChart node, you can call the functions like this:

```csharp
var stateChart = GetNode<Node>("StateChart");

// Send an event to the state chart
stateChart.Call("send_event", "some_event");

// Set an expression guard properties
stateChart.Call("set_expression_property", "health", 27);
stateChart.Call("set_expression_property", "shields", 48); 
```

The rest of the library works on Godot's signals, so you can nicely connect them to C# methods using the `Connect` method or the editor UI. Since there are no interfaces to implement or classes to derive from, you can use the library in a C# project without any problems.
