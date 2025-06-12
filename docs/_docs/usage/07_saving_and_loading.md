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

There are many ways to save your game in Godot and the right implementation will depend on your game's needs. Godot State Charts provides an interface via Resources that allow you to decide the best way to store the state for your game (for example, writing the Resource to disk or converting it into a JSON representation).

> ⚠️ **Note**: saving and loading of `AnimationPlayer` and `AnimationStateTree` states is not supported, as both of these states are deprecated.

## Saving
To get a saved resource file representing the current state of your state tree, call `StateChartSerializer.serialize(my_state_chart)` in your save game method. This will return a `SerializedStateChart` object. From here, you can either save it to storage with the built-in `ResourceSaver` or convert it into other formats as needed.

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
    save_resource.state_chart = StateChartSerializer.serialize(chart)
    
    # save my non-state-chart game data:
    ...
    
    # save to the path from above
    ResourceSaver.save(save_resource, path)
```

This will save the active status of all states of the state chart as well as any pending transitions and their timings.

## Loading
Loading requires reversing the process to populate a `SerializedStateChart` and it's children, then passing that into the `StateChartSerializer.deserialize(...)` method. How you do this, depends on your game's needs, but a simple way would be to load a `SerializedStateChart` back from a file with Godot's build-in `ResourceLoader` class.

It's important to note that the `StateChartSerializer` updates an existing state chart in your tree on which the state that was previously saved in `SerializedStateChart` is applied. It does not recreate `StateChart` or `StateChartState` nodes from scratch. This is because your scenes already contain state charts which have signals connected to your code and recreating this structure would be very error prone, or downright impossible in some cases. 

Here's an annotated example of loading from `save_and_load` demo game:
```gdscript
# This is the state chart that is currently in the tree and
# onto which we want to apply the state that we previously 
# have saved.
var chart:StateChart 

func load_state() -> void: 
	# set the file path to your saved game
	var path = "user://save_resource.tres"

	# load the global save resource from the file
	var save_resource: SaveResource = ResourceLoader.load(path, "SaveResource")

	# restore state chart internal state
	StateChartSerializer.deserialize(save_resource.state_chart, chart)
	
    # load other non-state-chart data
	...
```

### Loading from an older save

When you change the state chart definition in your game (e.g. add states, remove states, rename states, change state types, add/remove transitions) then previously saved instances of `SerializedStateChart` will become incompatible with your current state chart definition. `StateChartSerializer` will ensure that the `StateChart` in the tree exactly matches the structure of the `SerializedStateChart` before trying to restore the internal state. If the both do not exactly match, then the `StateChartSerializer` will refuse to restore the state and return a list of error messages detailing the problems. The running state chart will not be modified if `SerializedStateChart` is not compatible. This is to ensure consistent, predictable behaviour.

If your state charts have evolved, you will need to write additional code that patches `SerializedStateChart` resources to match the new structure of your state chart. It might also be necessary to change some internals (e.g. which state is currently active) to ensure predictable behaviour for your game. It is recommended that you wrap `SerializedStateChart` into your own saved game resource (like we did in the examples) and add a `game_version` property to this resource, so you can keep track of which version of your game saved the state chart. This way you can run migration logic when loading your game. 

Note that `SerializedStateChart` also has a `version` property, which the `StateChartSerializer` uses to do the same thing, in case this library changes how it serializes state charts. This field is reserved for the `StateChartSerializer` so do not use it to track your game version.
