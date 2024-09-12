---
layout: page
title: Nodes
permalink: /usage/nodes
description: "States are the building blocks from which you build your state charts."
---

# {{ page.title }}

## Table of Contents
- [The State Chart Node](#the-state-chart-node)
- [States](#states)
  - [Connecting to state signals from code](#connecting-to-state-signals-from-code)
- [Atomic states](#atomic-states)
- [Compound states](#compound-states)
- [Parallel states](#parallel-states)
- [History states](#history-states)
- [Animation tree states](#animation-tree-states)
- [Animation player states](#animation-player-states)

## The _State Chart_ Node

The ![State Chart node icon]({{ site.baseurl }}/assets/img/manual/icons/state_chart.svg){:class="state-icon"} _State Chart_ node is your main way of interacting with the state charts. It allows you to send events to the state chart using the `send_event(event)` method. You can also set expression properties with the `set_expression_property(name, value)`  function, which can later be used by [expression guards]({{site.baseurl}}/usage/events-and-transitions#expression-guards) to determine whether a certain transition should be taken (see the section on expression guards for more information).

## States

States are the building blocks from which you build your state charts. A state can be either active or inactive.  On start the root state of the state chart will be activated. When a state has child states, one or more of these child states will be activated as well. States provide a range of signals which you can use to react to state changes or to execute code while the state is active. The following signals are available:

- `state_entered()` - this signal is emitted when the state is entered.
- `state_exited()` - this signal is emitted when the state is exited.
- `event_received(event)` - this signal is emitted when an event is received by the state while the state is active. The event is passed as a parameter.
- `state_processing(delta)` - this signal is emitted every frame while the state is active. The delta time is passed as a parameter. The signal will obey pause mode of the tree, so if the node is paused, this signal will not be emitted.
- `state_physics_processing(delta)` - this signal is emitted every physics frame while the state is active. The delta time is passed as a parameter. The signal will obey pause mode of the tree, so if the node is paused, this signal will not be emitted.
- `state_stepped()` - called whenever the `step` method of the state chart is called. See [stepping mode]({{ site.baseurl }}/stepping-mode) for more information on stepping mode.
- `state_input(input_event)` - called when input is received while the state is active. This is useful to limit input to certain states.
- `state_unhandled_input(input_event)` - called when unhandled input is received while the state is active. Again this is useful to limit input to certain states.
- `transition_pending(initial_delay, remaining_delay)` - called every frame while a [delayed transition]({{ site.baseurl }}/usage/events-and-transitions#delayed-transitions) is pending for this state. The initial and remaining delay of the transition in seconds are passed as parameters. This can be used to drive progress bars or cooldown indicators or trigger additional effects at certain time indices during the transition. An example of this can be found in the `cooldown` demo. Note, that this is never called for transitions without a delay.

### Connecting to state signals from code

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

## Atomic states

_Atomic states_ ![Atomic State icon]({{ site.baseurl }}/assets/img/manual/icons/atomic_state.svg){:class="state-icon"} are the most basic type of state. They cannot have child states. Atomic states have no additional properties.

## Compound states

_Compound states_ ![Compound state icon]({{ site.baseurl }}/assets/img/manual/icons/compound_state.svg){:class="state-icon"} are states which have at least one child state (though having at least two child states makes more sense). Only one child state of a compound state can be active at any given time. Compound states have the following properties:

![Compound state properties]({{ site.baseurl }}/assets/img/manual/compound_state.png){:class="native-width centered"}

- _Initial state_ - this property determines which child state will be activated when the compound state is entered directly. You can always activate a child state by explicitly transitioning to it. If you do not set an initial state then no child state will be activated and an error will be printed to the console.

Compound states have two signals in addition to the signals that all states have, which allow you to run common code whenever a child state of the compound state is entered/exited:

- `child_state_entered()` - called when any child state is entered.
- `child_state_exited()` - called when any child state is exited.

## Parallel states

_Parallel states_ ![Parallel state icon]({{ site.baseurl }}/assets/img/manual/icons/parallel_state.svg){:class="state-icon"} are similar to compound states in that they can have multiple child states. However, all child states of a parallel state are active at the same time when the parallel state is active. They allow you to model multiple states which are independent of each other. As such they are a great tool for avoiding combinatorial state explosion that you can get with simple state machines. Parallel states have no additional properties.

## History states

History states ![History state icon]({{ site.baseurl }}/assets/img/manual/icons/history_state.svg){:class="state-icon"} are so-called "pseudo-states". They are not really a state but rather activate the last active state when you transition to them. They can only be used as child states of compound states. They are useful when you temporarily want to leave a compound state and then return to the state you were in before you left. History states have the following properties:

![History state properties]({{ site.baseurl }}/assets/img/manual/history_state.png){:class="native-width centered"}
- _Deep_ - if true the history state will capture and restore the state of the whole sub-tree below the compound state. If false the history state will only capture and restore the last active state of its immediate parent compound state.
- _Default state_ - this is the state which will be activated if the history state is entered and no history has been captured yet. If you do not set a default state, the history state will not activate any state when it is entered and an error will be printed to the console.

To use a history state, set up a transition that transitions directly to the history state. This will restore the last known state or activate the default state if no history has been captured yet. If your compound state has a history state as a child, but you do not want to restore the history when entering the compound state, you can transition to the compound state directly. This will activate the initial state of the compound state and will not restore the history. Also check the history state example in the examples folder.

## Animation tree states

> ⚠️ **Note**: this feature is currently experimental and may change or be removed in the future.

_Animation tree states_ ![Animation tree state icon]({{ site.baseurl }}/assets/img/manual/icons/animation_tree_state.svg){:class="state-icon"} are a variation of atomic states. They can be linked to an animation tree. When an animation tree state is activated it will ask the animation tree to travel to the same state (the animation tree state and the state inside the animation tree should have the same name). This can be used to control animation trees with the same state chart events that you use to control your game logic. Animation tree states have the following properties:

![Animation tree state properties]({{ site.baseurl }}/assets/img/manual/animation_tree_state.png){:class="native-width centered"}
- _Animation tree_ - the animation tree that should be controlled by the animation tree state.
- _State Name_ - the name of the state inside the animation tree that should be activated when the animation tree state is activated. This is optional, if you do not set a state name, the animation tree state will activate the state with the same name as the animation tree state.

Animation tree states are usually independent of the rest of the states, so it is usually a good idea to use a parallel state to separate them from the rest of the states.

![Separation of animation tree states]({{ site.baseurl }}/assets/img/manual/animation_tree_state_separation.png)


## Animation player states

> ⚠️ **Note**: this feature is currently experimental and may change or be removed in the future.

_Animation player states_ ![Animation player state icon]({{ site.baseurl }}/assets/img/manual/icons/animation_player_state.svg){:class="state-icon"} are similar to animation tree states. They can be linked to an animation player. When an animation player state is activated it will ask the animation player to play the same animation (the animation player state and the animation inside the animation player should have the same name). This can be used to control animation players with the same state chart events that you use to control your game logic. Animation player states have the following properties:

![Animation player state properties]({{ site.baseurl }}/assets/img/manual/animation_player_state.png){:class="native-width centered"}
- _Animation player_ - the animation player that should be controlled by the animation player state.
- _Animation Name_ - the name of the animation inside the animation player that should be played when the animation player state is activated. This is optional, if you do not set an animation name, the animation player state will play the animation with the same name as the animation player state.
- _Custom Blend_ - a custom animation blend time. The default is `-1` which will use the animation player's default blend time.
- _Custom Speed_ - a custom animation speed. The default is `1.0` which will play the animation forwards with normal speed. You can use negative values to play the animation backwards or values greater than `1.0` to play the animation faster.
- _From End_ - if true the animation will be played from the end to the beginning. This is useful if you want to play an animation backwards. Note that you will still need to set the custom speed to a negative value to actually play the animation backwards.

Similar to animation tree states, animation player states are usually independent of the rest of the states, so it is usually a good idea to use a parallel state to separate them from the rest of the states.
