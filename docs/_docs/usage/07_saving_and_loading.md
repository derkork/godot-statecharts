---
layout: page
title: Saving and Loading
permalink: /usage/saving-and-loading
description: "Here you can find guidance on how to save and load your state chart"
---

# {{ page.title }}

## Table of Contents
- [Saving](#saving)
- [Loading](#loading)

There are many ways to save your game in Godot and the right implentation will depend on your game's needs. Godot State Charts provides an interface via Resources that allow you to decide the best way to store the state for your game (for example, writing the Resource to disk or converting it into a JSON representation).

> ⚠️ **Note**: saving and loading of `AnimationPlayer` and `AnimationStateTree` states is not supported, as both of these states are deprecated.

## Saving
To get a saved resource file representing the current state of your state tree, call `my_state_chart.export_to_resource()` in your save game method. This will return a `SerializedStateChart` object. From here, you can either save it to storage with the built-in ResourceSaver or convert it into other formats as needed.

See the demo games folder for an example of saving game objects and state chart state together (inside the `save_and_load` directory).

Here's an annotated example from `save_and_load`:

```gdscript
func save_state() -> void:
    # set the save file path
    var path = "user://save_resource.tres"
    
    # instantiate a global save resource (with a reference to SerializedStateChart)
    var save_resource: SaveResource = SaveResource.new()
    
    # create the populated SerializedStateChart with the current state
    # SaveResource contains @export var state_chart: SerializedStateChart
    save_resource.state_chart = chart.export_to_resource()
    
    # save my non-state-chart game data:
    ...
    
    # save to the path from above
    ResourceSaver.save(save_resource, path)
```

This will save the active status of all nodes in the tree as well as any pending transitions and their timings.

## Loading
Loading requires reversing the process to populate a `SerializedStateChart` and it's children, then passing that into the `my_state_chart.load_from_resource(resource:SerializedStateChart)` method.

It's important to note that in order for your state chart to load properly, it must be fully instantiated into your node tree before trying to load it. Loading will only update the properties of existing nodes, but will not attempt to create or modify nodes that don't exist in the tree. It is safe to call load after `_ready()` is finished, so likely you'll want to use something like `my_load_method.call_deferred()` to ensure your tree is full set up before loading, if your game doesn't already have the necessary nodes in the tree.

Here's an annotated example of loading from `save_and_load` demo game:
```gdscript
func load_state() -> void:
    # set the file path to your saved game
	var path = "user://save_resource.tres"

    # load the global save resource from the file
	var save_resource: SaveResource = ResourceLoader.load(path, "SaveResource")

    # load the state chart data from the SerializedStateChart
	chart.load_from_resource(save_resource.state_chart)

    # load other non-state-chart data
    ...
```

### Loading from an older save
If you are make updates to your game that add or modify states to your state chart, you will likely need to modify the Resource representation of the StateChart and it's child nodes before calling `load_from_resource()`. The state charts framework attempts to raise warnings when nodes are missing compared to what is expected while loading, but doesn't guarantee to catch every possible permutation of ways the state could have changed. It also will not attempt to make any changes to nodes which did not exist when the state was saved. This could lead to broken states, such as having 2 active AtomicStates under the same CompoundState. When making changes to state charts, it's important to thoroughly test any previous save game states that you wish to keep valid.