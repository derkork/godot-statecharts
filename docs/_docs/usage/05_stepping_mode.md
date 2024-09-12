---
layout: page
title: Stepping Mode
permalink: /usage/stepping-mode
description: "Here you can find instructions about how to use the stepping mode."
---

# {{ page.title }}

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
