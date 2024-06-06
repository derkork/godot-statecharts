# Godot State Charts Manual
<style type="text/css">
img {
    align: center;
    display: block;
    margin-left: auto;
    margin-right: auto;
}
</style>

**__If you prefer to learn in video form, there is also a [video tutorial available on YouTube](https://www.youtube.com/watch?v=E9h9VnbPGuw) to get you started.__**

## Introduction

Godot State Charts is a plugin for Godot Engine that allows you to use state charts in your game. Now what is a state chart? [Statecharts.dev](https://statecharts.dev/) explains it like this:

> Put simply, a state chart is a beefed up state machine.  The beefing up solves a lot of the problems that state machines have, especially state explosion that happens as state machines grow.

Godot State Charts allows you to build state charts in the Godot editor.  The library is built in an idiomatic way, so you can use nodes to define states and transitions and use Godot signals to connect your code to the state machine. As states and transitions are nodes you can also easily modularize your state charts by using scenes for re-using states and transitions.

There is only a single class with two methods for your code to interface with the state chart. This makes it easy to integrate state charts into your game, as you don't need to extend from a base class or implement an interface for your states.


## Installation

### Requirements

This plugin requires Godot 4.0.3 or later. Earlier versions of Godot 4 may work but are not officially supported. The plugin will not work with Godot 3.x.

### Installation with the Godot Asset Library

The easiest way to install the plugin is to use the Godot Asset Library. Search for "Godot State Charts" and install the plugin. You can exclude the `godot_state_charts_examples` folder if you don't need the examples. 

### Manual installation

You can also download a ZIP file of this repository and extract it, then copy the `addons/godot_state_charts` folder into your project's `addons` folder.

After you installed it, make sure you enable the plugin in the project settings:

![Enabling the plugin in the project settings](enable_plugin.png)


### Installation with C#

If you want to use this library with C#, make sure you are using the .NET version of Godot 4. This can be downloaded from the [Godot download page](https://godotengine.org/download). The standard version of Godot 4 does not support C#. If you got Godot from Steam, you have the standard version and need to download the .NET version separately from the Godot website. There are additional installation steps for the Godot .NET version, so make sure you follow the instructions on the [Godot documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html).

After you installed the plugin as described above, you may need to initialize your C# project if you haven't already done so. You can do this by going to the menu _Project_ -> _Tools_ -> _C#_ -> _Create C# solution_.

![Create C# solution](create_csharp_solution.png)

> ⚠️ **Note**: the C# API is currently experimental and may change in the future. Please give it a try and let me know if you encounter any issues.

### Updating from an earlier version

The asset library currently has no support for plugin updates, therefore in order to update the plugin, perform the following steps:

- **Be sure you have a backup of your project or have it under version control, so you can go back in case things don't work out as intended.**
- Check the [CHANGES.md](https://github.com/derkork/godot-statecharts/blob/main/CHANGES.md) for any breaking changes that might impact your project and any special update instructions.
- Download the version you want to install from the [Release List](https://github.com/derkork/godot-statecharts/releases) (use the _Source Code ZIP_ link).
- Close Godot. It's important to not have the project opened while running the update.
- In your project locate the `godot_state_charts` folder within the `addons` folder and delete the `godot_state_charts` folder with all of its contents.
- Unpack your downloaded ZIP file somewhere. Inside of the unpacked ZIP file structure, locate the `godot_state_charts` folder within the `addons` folder.
- Move `godot_state_charts` folder you located in the previous step into the `addons` folder of your project.
- The plugin is now updated. You can now open the project again in Godot and continue working on it.

## Usage

The plugin adds a new node type called _State Chart_. This node represents your state chart and is the only node that your code will directly interact with. 

Below this node you can add the root state of your state chart, this will usually be a _Compound State_ or a _Parallel State_. You can add as many states as you want to your state chart, but you can only have one root state. Below each state you can add _Transition_ nodes. These nodes define the transitions between states. You can add as many transitions as you want to any state. 

You can add nodes through the usual _Add node_ dialog in Godot. Just type "state" or "transition" into the search field and you will see the nodes in the list.

![Creating a node in the editor](create_node.png)

Starting with version 0.2.0 there is also an improved UI to quickly add nodes and transitions with a single click. The UI is displayed automatically when you select a state chart node to which nodes can be added:

![Quickly adding nodes with the improved UI](quick_add_ui.gif)

If you hold down `Shift` while clicking the button for the node you want to add, the newly added node will be selected automatically. Otherwise the node will be added to the currently selected node but the currently selected node will stay selected.

The new UI supports undo/redo, so you can undo the addition of a node or transition with `Ctrl+Z`. You can move the sidebar to the other side of the editor by clicking the <img src="../addons/godot_state_charts/toggle_sidebar.svg" width="16" height="16" title="toggle sidebar icon"> icon at the bottom of the sidebar. 

### Examples

The plugin comes with a few examples. You can find them in the `godot_state_charts_examples` folder. To run an example, open and run it's main scene. The examples are:

- `ant_hill` - a rudimentary ant hill simulation. The ants are controlled by a state chart that handles the different states of the ants such as searching for food, carrying food, returning to the nest, etc. This example shows how state charts can simplify a lot of the if-else logic that is often needed to implement AI.
- `automatic_transitions` - an example that shows how to use automatic transitions that react to changes in expression properties.
- `cooldown` - an example on how to drive UI elements with the `transition_pending` signal. See also the section on [delayed transitions](#delayed-transitions) for more information.
- `csharp` - an example on how to use the API from C#. Note that you need to use the .NET version of Godot 4 for this example to work. See also the section on [installation with C#](#installation-with-c) for more information.
- `history_states` - an example that shows how you can use history states to implement a state machine that can remember the last active state of a compound state. 
- `order_of_events` - an example state chart to explore in which order events are fired. See also the [appendix](#order-of-events) for more information.
- `performance_test` - this example is a small test harness to evaluate how larger amounts of state charts will perform. It contains a state chart in `state_chart.tscn` which you can adapt to match your desired scenario. The actual performance will depend on what callback signals you will use so you should adapt the state chart in `state_chart.tscn` to match your scenario. Then there are scenes named `ten_state_charts.tscn`, `hundred_state_charts.tscn` and `thousand_state_charts.tscn` which each contain 10, 100 or 1000 instances of the state chart from `state_chart.tscn`. You can run these scenes to see how many instances of the state chart  you can run on your machine. Use the profiler to see how much time is spent in the state chart code. 
- `platformer` - a simple platformer game with a state chart for the player character that handles movement, jumping, falling, double jumps, coyote jumps and animation control. This example shows how state charts can massively simplify the code needed to implement a full player character controller. The character controller code is less than 70 lines of code.
- `random_transitions` - an example how to use expressions to randomly transition between states and controlling the length of transition delays.
- `stepping` - an example on how to use stepping mode in a turn-based game. See also the section on [stepping mode](#stepping-mode) for more information.

### The _State Chart_ node

<img src="../addons/godot_state_charts/state_chart.svg" width="32" height="32" align="left"> The _State Chart_ node is your main way of interacting with the state charts. It allows you to send events to the state chart using the `send_event(event)` method. You can also set expression properties with the `set_expression_property(name, value)`  function, which can later be used by expression guards to determine whether a certain transition should be taken (see the section on expression guards for more information).


### States

States are the building blocks from which you build your state charts. A state can be either active or inactive.  On start the root state of the state chart will be activated. When a state has child states, one or more of these child states will be activated as well. States provide a range of signals which you can use to react to state changes or to execute code while the state is active. The following signals are available:

- `state_entered()` - this signal is emitted when the state is entered.
- `state_exited()` - this signal is emitted when the state is exited.
- `event_received(event)` - this signal is emitted when an event is received by the state while the state is active. The event is passed as a parameter.
- `state_processing(delta)` - this signal is emitted every frame while the state is active. The delta time is passed as a parameter. The signal will obey pause mode of the tree, so if the node is paused, this signal will not be emitted.
- `state_physics_processing(delta)` - this signal is emitted every physics frame while the state is active. The delta time is passed as a parameter. The signal will obey pause mode of the tree, so if the node is paused, this signal will not be emitted.
- `state_stepped()` - called whenever the `step` method of the state chart is called. See [stepping mode](#stepping-mode) for more information on stepping mode.
- `state_input(input_event)` - called when input is received while the state is active. This is useful to limit input to certain states.
- `state_unhandled_input(input_event)` - called when unhandled input is received while the state is active. Again this is useful to limit input to certain states.
- `transition_pending(initial_delay, remaining_delay)` - called every frame while a [delayed transition](#delayed-transitions) is pending for this state. The initial and remaining delay of the transition in seconds are passed as parameters. This can be used to drive progress bars or cooldown indicators or trigger additional effects at certain time indices during the transition. An example of this can be found in the `cooldown` demo. Note, that this is never called for transitions without a delay.

#### Connecting to state signals from code

Most of the time you will want to connect signals directly from the editor UI, as this is where you edit your state chart. However, if you wish, you can of course also connect to the signals from code by using the `connect` function like with any other Node in Godot. For example, to connect to the `state_entered` signal you can do the following:

```gdscript

func _ready():
    var state: State = %ActiveState
    state.state_entered.connect(_on_state_entered)

func _on_state_entered():
    # do something
``` 

If you want to connect to signals in C#, you will need to use the C# `State` wrapper class. It provides a set of `SignalName` constants which you can use if you want to connect to the signals from C# code without having to rely on hard-coded strings. This is similar to how all other nodes in Godot do this. For example you can connect to the `state_entered` signal like this:

```csharp
using Godot;
using GodotStateCharts;

public class MyNode : Node
{

    private void _Ready() {
        // get the active state node
        var state = StateChartState.Of(GetNode("%ActiveState"));
        // connect to the state_entered signal
        state.Connect(StateChartState.SignalName.StateEntered, Callable.From(OnStateEntered));
    }

    private void OnStateEntered()
    {
        // do something
    }
}
```

If you want to connect signals from the editor UI you can just do it like you would do it for any other node. There is no difference whether you use C# or GDScript.

#### Atomic states

<img src="../addons/godot_state_charts/atomic_state.svg" width="32" height="32" align="left"> Atomic states are the most basic type of state. They cannot have child states. Atomic states have no additional properties.

#### Compound states

<img src="../addons/godot_state_charts/compound_state.svg" width="32" height="32" align="left"> Compound states are states which have at least one child state (though having at least two child states makes more sense). Only one child state of a compound state can be active at any given time. Compound states have the following properties:

- _Initial state_ - this property determines which child state will be activated when the compound state is entered directly. You can always activate a child state by explicitly transitioning to it. If you do not set an initial state then no child state will be activated and an error will be printed to the console.

<img src="compound_state.png" width="400" alt="Compound state properties">

Compound states have two signals in addition to the signals that all states have, which allow you to run common code whenever a child state of the compound state is entered/exited:

- `child_state_entered()` - called when any child state is entered.
- `child_state_exited()` - called when any child state is exited. 

#### Parallel states

<img src="../addons/godot_state_charts/parallel_state.svg" width="32" height="32" align="left"> Parallel states are similar to compound states in that they can have multiple child states. However, all child states of a parallel state are active at the same time when the parallel state is active. They allow you to model multiple states which are independent of each other. As such they are a great tool for avoiding combinatorial state explosion that you can get with simple state machines. Parallel states have no additional properties.

#### History states

<img src="../addons/godot_state_charts/history_state.svg" width="32" height="32" align="left"> History states are pseudo-states. They are not really a state but rather activate the last active state when being transitioned to. They can only be used as child states of compound states. They are useful when you temporarily want to leave a compound state and then return to the state you were in before you left. History states have the following properties:

- _Deep_ - if true the history state will capture and restore the state of the whole sub-tree below the compound state. If false the history state will only capture and restore the last active state of its immediate parent compound state.
- _Default state_ - this is the state which will be activated if the history state is entered and no history has been captured yet. If you do not set a default state, the history state will not activate any state when it is entered and an error will be printed to the console.


<img src="history_state.png" width="400" alt="History state properties">

To use a history state, set up a transition that transitions directly to the history state. This will restore the last known state or activate the default state if no history has been captured yet. If your compound state has a history state as a child but you do not want to restore the history when entering the compound state, you can transition to the compound state directly. This will activate the initial state of the compound state and will not restore the history. Also check the history state example in the examples folder.

#### Animation tree states

> ⚠️ **Note**: this feature is currently experimental and may change or be replaced in the future.

<img src="../addons/godot_state_charts/animation_tree_state.svg" width="32" height="32" align="left"> Animation tree states are a variation of atomic states. They can be linked to an animation tree. When an animation tree state is activated it will ask the animation tree to travel to the same state (the animation tree state and the state inside the animation tree should have the same name). This can be used to control animation trees with the same state chart events that you use to control your game logic. Animation tree states have the following properties:

- _Animation tree_ - the animation tree that should be controlled by the animation tree state.
- _State Name_ - the name of the state inside the animation tree that should be activated when the animation tree state is activated. This is optional, if you do not set a state name, the animation tree state will activate the state with the same name as the animation tree state.

<img src="animation_tree_state.png" width="400" alt="Animation tree state properties">

Animation tree states are usually independent of the rest of the states, so it is usually a good idea to use a parallel state to separate them from the rest of the states.

![Separation of animation tree states](animation_tree_state_separation.png)


#### Animation player states

> ⚠️ **Note**: this feature is currently experimental and may change or be replaced in the future.

<img src="../addons/godot_state_charts/animation_player_state.svg" width="32" height="32" align="left"> Animation player states are similar to animation tree states. They can be linked to an animation player. When an animation player state is activated it will ask the animation player to play the same animation (the animation player state and the animation inside the animation player should have the same name). This can be used to control animation players with the same state chart events that you use to control your game logic. Animation player states have the following properties:

- _Animation player_ - the animation player that should be controlled by the animation player state.
- _Animation Name_ - the name of the animation inside the animation player that should be played when the animation player state is activated. This is optional, if you do not set an animation name, the animation player state will play the animation with the same name as the animation player state.
- _Custom Blend_ - a custom animation blend time. The default is `-1` which will use the animation player's default blend time.
- _Custom Speed_ - a custom animation speed. The default is `1.0` which will play the animation forwards with normal speed. You can use negative values to play the animation backwards or values greater than `1.0` to play the animation faster.
- _From End_ - if true the animation will be played from the end to the beginning. This is useful if you want to play an animation backwards. Note that you will still need to set the custom speed to a negative value to actually play the animation backwards.

<img src="animation_player_state.png" width="400" alt="Animation player state properties">

Similar to animation tree states, animation player states are usually independent of the rest of the states, so it is usually a good idea to use a parallel state to separate them from the rest of the states.

### Events and transitions

<img src="../addons/godot_state_charts/transition.svg" width="32" height="32" align="left"> Transitions allow you to switch between states. Rather than directly switching the state chart to a certain state, you send events to the state chart. You can send events to the state chart by calling the `send_event(event)` method. To send an event you first need to get hold of the state chart node. A simple way to do this is to use the `get_node` function:

```gdscript
# my_node.gd

# Get the state chart node.
@onready var state_chart: StateChart = get_node("StateChart")

func _when_something_happened():
    # Call the send_event function to send an event to the state chart.
    state_chart.send_event("some_event")
```

For C# you cannot easily call the state chart node directly because the underlying functionality is written in GDScript. Therefore this library provides a wrapper class `StateChart` which you can use to interact with the state chart node. You can get an instance of this class by calling the `StateChart.Of` function: 

```csharp
using Godot;
using GodotStateCharts;

public class MyNode : Node
{
    private StateChart stateChart;

    public override void _Ready()
    {
        // first get the state chart node, same as it is done in GDScript
        var stateChartNode = GetNode("StateChart");
        // then use the StateChart.Of function to create a type-safe wrapper.
        stateChart = StateChart.Of(stateChartNode);

        // alternatively you can use the following one-liner:
        // stateChart = StateChart.Of(GetNode("StateChart"));
    }

    private void WhenSomethingHappened()
    {
        // now you can use the wrapper to send events to the state chart, the calls 
        // will be properly translated to the underlying GDScript functions.
        stateChart.SendEvent("some_event");
    }
}
```

When you send an event, it can trigger one or more transitions. For example, if we have a compound state with two child states _Idle_ and _Walking_ and we have set up two transitions, one reacting to the event `move` and one reacting to the event `stop`. The _Idle_ state is the initial state.

![Transition in a compound state](compound_transition.gif)

Now we start by sending the `move` event to the state chart. The compound state will forward the event to the currently active state, which is the _Idle_ state. On the _Idle_ state a transition reacting to the `move` event is defined, so this transition will execute and the state chart will switch to the  _Walking_ state. 

Now we send a `stop` event to the state chart. The currently active state is now _Walking_ so the the compound state will forward the event to the _Walking_ state. On the _Walking_ state a transition reacting to the `stop` event is defined, so that transition will execute and the state chart will switch back to the _Idle_ state.

In deeper state charts, events will be passed to the active states going all the way down until an active leaf state (a state which has no more child states) is reached. Now all transitions of that state will be checked, whether they react to that event. If a transition reacts to that event it will be queued for execution and the event is considered as handled. If no transition handles a given event, the event will bubble up to the parent state until it is consumed or reaches the root state. If the event reaches the root state and is not consumed, it will be ignored.

> ⚠️ **Note:** The initial state of a state chart will only be entered one frame after the state chart's `_ready` function ran. It is done this way to give nodes above the state chart time to run their `_ready` functions before any state chart logic is triggered. 
> 
> This means that if you call `send_event`, `set_expression_property` or `step` in a `_ready` function things will most likely not work as expected. If you must call any of these functions in a `_ready` function, you can use `call_deferred` to delay the event sending by one frame, e.g. `state_chart.send_event.call_deferred("some_event")`. 

##### Multiple transitions on the same state
A single state can have multiple transitions. If this is the case, all transitions will be checked from top to bottom and the first transition that reacts to the event will be executed. If you want to have multiple transitions that react to the same event, you can use [guards](#transition-guards) to determine which transition should be taken.

##### Event selection and management

Starting with version 0.12.0 the plugin provides a dropdown for events in the editor UI. This dropdown allows you to quickly select an event from a list of all events that are currently used in the state chart. This helps to avoid typos and makes it easier to find the event you are looking for.

![Event dropdown](event_dropdown.png)

The dropdown also has "Manage..." entry which allows you to rename events that are used in the state chart. This is useful if you want to rename an event that is used in multiple transitions. 

![Renaming an event](event_rename.png)

In the dialog, select the event you want to rename and enter the new name. All transitions in the current state chart that use the event will be updated automatically. You can undo the renaming by pressing `Ctrl+Z`. Also note, that renaming an event will not rename the event in your code, so you will have to update the event name in your code manually.

##### Transition taken signal

Each transition provides a `taken` signal which is fired when the transition is taken. This is useful if you need to determine how you left a state, which you cannot do with the `state_exited` signal alone. You can use this signal run side effects when a specific transition is taken. For example the platformer demo uses the signal to run the double-jump animation when the player leaves the _Double Jump_ state through the _On Jump_ transition. 

The signal is only emitted when the transition is taken, not when it is pending. This means that if you have a transition with a delay, the signal will only be emitted when the transition is actually executed. If the transition is discarded for any reason, the signal will not be emitted.

#### Automatic transitions

It is possible to have transitions with an empty _Event_ field. These transitions will be evaluated whenever you change a state, send an event or set an expression property (see [expression guards](#expression-guards)). This is useful for modeling [condition states](https://statecharts.dev/glossary/condition-state.html) or react to changes in expression properties. Usually you will put a guard on such an automatic transition to make sure it is only taken when a certain condition is met. 

![Alt text](immediate_transition.png)

Note that automatic transitions will still only be evaluated for currently active states.

#### Delayed transitions

Transitions can execute immediately or after a certain time has elapsed. If a transition has no time delay it will be executed immediately (within the same frame). If a transition has a time delay, it will be marked as pending and executed after the time delay has elapsed but only if the state to which the transition belongs is still active at this time and was not left temporarily. Only one transition can ever be active or pending for any given state. So if another transition is executed for a state while one is pending, the pending transition will be discarded. A pending transition is also cancelled when the state is left through other means (e.g. because a parent state got deactivated). There is one exception to this rule, when you are using history states. When you leave a state and re-enter it through a history state, then any pending transition will be resumed as if you had never left the state.

When you have a transition that is both delayed and automatic, the transition will be marked as pending when it's condition is met. If subsequently the condition is no longer met, it will still be executed unless another transition is marked as pending in the meantime or the state is left through other means.

Transition delay is an expression, which means you can not only put in a number of seconds, but also use expressions to calculate the delay. This is useful if you want to have a random delay or a delay that depends on an expression property - e.g. a cooldown that depends on the player's level or a random delay for an enemy to make it less predictable.

#### Transition guards

A transition can have a guard which determines whether the transition should be taken or not. If a transition reacts to an event the transition's guard will be evaluated. If the guard evaluates to `true` the transition will be taken. Otherwise the next transition which reacts to the event will be checked. If a transition has no guard, it will always be taken. Guards can be nested to create more complex guards. The following guards are available:

- <img src="../addons/godot_state_charts/all_of_guard.svg" width="16" height="16" align="left"> _AllOfGuard_ - this guard evaluates to `true` if all of its child guards evaluate to `true` (logical AND).
- <img src="../addons/godot_state_charts/any_of_guard.svg" width="16" height="16" align="left"> _AnyOfGuard_ - this guard evaluates to `true` if any of its child guards evaluate to `true` (logical OR).
- <img src="../addons/godot_state_charts/not_guard.svg" width="16" height="16" align="left"> _NotGuard_ - this guard evaluates to the opposite of its child guard.
- <img src="../addons/godot_state_charts/state_is_active_guard.svg" width="16" height="16" align="left"> _StateIsActiveGuard_ - this guard allows you to configure and monitor a state. The guard evaluates to `true` if the state is active and to `false` if the state is inactive.
- <img src="../addons/godot_state_charts/expression_guard.svg" width="16" height="16" align="left"> _ExpressionGuard_ - this guard allows you to use expressions to determine whether the transition should be taken or not. 

##### Expression guards
Expression guards give you the most flexibility when it comes to guards. You can use expressions to determine whether a transition should be taken or not. Expression guards are evaluated using the [Godot Expression](https://docs.godotengine.org/en/stable/classes/class_expression.html) class. You can add so-called _expression properties_ to the state chart node by calling the `set_expression_property(name, value)` method. 

```gdscript
@onready var state_chart: StateChart = $StateChart

func _ready():
    # Set an expression property called "player_health" with the value 100
    state_chart.set_expression_property("player_health", 100)
```

In C# this is done very similarly, again using the type-safe wrapper:


```csharp
using Godot;
using GodotStateCharts;

public class MyNode : Node
{
    private StateChart stateChart;

    public override void _Ready()
    {
        stateChart = StateChart.Of(GetNode("StateChart"));
        stateChart.SetExpressionProperty("player_health", 100);
    }
}
```

These expression properties can then be used in your expressions. The following example shows how to use expression guards to check whether the player's health is below 50%: 

![Example of an expression guard for transitioning into berserk mode when player's health sinks below 50%](expression_guard.png)

> **Note:** all expressions for the expression guards are written in GDScript even if you use C# to interact with the StateChart.

It is important to make sure that your code sets any expression property used by the guard before the guard is first evaluated. For example, if your guard uses a `player_health` expression property, you will need to call `set_expression_property('player_health', some_health)` _before_ the guard is evaluated. Otherwise the guard will not be able to evaluate the expression because it has no value for `player_health`. It is recommended that you use the `_ready`/`_Ready` method to initialize all expression properties used in your state chart with some sane default value.

### Event queueing mechanism

It is possible to send events or change expression properties in state callbacks like `state_entered`. This would in turn also trigger transitions. Because at this time we may already be in the process of transitioning to one or more new states, the library will queue up transitions that may result from these changes until after the current transition has finished. This will ensure that one set of transitions is fully executed including all calls to callbacks before the next one happens. If callbacks set expression properties, the changed expression property will be immediately visible, but automatic transitions resulting from this change will only run after the current transition is fully processed. For example if you set an expression property during `state_entered` the new value of this property will already be visible to automatic transitions that run on state enter. If you don't want this, consider calling `set_expression_property` deferred (e.g. `set_expression_property.call_deferred("property_name", value)`).

In general the library tries to preserve order of events as much as possible though there may be some edge cases where this will not be possible. If you encounter such a case, please report it and we'll try to find a solution.

### Debugging

#### Debugging in-game with the state chart debugger

<img src="../addons/godot_state_charts/utilities/state_chart_debugger.svg" width="32" height="32" align="left"> When the game is running it is very useful to see the current state of the state chart for debugging purposes. For this, this library contains a state chart debugger that you can add to your scene. You can add it to your scene by pressing the "Instantiate child scene" icon above the node tree and then looking for "debugger":

![Adding the state chart debugger](add_statechart_debugger.gif)

 The debugger is a control node that you can position anywhere in your scene where it makes sense (maybe you already have an in-game debugging screen where you can add it). Since it is a control it can easily be integrated into an existing UI.

![The state chart debugger](state_chart_debugger.png)

The state chart debugger has a property _Initial node to watch_ where you can set a node that should be watched. It doesn't necessarily need to be a state chart node, the debugger will search for a state chart anywhere below the node you set. This is useful when you have the state chart nested in a sub-scene and you want to watch the state chart from the root scene where you don't have access to the state chart node.

You can also use the `debug_node` function of the state chart debugger to change the node that is being watched at runtime. For example you could add code that changes the debugged node when clicking on a unit or object in your game

```gdscript
@onready var debugger: StateChartDebugger = $StateChartDebugger

func _on_unit_clicked(unit):
    debugger.debug_node(unit)
```

In C# there is another wrapper class `StateChartDebugger` which you can use to interact with the debugger. You can get an instance of this class by calling the `StateChartDebugger.Of` function: 

```csharp
using Godot;    
using GodotStateCharts;

public class MyNode : Node
{
    private StateChartDebugger debugger;

    public override void _Ready()
    {
        // get the debugger node and wrap it in a type-safe wrapper
        debugger = StateChartDebugger.Of(GetNode("StateChartDebugger"));
    }

    private void OnUnitClicked(Node unit)
    {
        // change the node that is being watched by the debugger
        debugger.DebugNode(unit);
    }
}
```

Another option is to directly use built-in signals and set the node to debug in the editor UI. This is how it was done in the example projects:

![Setting the node to debug with the editor UI.](debugger_with_signals.png)

At runtime, the state chart debugger will show the current state of the state chart, including all currently set expression properties. It also indicates time left for delayed transitions, so you have a good overview of what is going on in your state chart.

![Live view of the state chart debugger](state_chart_debugger_live.png)

By default, the state chart debugger will track state changes in the state chart it watches and print them into the "History" tab. This way you can see which state transitioned into which state and when. 

![Tracking history with the debugger](debugger_history_tracking.png)


You can add custom lines into the history by calling the `add_history_entry` function. This is useful if you want to have additional information in the history. 

```gdscript
debugger.add_history_entry("Player died")
```

The C# wrapper also provides a `AddHistoryEntry` function which you can use to add custom entries to the history.

```csharp
debugger.AddHistoryEntry("Player died");
```

The debugger will only track state changes of the currently watched state chart. If you connect the debugger to a different state chart, it will start tracking the state changes of the new state chart.

If you want to disable the history tracking, you can unset the _Auto Track State Changes_ checkbox in the editor UI.

#### Debugging in the editor 

> ⚠️ **Note**: this feature is currently in preview and may still have some rough edges. Please report any issues you encounter.

Starting with version 0.10.0 the plugin contains an in-editor debugger, which shows the current state of any tracked state chart in the currently running game.  

![The in-editor debugger](in_editor_debugger.png)

This feature is opt-in, so for a state chart to appear in the debugger, you need to set the _Track in Editor_ property of the state chart to `true`.

![Track the current state chart in the editor](track_in_editor.png)

Once this is set, the state chart will appear in the in-editor debugger when the game is running. From there you can select a state chart in the tree on the left and see its current state and history on the right. As with the in-game debugger you have flags to toggle whether events, state changes and transitions should appear in the history. 

The in-editor debugger has some limitations compared to the in-game debugger:

- In general the in-editor debugger requires debug information sent from the game to the editor via a network connection. This takes longer and has a higher overhead than the in-game debugger which can directly access and display the state chart data. This means that the in-editor debugger will always slightly lag behind. It also limits how much information can be shown in the editor before the network connection gets overloaded.
- If you have a large amount of tracked state charts (eg. more than a few dozen) you will get warnings that the network connection is overloaded and the data displayed in the in-editor debugger will be incomplete or outdated. This is a fundamental limitation of the debugging process and unlikely to change in the future - there is only so much data a connection can handle.
- The feature is completely disabled when the game is not running from the editor. This means you cannot use it to remote-debug an exported game. 
- You cannot see the expression properties as they would need to be serialized and sent over the network whenever they change, which adds a lot of overhead. Also some of the data may not be serializable at all.
- You cannot inject custom history entries into the history as the remote debugger has no public API. This feature would require a unified API for both the in-game and in-editor debugger which is currently not available and would introduce breaking changes. 

## Stepping mode

If you have a turn based game where you want to execute code depending on which state you are in but you don't want to run this code every frame in `_process` or `_physics_process` but rather every turn, you can use stepping mode. In this case, you will connect your state handling code not to the `state_processing` or `state_physics_processing` signals, but rather to the `state_stepped` signal. 

Then you call the `step` function of the state chart whenever want to calculate the "next round".  

```gdscript
func _on_next_round_button_pressed():
    state_chart.step() # calculate the next round based on the current state
```

In C# you can use the `Step` function of the `StateChart` wrapper class:

```csharp
private void OnNextRoundButtonPressed()
{
    stateChart.Step();
}
```

This will emit the `state_stepped` signal for all states which are currently active. You can connect your code to this signal to execute it every time the state chart is stepped.


## Tips & tricks

### Keep state and logic separate

State charts work best when you keep the state and the logic separate. This means that the state charts should contain all the rules for changing states while your code should only contain the logic that is executed when being in a state or when entering or leaving a state. You should not track the current state in your code, that is the responsibility of the state chart. The `StateChart` class deliberately does not expose the current state of the state chart for this reason.

Instead, use the provided state events to trigger logic in your code. Many times you don't even need to write any code. For example if you have a bomb that explodes and you want to play a sound when it enters the _Exploding_ state, you can simply link up the `state_entered` signal of the _Exploding_ state to the `play` function of your audio player.

![Running code when a state is entered.](running_code_on_state_entering.png)

If you only want to allow input in certain states, connect the `state_processing` or `state_physics_processing` signals to the same method of your code for all the states where the input is allowed. You can see one example of this in the platformer example, where jumping is only allowed in certain states:

![Running the same code in multiple states](running_same_code_in_multiple_states.png)

The way this is set up the code doesn't need to know which states may exist or when you are allowed to jump. The state chart takes care of that and the jumping code is only executed when the state chart is in a state where jumping is allowed.

```gdscript
## Called in states that allow jumping, we process jumps only in these.
func _on_jump_enabled_state_physics_processing(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		_state_chart.send_event("jump")
```

Or in C#:

```csharp
private void OnJumpEnabledStatePhysicsProcessing(float delta)
{
    if (Input.IsActionJustPressed("ui_accept"))
    {
        velocity.y = JUMP_VELOCITY;
        stateChart.SendEvent("jump");
    }
}
```

### Remember that events bubble up in the chart tree

When you have multiple states that need to react on the same event, you can handle the event in the parent state. For example in the platformer demo, the frog can be in multiple different states while it is airborne.

![Sub-states of the airborne state](airborne_substates.png)

However no matter in which specific airborne state the frog is, once it lands on the ground it always should transition back to the _Grounded_ state. Therefore the transition for handling this has been added to the _Airborne_ state. This way the transition will be taken no matter in which specific airborne state the frog is. Since no sub-state of _Airborne_  (_CoyoteJumpEnabled_, _DoubleJumpEnabled_, _CannotJump_) handles the event, the event will bubble up to the parent state _Airborne_ and the transition will be taken.

### Give everything meaningful names

Because both states and transitions are nodes, it is very easy to rename them in the editor. Use this to provide meaningful names for your states and transitions. This makes it easier to understand what is going on in your state chart and also makes it easier to find the right node in the editor. Transitions should have the event they react on in their name, for example _On Jump_ or _On Attack_.  State names should be descriptive, for example _Grounded_, _Airborne_, _CoyoteJumpEnabled_, _DoubleJumpEnabled_, _CannotJump_. Since you will never type a state name or transition name directly in your code, you can use longer names that are easy to understand.

### Use the built-in "Editor Description" feature

Godot has a very nice built-in comment field named "Editor Description". Use this to write down some thoughts about why a state or transition exists and how it works in conjunction with other states and transitions. This is especially useful when you have a complex state chart with many states and transitions. Just like you write comments for your code, it is a good idea to write comments for your state charts.

![An example of the editor description](editor_description.png)


## Appendix

### Order of events

Usually you don't need to worry too much about the order in which state changes are processed but there are some instances where it is important to know the order in which events are processed. The following will give you an overview on the inner workings and the order in which events are processed.

#### Generic event handling rules

The state chart reacts to these events:

- an explicit event was sent to the state chart node using the `send_event` function.
- an expression property was changed using the `set_expression_property` function.
- 
Whenever an event occurs, the state chart will try to find transitions that react to this event. Only transitions in states that are currently active will be considered. Transitions will be checked in a depth-first manner. So the innermost transition that handles any given event (be it explicit or automatic) will run. When a transition runs, the event is considered as handled and will no longer be processed by any other transition, except if that other transition happens to live in a parallel state (each parallel state can handle events even if that event was already handled by another parallel state). If the transition has a guard and it evaluates to `false` then the next transition that reacts to the event will be checked. If no transition reacts to the event, the event will bubble up to the parent state. This process will continue until the event is handled or the root state is reached. If the event is not handled by any state, it will be ignored. 

#### Example
For this example we will use the following state chart:

![Example state chart for the order of events](order_of_events_chart.png) 

When the program starts, state _B_ is active. Since it is a parallel state, it will automatically activate its child states, _B1_ and _B2_. This is the starting position.

![The starting position](ooe_starting_position.png)


Now we send an event to the state chart that will trigger a transition to state _C_. Now the following things will happen:

- Since we leave _B_, the child states _B1_ and _B2_ will exited. They are exited in the order in which they are defined, so first _B1_ and then _B2_. This will also emit the `state_exited` signal on each of the child states.
- Then _B_ will exit and emit the `state_exited` signal.
- Now we enter _C_ which is a compound state. First the `state_entered` signal will be emitted on _C_. Now _C_ will look for its initial state which is _C1_ and will activate it. This will emit the `state_entered` signal on _C1_.
- We can see that _C1_ has a transition named _Immediately to C2_ which will immediately transition the active state from _C1_ to _C2_. This will emit the `state_exited` signal on _C1_ and the `state_entered` signal on _C2_.
- On _C2_ we have another little contraption, a receiver on _C2_'s `state_entered` signal. This will send an event to the state chart which triggers the _To C3_ transition. So we will immediately transition from _C2_ to _C3_. This will emit the `state_exited` signal on _C2_ and the `state_entered` signal on _C3_.
- Until here, everything happens within the same frame. On _C3_ we have a delayed transition to _C4_ which is executed 0.5 seconds later.  This will emit the `state_exited` signal on _C3_ and the `state_entered` signal on _C4_.

Then we have reached this state:

![The end position](ooe_end_position.png)

Now we can switch back to state _B_ by sending the appropriate event to the state chart. This will trigger the following events:

- Since we leave _C_, the currently active state _C4_ will be exited and the `state_exited` signal will be emitted for this state. Then _C_ will be exited and the `state_exited` signal will be emitted for this state.
- We now enter _B_ again, and fire the `state_entered` signal on _B_. Since _B_ is a parallel state, it will activate its child states _B1_ and _B2_ again. This will emit the `state_entered` signal on _B1_ and _B2_.


You can also see this in action in the `order_of_events` example in the `godot_state_charts_examples` folder. The _History_ tab of the state chart debugger will show you the order in which the events are processed.

![History debugger in action](ooe_debugger.png)

You can also modify this example and explore the order of events yourself.
