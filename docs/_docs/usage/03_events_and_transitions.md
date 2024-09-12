---
layout: page
title: Events and transitions
permalink: /usage/events-and-transitions
description: "Transitions allow you to switch between states."
---

# {{ page.title }}

## Table of Contents

- [Transitions](#transitions)
- [Multiple transitions on the same state](#multiple-transitions-on-the-same-state)
- [Event selection and management](#event-selection-and-management)
- [Transition taken signal](#transition-taken-signal)
- [Automatic transitions](#automatic-transitions)
- [Delayed transitions](#delayed-transitions)
- [Transition guards](#transition-guards)
- [Expression guards](#expression-guards)
- [Event queueing mechanism](#event-queueing-mechanism)

## Transitions
_Transitions_ ![Transition icon]({{ site.baseurl }}/assets/img/manual/icons/transition.svg){:class="state-icon"} allow you to switch between states. Rather than directly switching the state chart to a certain state, you send events to the state chart. You can send events to the state chart by calling the `send_event(event)` method. To send an event you first need to get hold of the state chart node. A simple way to do this is to use the `get_node` function:

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

![Transition in a compound state]({{ site.baseurl }}/assets/img/manual/compound_transition.gif)

Now we start by sending the `move` event to the state chart. The compound state will forward the event to the currently active state, which is the _Idle_ state. On the _Idle_ state a transition reacting to the `move` event is defined, so this transition will execute and the state chart will switch to the  _Walking_ state.

Now we send a `stop` event to the state chart. The currently active state is now _Walking_ so the the compound state will forward the event to the _Walking_ state. On the _Walking_ state a transition reacting to the `stop` event is defined, so that transition will execute and the state chart will switch back to the _Idle_ state.

In deeper state charts, events will be passed to the active states going all the way down until an active leaf state (a state which has no more child states) is reached. Now all transitions of that state will be checked, whether they react to that event. If a transition reacts to that event it will be queued for execution and the event is considered as handled. If no transition handles a given event, the event will bubble up to the parent state until it is consumed or reaches the root state. If the event reaches the root state and is not consumed, it will be ignored.

> ⚠️ **Note:** The initial state of a state chart will only be entered one frame after the state chart's `_ready` function ran. It is done this way to give nodes above the state chart time to run their `_ready` functions before any state chart logic is triggered.
>
> This means that if you call `send_event`, `set_expression_property` or `step` in a `_ready` function things will most likely not work as expected. If you must call any of these functions in a `_ready` function, you can use `call_deferred` to delay the event sending by one frame, e.g. `state_chart.send_event.call_deferred("some_event")`.

## Multiple transitions on the same state
A single state can have multiple transitions. If this is the case, all transitions will be checked from top to bottom and the first transition that reacts to the event will be executed. If you want to have multiple transitions that react to the same event, you can use [guards](#transition-guards) to determine which transition should be taken.

## Event selection and management

Starting with version 0.12.0 the plugin provides a dropdown for events in the editor UI. This dropdown allows you to quickly select an event from a list of all events that are currently used in the state chart. This helps to avoid typos and makes it easier to find the event you are looking for.

![Event dropdown]({{ site.baseurl }}/assets/img/manual/event_dropdown.png){:class="native-width centered"}

The dropdown also has "Manage..." entry which allows you to rename events that are used in the state chart. This is useful if you want to rename an event that is used in multiple transitions.

![Renaming an event]({{ site.baseurl }}/assets/img/manual/event_rename.png){:class="native-width centered"}

In the dialog, select the event you want to rename and enter the new name. All transitions in the current state chart that use the event will be updated automatically. You can undo the renaming by pressing `Ctrl+Z`. Also note, that renaming an event will not rename the event in your code, so you will have to update the event name in your code manually.

## Transition taken signal

Each transition provides a `taken` signal which is fired when the transition is taken. This is useful if you need to determine how you left a state, which you cannot do with the `state_exited` signal alone. You can use this signal run side effects when a specific transition is taken. For example the platformer demo uses the signal to run the double-jump animation when the player leaves the _Double Jump_ state through the _On Jump_ transition.

The signal is only emitted when the transition is taken, not when it is pending. This means that if you have a transition with a delay, the signal will only be emitted when the transition is actually executed. If the transition is discarded for any reason, the signal will not be emitted.

## Automatic transitions

It is possible to have transitions with an empty _Event_ field. These transitions will be evaluated whenever you change a state, send an event or set an expression property (see [expression guards](#expression-guards)). This is useful for modeling [condition states](https://statecharts.dev/glossary/condition-state.html) or react to changes in expression properties. Usually you will put a guard on such an automatic transition to make sure it is only taken when a certain condition is met.

![Automatic transition]({{ site.baseurl }}/assets/img/manual/immediate_transition.png){:class="native-width centered"}

Note that automatic transitions will still only be evaluated for currently active states.

## Delayed transitions

Transitions can execute immediately or after a certain time has elapsed. If a transition has no time delay it will be executed immediately (within the same frame). If a transition has a time delay, it will be marked as pending and executed after the time delay has elapsed but only if the state to which the transition belongs is still active at this time and was not left temporarily. Only one transition can ever be active or pending for any given state. So if another transition is executed for a state while one is pending, the pending transition will be discarded. A pending transition is also cancelled when the state is left through other means (e.g. because a parent state got deactivated). There is one exception to this rule, when you are using history states. When you leave a state and re-enter it through a history state, then any pending transition will be resumed as if you had never left the state.

When you have a transition that is both delayed and automatic, the transition will be marked as pending when it's condition is met. If subsequently the condition is no longer met, it will still be executed unless another transition is marked as pending in the meantime or the state is left through other means.

Transition delay is an expression, which means you can not only put in a number of seconds, but also use expressions to calculate the delay. This is useful if you want to have a random delay or a delay that depends on an expression property - e.g. a cooldown that depends on the player's level or a random delay for an enemy to make it less predictable.

## Transition guards

A transition can have a guard which determines whether the transition should be taken or not. If a transition reacts to an event the transition's guard will be evaluated. If the guard evaluates to `true` the transition will be taken. Otherwise the next transition which reacts to the event will be checked. If a transition has no guard, it will always be taken. Guards can be nested to create more complex guards. The following guards are available:

- _AllOfGuard_ ![AllOfGuard icon]({{ site.baseurl }}/assets/img/manual/icons/all_of_guard.svg){:class="state-icon"} - this guard evaluates to `true` if all of its child guards evaluate to `true` (logical AND).
- _AnyOfGuard_ ![AnyOfGuard icon]({{ site.baseurl }}/assets/img/manual/icons/any_of_guard.svg){:class="state-icon"} - this guard evaluates to `true` if any of its child guards evaluate to `true` (logical OR).
- _NotGuard_ ![NotGuard icon]({{ site.baseurl }}/assets/img/manual/icons/not_guard.svg){:class="state-icon"} - this guard evaluates to the opposite of its child guard.
- _StateIsActiveGuard_ ![StateIsActiveGuard icon]({{ site.baseurl }}/assets/img/manual/icons/state_is_active_guard.svg){:class="state-icon"} - this guard allows you to configure and monitor a state. The guard evaluates to `true` if the state is active and to `false` if the state is inactive.
- _ExpressionGuard_ ![ExpressionGuard icon]({{ site.baseurl }}/assets/img/manual/icons/expression_guard.svg){:class="state-icon"} - this guard allows you to use expressions to determine whether the transition should be taken or not.

## Expression guards
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

![Example of an expression guard for transitioning into berserk mode when player's health sinks below 50%]({{ site.baseurl }}/assets/img/manual/expression_guard.png){:class="native-width centered"}

> **Note:** all expressions for the expression guards are written in GDScript even if you use C# to interact with the StateChart.

It is important to make sure that your code sets any expression property used by the guard before the guard is first evaluated. For example, if your guard uses a `player_health` expression property, you will need to call `set_expression_property('player_health', some_health)` _before_ the guard is evaluated. Otherwise the guard will not be able to evaluate the expression because it has no value for `player_health`. You can set some sane initial values in two ways:

1. Starting with version 0.16.0 you can set initial values for expression properties in the state chart inspector:
   ![Setting initial properties in the state chart inspector.]({{ site.baseurl }}/assets/img/manual/initial_property_values.png){:class="native-width centered"}
2. You can use the `_ready`/`_Ready` method to initialize all expression properties used in your state chart with some sane default value by calling `set_expression_property`.

## Event queueing mechanism

It is possible to send events or change expression properties in state callbacks like `state_entered`. This would in turn also trigger transitions. Because at this time we may already be in the process of transitioning to one or more new states, the library will queue up transitions that may result from these changes until after the current transition has finished. This will ensure that one set of transitions is fully executed including all calls to callbacks before the next one happens. If callbacks set expression properties, the changed expression property will be immediately visible, but automatic transitions resulting from this change will only run after the current transition is fully processed. For example if you set an expression property during `state_entered` the new value of this property will already be visible to automatic transitions that run on state enter. If you don't want this, consider calling `set_expression_property` deferred (e.g. `set_expression_property.call_deferred("property_name", value)`).

In general the library tries to preserve order of events as much as possible though there may be some edge cases where this will not be possible. If you encounter such a case, please report it and we'll try to find a solution.
