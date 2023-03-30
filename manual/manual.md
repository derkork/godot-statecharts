# Godot State Charts Manual

## Introduction

Godot State Charts is a plugin for Godot Engine that allows you to use state charts in your game. Now what is a state chart? [Statecharts.dev](https://statecharts.dev/) explains it like this:

> Put simply, a state chart is a beefed up state machine.  The beefing up solves a lot of the problems that state machines have, especially state explosion that happens as state machines grow.

Godot State Charts allows you to build state charts in the Godot editor.  The library is built in an idiomatic way, so you can use nodes to define states and transitions and use Godot signals to connect your code to the state machine. As states and transitions are nodes you can also easily modularize your state charts by using scenes for re-using states and transitions.

There is only a single class with two methods for your code to interface with the state chart. This makes it easy to integrate state charts into your game, as you don't need to extend from a base class or implement an interface for your states.

## Installation

The easiest way to install the plugin is to use the Godot Asset Library. Search for "Godot State Charts" and install the plugin. You can exclude the `examples` folder if you don't need the examples. 

You can also download a ZIP file of this repository and extract it, then copy the `addons/godot_state_charts` folder into your project's `addons` folder.


## Usage

The plugin adds a new node type called _State Chart_. This node represents your state chart and is the only node that your code will directly interact with. 

Below this node you can add the root state of your state chart, this will usually be a _Compound State_ or a _Parallel State_. You can add as many states as you want to your state chart, but you can only have one root state. Below each state you can add _Transition_ nodes. These nodes define the transitions between states. You can add as many transitions as you want to any state.

![example image of a state chart](state_chart_example.png)

### The _State Chart_ node

The _State Chart_ node is your main way of interacting with the state charts. It allows you to send events to the state chart using the `send_event(event)` method. You can also set expression properties with the `set_expression_property(name, value)`  function, which can later be used by expression guards to determine whether a certain transition should be taken (see the section on expression guards for more information).


### States

States are the building blocks from which you build your state charts. A state can be either active or inactive.  On start the root state of the state chart will be activated. When a state has child states, one or more of these child states will be activated as well. States provide a range of signals which you can use to react to state changes or to execute code while the state is active. The following signals are available:

- `state_entered()` - this signal is emitted when the state is entered.
- `state_exited()` - this signal is emitted when the state is exited.
- `event_received(event)` - this signal is emitted when an event is received by the state while the state is active. The event is passed as a parameter.
- `state_processing(delta)` - this signal is emitted every frame while the state is active. The delta time is passed as a parameter. The signal will obey pause mode of the tree, so if the node is paused, this signal will not be emitted.
- `state_physics_processing(delta)` - this signal is emitted every physics frame while the state is active. The delta time is passed as a parameter. The signal will obey pause mode of the tree, so if the node is paused, this signal will not be emitted.

#### Atomic states

Atomic states are the most basic type of state. They cannot have child states. Atomic states have no additional properties.

#### Compound states

Compound states are states which have at least one child state (though having at least two child states makes more sense). Only one child state of a compound state can be active at any given time. Compound states have the following properties:

- _Initial state_ - this property determines which child state will be activated when the compound state is entered directly. You can always activate a child state by explicitly transitioning to it. If you do not set an initial state then no child state will be activated and an error will be printed to the console.

![Compound state properties](compound_state.png)

#### Parallel states

Parallel states are similar to compound states in that they can have multiple child states. However, all child states of a parallel state are active at the same time when the parallel state is active. They allow you to model multiple states which are independent of each other. As such they are a great tool for avoiding combinatorial state explosion that you can get with simple state machines. Parallel states have no additional properties.

#### History states

History states are pseudo-states. They are not really a state but rather activate the last active state when being transitioned to. They can only be used as child states of compound states. They are useful when you temporarily want to leave a compound state and then return to the state you were in before you left. History states have the following properties:

- _Deep_ - if true the history state will capture and restore the state of the whole sub-tree below the compound state. If false the history state will only capture and restore the last active state of its immediate parent compound state.
- _Default state_ - this is the state which will be activated if the history state is entered and no history has been captured yet. If you do not set a default state, the history state will not activate any state when it is entered and an error will be printed to the console.

![History state properties](history_state.png)

### Events and transitions

Transitions allow you to switch between states. Rather than directly switching the state chart to a certain state, you send events to the state chart. These events then trigger one or more transitions.  You can send events to the state chart by calling the `send_event(event)` method. For example, if we have a compound state with two child states _Idle_ and _Walking_ and we have set up two transitions, one reacting to the event `move` and one reacting to the event `stop`. The _Idle_ state is the initial state.

![Transition in a compound state](compound_transition.gif)

Now we start by sending the `move` event to the state chart. The compound state will forward the event to the currently active state, which is the _Idle_ state. On the _Idle_ state a transition reacting to the `move` event is defined, so this transition will execute and the state chart will switch to the  _Walking_ state. 

Now we send a `stop` event to the state chart. The currently active state is now _Walking_ so the the compound state will forward the event to the _Walking_ state. On the _Walking_ state a transition reacting to the `stop` event is defined, so that transition will execute and the state chart will switch back to the _Idle_ state.

In deeper state charts, events will be passed to the active states going all the way down until an active leaf state (a state which has no more child states) is reached. Now all transitions of that state will be checked, whether they react to that event. If a transition reacts to that event it will be queued for execution and the event is considered as handled. If no transition handles a given event, the event will bubble up to the parent state until it is consumed or reaches the root state. If the event reaches the root state and is not consumed, it will be ignored.

#### Transitions on entering a state

It is possible to immediately transition elsewhere when a state is entered. This is useful for modeling [condition states](https://statecharts.dev/glossary/condition-state.html). To make a transition execute immediately when a state is entered, leave the _Event_ field empty. Usually you will put a guard on such a transition to make sure it is only taken when a certain condition is met.

![Alt text](immediate_transition.png)

#### Delayed transitions

Transitions can execute immediately or after a certain time has elapsed. If a transition has no time delay it will be executed in the next frame after the event triggering it has been sent. If a transition has a time delay, it will be executed after the time delay has elapsed but only if the state to which the transition belongs is still active and was not left temporarily. Once a state is left, all transitions which were queued for execution will be discarded. There is one exception to this rule, when you are using history states. This is explained in more detail in the section on history states.

#### Transition guards

A transition can have a guard which determines whether the transition should be taken or not. If a transition reacts to an event the transition's guard will be evaluated. If the guard evaluates to `true` the transition will be taken. Otherwise the next transition which reacts to the event will be checked. If a transition has no guard, it will always be taken. Guards can be nested to create more complex guards. The following guards are available:

- _AllOfGuard_ - this guard evaluates to `true` if all of its child guards evaluate to `true` (logical AND).
- _AnyOfGuard_ - this guard evaluates to `true` if any of its child guards evaluate to `true` (logical OR).
- _NotGuard_ - this guard evaluates to the opposite of its child guard.
- _StateIsActiveGuard_ - this guard allows you to configure and monitor a state. The guard evaluates to `true` if the state is active and to `false` if the state is inactive.
- _ExpressionGuard_ - this guard allows you to use expressions to determine whether the transition should be taken or not. 

##### Expression guards
Expression guards give you the most flexibility when it comes to guards. You can use expressions to determine whether a transition should be taken or not. Expression guards are evaluated using the [Godot Expression](https://docs.godotengine.org/en/stable/classes/class_expression.html) class. You can add so-called _expression properties_ to the state chart node by calling the `set_expression_property(name, value)` method. 

```gdscript
@onready var state_chart: StateChart = $StateChart

func _ready():
    # Set an expression property called "player_health" with the value 100
    state_chart.set_expression_property("player_health", 100)
```
These properties can then be used in your expressions. The following example shows how to use expression guards to check whether the player's health is below 50%:

![Example of an expression guard for transitioning into berserk mode when player's health sinks below 50%](expression_guard.png)

### Debugging

When the game is running it is very useful to see the current state of the state chart for debugging purposes. For this, this library contains a state chart debugger that you can add to your scene. 

You can add the debugger through the _Add Node_ dialog. Search for _StateChartDebugger_ and add it to your scene. It is a tree control that you can position anywhere in your scene where it makes sense (maybe you already have an in-game debugging screen where you can add it).

![The state chart debugger](state_chart_debugger.png)

The state chart debugger is has a property _Initial node to watch_ where you can set a node that should be watched. It doesn't necessarily need to be a state chart node, the debugger will search for a state chart anywhere below the node you set. This is usefuly when you have the state chart nested in a sub-scene and you want to watch the state chart from the root scene where you don't have access to the state chart node.

You can also use the `debug_node` function of the state chart debugger to change the node that is being watched at runtime. For example you could add code that changes the debugged node when clicking on a unit or object in your game

```gdscript
@onready var debugger: StateChartDebugger = $StateChartDebugger

func _on_unit_clicked(unit):
    debugger.debug_node(unit)
```

Another option is to directly use built-in signals and set the node to debug in the editor UI. This is how it was done in the example projects:

![Setting the node to debug with the editor UI.](debugger_with_signals.png)

At runtime, the state chart debugger will show the current state of the state chart, including all currently set expression properties. It also indicates time left for delayed transitions, so you have a good overview of what is going on in your state chart.

![Live view of the state chart debugger](state_chart_debugger_live.png)

## Tips and tricks

### Keep state and logic separate

State charts work best when you keep the state and the logic separate. This means that the state charts should contain all the rules for changing states while your code should only contain the logic that is executed when when being in a state or when entering or leaving a state. You should not track the current state in your code, that is the responsibility of the state chart. The `StateChart` class deliberately does not expose the current state of the state chart for this reason.

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

### Remember that events bubble up in the chart tree

When you have multiple states that need to react on the same event, you can handle the event in the parent state. For example in the platformer demo, the frog can be in multiple different states while it is airborne.

![Sub-states of the airborne state](airborne_substates.png)

However no matter in which specific airborne state the frog is, once it lands on the ground it always should transition back to the _Grounded_ state. Therefore the transition for handling this has been added to the _Airborne_ state. This way the transition will be taken no matter in which specific airborne state the frog is. Since no sub-state of _Airborne_  (_CoyoteJumpEnabled_, _DoubleJumpEnabled_, _CannotJump_) handles the event, the event will bubble up to the parent state _Airborne_ and the transition will be taken.

### Give everything meaningful names

Because both states and transitions are nodes, it is very easy to rename them in the editor. Use this to provide meaningful names for your states and transitions. This makes it easier to understand what is going on in your state chart and also makes it easier to find the right node in the editor. Transitions should have the event they react on in their name, for example _On Jump_ or _On Attack_.  State names should be descriptive, for example _Grounded_, _Airborne_, _CoyoteJumpEnabled_, _DoubleJumpEnabled_, _CannotJump_. Since you will never use a state name or transition name directly in your code, you can use longer names that are easy to understand.