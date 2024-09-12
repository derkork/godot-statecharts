---
layout: page
title: Appendix
permalink: /appendix
description: "Here you can find the appendix of the documentation."
---

# Appendix

## Table of Contents
- [Order of events](#order-of-events)
    - [Generic event handling rules](#generic-event-handling-rules)
    - [Example](#example)

## Order of events

Usually you don't need to worry too much about the order in which state changes are processed but there are some instances where it is important to know the order in which events are processed. The following will give you an overview on the inner workings and the order in which events are processed.

### Generic event handling rules

The state chart reacts to these events:

- an explicit event was sent to the state chart node using the `send_event` function.
- an expression property was changed using the `set_expression_property` function.

Whenever an event occurs, the state chart will try to find transitions that react to this event. Only transitions in states that are currently active will be considered. Transitions will be checked in a depth-first manner. So the innermost transition that handles any given event (be it explicit or automatic) will run. When a transition runs, the event is considered as handled and will no longer be processed by any other transition, except if that other transition happens to live in a parallel state (each parallel state can handle events even if that event was already handled by another parallel state). If the transition has a guard and it evaluates to `false` then the next transition that reacts to the event will be checked. If no transition reacts to the event, the event will bubble up to the parent state. This process will continue until the event is handled or the root state is reached. If the event is not handled by any state, it will be ignored.

### Example
For this example we will use the following state chart:

![Example state chart for the order of events]({{ site.baseurl }}/assets/img/manual/order_of_events_chart.png){:class="native-width centered"}

When the program starts, state _B_ is active. Since it is a parallel state, it will automatically activate its child states, _B1_ and _B2_. This is the starting position.

![The starting position]({{ site.baseurl }}/assets/img/manual/ooe_starting_position.png)


Now we send an event to the state chart that will trigger a transition to state _C_. Now the following things will happen:

- Since we leave _B_, the child states _B1_ and _B2_ will exited. They are exited in the order in which they are defined, so first _B1_ and then _B2_. This will also emit the `state_exited` signal on each of the child states.
- Then _B_ will exit and emit the `state_exited` signal.
- Now we enter _C_ which is a compound state. First the `state_entered` signal will be emitted on _C_. Now _C_ will look for its initial state which is _C1_ and will activate it. This will emit the `state_entered` signal on _C1_.
- We can see that _C1_ has a transition named _Immediately to C2_ which will immediately transition the active state from _C1_ to _C2_. This will emit the `state_exited` signal on _C1_ and the `state_entered` signal on _C2_.
- On _C2_ we have another little contraption, a receiver on _C2_'s `state_entered` signal. This will send an event to the state chart which triggers the _To C3_ transition. So we will immediately transition from _C2_ to _C3_. This will emit the `state_exited` signal on _C2_ and the `state_entered` signal on _C3_.
- Until here, everything happens within the same frame. On _C3_ we have a delayed transition to _C4_ which is executed 0.5 seconds later.  This will emit the `state_exited` signal on _C3_ and the `state_entered` signal on _C4_.

Then we have reached this state:

![The end position]({{ site.baseurl }}/assets/img/manual/ooe_end_position.png)

Now we can switch back to state _B_ by sending the appropriate event to the state chart. This will trigger the following events:

- Since we leave _C_, the currently active state _C4_ will be exited and the `state_exited` signal will be emitted for this state. Then _C_ will be exited and the `state_exited` signal will be emitted for this state.
- We now enter _B_ again, and fire the `state_entered` signal on _B_. Since _B_ is a parallel state, it will activate its child states _B1_ and _B2_ again. This will emit the `state_entered` signal on _B1_ and _B2_.


You can also see this in action in the `order_of_events` example in the `godot_state_charts_examples` folder. The _History_ tab of the state chart debugger will show you the order in which the events are processed.

![History debugger in action]({{ site.baseurl }}/assets/img/manual/ooe_debugger.png)

You can also modify this example and explore the order of events yourself.
