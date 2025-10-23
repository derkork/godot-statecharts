# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.22.2] - 2025-10-23
## Fixed
- History states should no longer cause memory leaks ([#196](https://github.com/derkork/godot-statecharts/issues/196)). A big thanks goes to [7hells](https://github.com/7hells) who provided a PR with the fix.

## [0.22.1] - 2025-08-21
## Fixed
- When using an expression for the transition delay, and listening to the `transition_pending` signal you will now get the proper initial delay from that expression instead of a zero ([#190](https://github.com/derkork/godot-statecharts/issues/190)). 

## [0.22.0] - 2025-06-22
### Added
- It is now possible to save and restore a state chart's state using the new `StateChartSerializer` class. This can be useful for saving and loading games or in networked situations where the current state needs to be transferred  to a joining client. A huge thanks goes out to [Jeff Ammons](https://github.com/jammons) for digging into this rather complex topic and providing a [pull request](https://github.com/derkork/godot-statecharts/pull/183). 

### Fixed
- A few compiler warnings were resolved for the C# implementation. A big thanks goes to [Walter Geisler](https://github.com/Soren025) for providing a [pull request](https://github.com/derkork/godot-statecharts/pull/185) for this ([#184](https://github.com/derkork/godot-statecharts/issues/184))!

## [0.21.5] - 2025-04-05
### Improved
- The addon now ships with UID files for Godot 4.4 ([#178](https://github.com/derkork/godot-statecharts/issues/178)).
- The platformer example was improved as to not needlessly send events all the time which pollute the history log. A big thanks goes out to [mrezai](https://github.com/mrezai) for submitting a PR with this improvement ([#179](https://github.com/derkork/godot-statecharts/pull/179))


## [0.21.4] - 2025-03-28
### Improved
- Added in-editor error message when delay expression for transitions is empty. Also improved the error messages when an expression fails to parse or run. ([#174](https://github.com/derkork/godot-statecharts/issues/174)).

## [0.21.3] - 2025-02-12
### Fixed
- When transitioning into a child of a parallel state, other compound children of this parallel state will now properly enter their initial state ([#166](https://github.com/derkork/godot-statecharts/issues/166)).

## [0.21.2] - 2025-02-09
### Fixed
- The connection between state chart and the remote debugger is now properly shut down and reopened when a scene is reloaded with `change_scene_to_xxx` ([#165](https://github.com/derkork/godot-statecharts/issues/165)).

## [0.21.1] - 2025-02-06
### Fixed
- The state chart will no longer wrongly enter initial states of compound states under certain circumstances ([#164](https://github.com/derkork/godot-statecharts/issues/164)).
- Events sent on `state_enter` in parallel states are no longer ignored if the event was part of the state chart initialization sequence ([#143](https://github.com/derkork/godot-statecharts/issues/143)).

### Improved
- The automated test suite has received some improvements which help debugging issues faster in the future.

## [0.21.0] - 2025-01-31
### Breaking Change
- At long last, automatic transitions can now also track state changes. This way a _State Is Active_ guard can now be used in an automatic transition to run this transition whenever another state becomes active ([#114](https://github.com/derkork/godot-statecharts/issues/114)). Note that this was previously not possible, so projects which tried to emulate this behaviour using other means (e.g. continuously sending events) can now take advantage of this new behaviour and simplify their code and improve performance. Since the state chart now behaves differently than before, I'm marking this as a breaking change, though it should not affect most projects.

### Fixed
- When a transition was pending, another automatic transition could supersede it even if the pending transition had a higher priority. This has been fixed and a pending transition can only be superseded by a lower priority transition if the pending transitions trigger condition(s) are no longer met. 

## [0.20.0] - 2025-01-21
### Improved
- All nodes have received new icons which are more consistent with Godot's built-in icons and are easier to recognize at a glance. A huge thanks goes out to [Donatas Kirda](https://github.com/bloodwiing) who took the time to create these fantastic new icons and provided a PR with them ([#160](https://github.com/derkork/godot-statecharts/pull/160)).

## [0.19.0] - 2025-01-20
### Changed
- The _Animation Tree State_ and _Animation Player State_ nodes are now deprecated and should not be used in new projects anymore. The nodes will now display a warning in the tree and have been removed from the _Quick Add_ sidebar. They will be fully removed in a future release.

## [0.18.0] - 2024-12-07
### Added
- It is now possible to manually trigger transitions using the new `take` method on the transition. This can be useful if you want to directly trigger a transition from code rather than sending events. A big thanks goes out to [Mehmet Sahin](https://github.com/mixemer) for suggesting this feature and providing a PR for it ([#152](https://github.com/derkork/godot-statecharts/issues/152)).

## [0.17.1] - 2024-11-04
### Added
- The state chart will now issue a warning in debug builds when trying to send an event that is not defined in any transition of the state chart. This can help to catch typos in event names early on ([#150](https://github.com/derkork/godot-statecharts/issues/150)). This warning is now enabled by default but can be disabled per state chart in state chart settings.  

## [0.17.0] - 2024-08-16
### Added
- The C# wrappers now provide type-safe events for all signals that the underlying nodes emit. This way you can simply subscribe to a signal using the familiar `+=` notation, e.g. `stateChart.StateEntered += OnStateEntered`. This makes it easier to work with the state chart from C# code. A big thanks goes out to [Marques Lévy](https://github.com/Prakkkmak) for suggesting this feature and providing a POC PR for it ([#126](https://github.com/derkork/godot-statecharts/pull/126)). Note that the usual rules for signals in C# apply, e.g. signal connections will not automatically be disconnected when the receiver is freed. 

### Fixed
- The library now handles cases better where code tries to access a state chart that has been removed from the tree. This may happen when using Godot's `change_scene_to_file` or `change_scene_to_packed` functions. Debug output in these cases will no longer try to get full path names of nodes that have been removed from the tree. This should prevent errors and crashes in these cases ([#129](https://github.com/derkork/godot-statecharts/issues/129)).
- The error messages for evaluating expressions have been improved. They now show the expression that was evaluated and the result of the evaluation ([#138](https://github.com/derkork/godot-statecharts/issues/138)) 
- Compound state should no longer show a warning for overriding `add_child`. A big thanks goes out to [yesfish](https://github.com/huwpascoe) for finding this and providing a fix ([#128](https://github.com/derkork/godot-statecharts/issues/128)).
- The editor side bar can now be made smaller than before which can be useful when working on smaller screens ([#127](https://github.com/derkork/godot-statecharts/issues/127)).

## [0.16.0] - 2024-06-06 
### Added
- The delay for a transition can now be an expression rather than just a float value. This allows for more dynamic transitions. For example the delay can now be a random value (using `randf_range()`) or any expression property. Of course you can still just use a single float number.  This change is backwards-compatible, all existing state charts will automatically be converted to the new format when loaded. There is a new example named `random_transitions` which shows this new feature to create a randomly wandering mob. A big thanks goes out to [Miguel Silva](https://github.com/mrjshzk) and [alextkd2003](https://github.com/alextkd2003) for providing POC PRs for this feature.
- It is now possible to read expression properties back from the state chart. This is useful for debugging or for avoiding holding the same value in multiple places ([#110](https://github.com/derkork/godot-statecharts/issues/110)).
- It is now possible to set initial values for expression properties in the state chart. This avoids getting errors when using expressions in transitions that run immediately after the state chart is started and the expression property has not been set yet. This is again backwards-compatible, all existing state charts will automatically start with an empty dictionary of expression properties.

### Improved
- The state chart debugger in the editor now automatically selects the first state chart when the game starts. This reduces the amount of clicking needed to start debugging a state chart ([#118](https://github.com/derkork/godot-statecharts/issues/118)).
- The state chart will now detect infinite transition loops that would cause the game to freeze (>100 transitions within a single frame). When such a loop is detected, the state chart will print an error message and stop processing transitions. After that, the state chart is in an undefined state and will no longer work properly. This has been added for easier debugging of freezes. Note that this will not catch infinite loops that involve delayed transitions as such loops will not freeze the game and may actually be desired ([#116](https://github.com/derkork/godot-statecharts/issues/116)).
- The constructor of the `StateChart` wrapper class for C# is now protected to allow for easier subclassing ([#119](https://github.com/derkork/godot-statecharts/issues/119)).
- There are now some automated tests to ensure that changes to the library will not break existing functionality. This should help to prevent regressions in the future.

### Fixed
- The history log in the state chart debugger in the editor now only updates when there were actually changes. This will increase performance and prevent the log from becoming un-scrollable.
- Expression guards will no longer print the error message twice if the expression is not valid.

## [0.15.2] - 2024-04-17
### Fixed
- Using a history state as initial state of a compound state will no longer leave the compound state stuck at the history state.
- When having multiple automatic transitions with a delay in a state the first matching transition will be taken. Before, if all automatic transitions had a delay, the last matching transition was taken which was different from the documented behavior.

## [0.15.1] - 2024-04-02
### Improved
- The C# wrappers for the state chart nodes now have a `CallDeferred` function and a new `MethodNames` enum which contains the names of all methods that can be called on a state chart node. This makes it easier to call methods on a state chart node from C# code (e.g. `		_stateChart.CallDeferred(StateChart.MethodName.SendEvent, "player_entered")
  ` ([#101](https://github.com/derkork/godot-statecharts/issues/101)).

### Fixed
- Compound states will now properly handle some edge cases that occur when a transition is immediately leaving them once they are entered. This will prevent multiple child states of compound states from being active at the same time or child states being entered but never exited even though the compound state is left ([#100](https://github.com/derkork/godot-statecharts/issues/100)).


## [0.15.0] - 2024-03-25
### Breaking change
- The class `State` has been renamed to `StateChartState` to avoid conflicts with other libraries that might also have a class or enum named `State`. If you have code that uses the `State` class, you will need to update it to use `StateChartState` instead. This change also affects C# projects as the class name has changed there as well even though C# has namespaces to avoid conflicts ([#97](https://github.com/derkork/godot-statecharts/issues/97)). Scenes should remain unaffected by this change.

### Improved
- The state chart debugger icon is now having the same color as other UI node icons in the editor to reflect that it is a UI node. A big thanks goes out to [mieldepoche](https://github.com/mieldepoche) for suggesting this improvement and providing the icon ([#94](https://github.com/derkork/godot-statecharts/issues/94)).

### Fixed
- The event popup in the transition editor should now appear at the correct position when using multiple monitors ([#86](https://github.com/derkork/godot-statecharts/issues/86)). A big thanks goes out to [cyber-mantis](https://github.com/cyber-mantis) for providing a fix for this issue.
- Fixed a typo in the error message that was showing for a compound state with only one child state ([#96](https://github.com/derkork/godot-statecharts/issues/96)).

## [0.14.0] - 2024-02-26
### Breaking Change
- The handling of `set_expression_property` has changed such that expression property changes are immediately visible to guards after the call to `set_expression_property` even if `set_expression_property` is called while a transition is currently in progress. For more details check out the discussion on [#82](https://github.com/derkork/godot-statecharts/issues/82). If you relied on the old behaviour, you can call `set_expression_property` deferred, to make the change visible only after the current transition is fully processed.

## [0.13.2] - 2024-02-25
### Fixed
- The icons introduced in the last release seem to significantly slow down the rendering in the state chart debugger. They have been replaced with ASCII text labels as this problem can only be fixed at engine level ([#84](https://github.com/derkork/godot-statecharts/issues/84)).

## [0.13.1] - 2024-02-23
### Fixed
- The state chart now issues a better error message when being called while not yet ready ([#81](https://github.com/derkork/godot-statecharts/issues/81)).
- The state chart now properly handles property changes which happen during state or transition callbacks. These will be queued after the current event or property change is fully processed. This way consistency is maintained and reactions to an event or property change will not see intermediate property changes during their execution ([#82](https://github.com/derkork/godot-statecharts/issues/82)). A big thanks goes to [Matt Idzik](https://github.com/MidZik) who supplied a PR that helped implementing this fix.

### Improved
- The history in the state chart debugger now uses little icons to show the type history entry. This makes it easier to see what happened at a glance. A big thanks goes out to [Alireza Zamani](https://github.com/alitnk) for suggesting this improvement.

## [0.13.0] - 2024-01-30
### Breaking Change
- You can now have fully automatic transitions ([#71](https://github.com/derkork/godot-statecharts/issues/71)). An automatic transition has no event and will be executed when the state is entered, any event is sent or any expression property is modified. Note that a state must be active for its automatic transitions to be considered. 

  This change can potentially break existing state charts which have transitions with no event. Before this change, these transitions were only executed when the state was entered. After this change, there are more situations in which these transitions can be executed, so you might have to add additional guards to your transitions or use the `state_entered` signal to trigger your logic. 

### Added
- A new demo was added to show how to use automatic transitions. It is located at `godot_state_charts_examples/automatic_transitions`.

### Improved
- Compound and parallel states will now show a warning when they have less than two child states.

### Fixed
- The editor debugger should no longer cause compile errors when the game is exported. These errors were actually harmless but would give the impression that something is broken ([#74](https://github.com/derkork/godot-statecharts/issues/74)).
- The debugger remote now properly handles the case when a state chart leaves the tree and un-registers itself from the in-editor debugger properly instead of printing out errors.
- Parallel states now properly ignore non-state children when calculating their child state count.

## [0.12.0] - 2024-01-12
### Added
- The inspector for transitions now provides a list of all events currently used in the state chart from which an event can be selected. This minimizes the risk of typos when entering event names ([#72](https://github.com/derkork/godot-statecharts/issues/72)).
- Events can now be renamed in the inspector. This will rename all occurrences of the event in the state chart. This can help for larger state charts where an event is used in multiple locations and finding and renaming all occurrences is cumbersome and error-prone. Note that this will not change the name of the event in your code. ([#72](https://github.com/derkork/godot-statecharts/issues/72)).

## [0.11.1] - 2023-12-22
### Fixed
- The state chart now sends an `event_received` with the correct event name, when an event is sent to it while another event is still being processed ([#64](https://github.com/derkork/godot-statecharts/issues/64)).

## [0.11.0] - 2023-12-14
### Added
- When adding the first child state to a compound state in the editor, this will now automatically be set as the initial state of the compound state. A big thanks goes out to [Roger](https://github.com/RogerRandomDev) for submitting a PR with this feature.

### Fixed
- Some of the node warnings have been clarified to make it easier to understand what is going on.
- Some fringe errors that may happen when you add unrelated nodes below state or transition nodes have been addressed.


## [0.10.0] - 2023-12-13
### Added
- **Preview**: In-editor state chart debugger ([#48](https://github.com/derkork/godot-statecharts/issues/48)). The state chart debugger is now also available in the editor itself. When you start a game the debugger will show all marked state charts and you can inspect them from the editor. This is useful for quickly debugging multiple state charts while playing the game without having UI obstructing the game view. Please give it a try and report any issues you find.

- The demos are all opted-in to the new in-editor debugger so you can try it out right away.

### Removed
- The internal `_before_transition` on the `StateChart` class has been removed. It was used only by the state chart debugger which has received some internal re-writes and no longer needs this. As this was an internal signal, this change should not affect any user code. If your code used this signal, you can now use the `taken` signal on any transition to know when a certain transition was taken.

### Fixed
- Some code that should not run in the editor was actually running in the editor. This has been fixed. The change should not affect any user code but fixes a few stray warnings that occasionally popped up in the editor.


## [0.9.1] - 2023-11-27
### Fixed
- Added missing import `Transition.cs`.

## [0.9.0] - 2023-11-26
### Added
- Transitions now provide a `taken` signal which is called when the transition is taken. This is useful for running side effects only when a specific transition is taken, e.g. play a specific sound or animation ([#58](https://github.com/derkork/godot-statecharts/issues/58)). 


## [0.8.0] - 2023-10-29
### Added
- A new set of wrapper classes were added to make it easier to use state charts in C#. The new classes are located in `addons/godot-statecharts/csharp`. A new demo was added to show how to use the new classes. It is located at `godot_state_charts_examples/csharp`. ([#50](https://github.com/derkork/godot-statecharts/issues/50)). Please note that the new API is currently experimental and might change in the future, depending on feedback from the community.


## [0.7.1] - 2023-10-08
### Fixed
- Corrected version number in plugin settings.

## [0.7.0] - 2023-10-07
### Added
- States now have a new `transition_pending` signal which is emitted every frame while a delayed transition is pending. The signal includes the original delay of the transition and the remaining time until it will be triggered. This is useful for driving progress bars or cooldown indicators. A new demo was added to show how this works. It is located at `godot_state_charts_examples/cooldown` ([#46](https://github.com/derkork/godot-statecharts/issues/46)). 



## [0.6.0] - 2023-10-06
### Added
- You can now move the sidebar for quickly adding new states to the other side of the editor. This is useful if you have your node tree on the right side of the editor. The location will be saved with the editor layout ([#47](https://github.com/derkork/godot-statecharts/issues/47)).


## [0.5.0] - 2023-09-27
### Added
- Compound states now have two additional signals `child_state_entered` and `child_state_exited` which allow running common code that should run whenever a child state of the compound state is entered or exited. This is for example useful for resetting some internal state. A big thanks goes out to [Ian Sly](https://github.com/uzkbwza) for sending a PR with this feature.
- You can now use the new stepping mode to run code depending on the currently active states in a turn-based game. A new demo was added to show how this works. It is located at `godot_state_charts_examples/stepping`. There is also a section explaining this mode in the [documentation](manual/manual.md#stepping-mode). Another big thanks goes out to [Ian Sly](https://github.com/uzkbwza) for sending a PR with this feature.

### Fixed
- In the platformer demo the player now keeps its orientation (left or right) when standing still. Before it would always face right when standing still. In addition the handling of animations was greatly simplified. A big thanks goes out to [Renato Rotenberg](https://github.com/Brawmario) for sending a PR and giving some great advice on how to improve the handling of animations in the platformer demo.



## [0.4.5] - 2023-09-13
### Fixed
- Fixed double jump animation in platformer demo looping endlessly in Godot 4.1 ([#33](https://github.com/derkork/godot-statecharts/issues/33)).

## [0.4.4] - 2023-09-10
### Fixed
- Fixed the ant hill demo which was broken in the last release ([#31](https://github.com/derkork/godot-statecharts/issues/31)).


## [0.4.3] - 2023-09-05
### Fixed
- The state chart now waits for the next frame after being ready to enter its initial state. This allows all nodes which are above the statechart in the three to finish their `_ready` phase and properly initialize before the state chart starts running ([#28](https://github.com/derkork/godot-statecharts/issues/28)).

## [0.4.2] - 2023-08-22
### Fixed
- The state chart debugger now again properly recognizes the "Maximum Lines" setting ([#26](https://github.com/derkork/godot-statecharts/issues/26)).


## [0.4.1] - 2023-08-21
### Fixed
- The state chart debugger's performance has been vastly improved, so it should no longer affect the framerate. The history field is now only updated twice a second rather than every frame and only when it is actually visible. Also history is now held in a ring buffer which helps to speedily add and overwrite history entries as well as keeping memory usage in check ([#24](https://github.com/derkork/godot-statecharts/issues/24)).

### Added
- You can now filter out information from the state chart debugger. For now you can ignore events, state changes and transitions. These settings can also be changed at runtime, so you can filter out information that is not relevant for the current situation.

### Removed
- The _Auto Track State Changes_ setting has been removed from the state charts debugger, as its functionality was made obsolete by the new filter settings.


## [0.4.0] - 2023-08-17
### Breaking changes

- State changes by transitions with zero delay are now always happening in the same frame in which they were triggered. Before, state changes were delayed until the next frame. Because this could significantly delay complex state chains, this behavior was changed ([#21](https://github.com/derkork/godot-statecharts/issues/21)). Since this necessitated some other internal changes as well, there is no option to restore the old behaviour without introducing a lot of internal complexity. If for some reason you really need to delay a state change by one frame, you can use a transition with a very short delay (e.g. 0.0001 seconds).

### Added
- A new demo was added for showing the exact flow of events when changing states. It is located at `godot_state_charts_examples/order_of_events`. A section explaining this demo was added to the [documentation](manual/manual.md#order-of-events).

### Improved
- The state chart debugger now shows the frame number instead of the time when a change happened. This makes it easier to see the exact timing of events.
It also now shows an entry when the state chart receives an event and when a transition is about to be triggered.

### Fixed
- In the ant hill demo the ants now try to take a random direction when they cannot reach their target. This prevents them from getting stuck in corners or edges.


## [0.3.1] - 2023-05-03
### Fixed
- The _Animation Name_ property of the _Animation Player State_ is now heeded ([#15](https://github.com/derkork/godot-statecharts/issues/15)).
- All icons are now 16x16 pixels in size like the built-in Godot icons. ([#12](https://github.com/derkork/godot-statecharts/issues/12))
- The version number is now correctly displayed in the editor.
- In the ant hill demo ants no longer collide with each other, which caused them to get stuck on each other.


## [0.3.0] - 2023-05-02
### Added
- A new _Animation Player State_ is now available. It works similar to the _Animation Tree State_ but controls an animation player instead of an animation tree. With this you can trigger animations when entering a certain state. A huge thanks goes out to [Junji Takakura](https://github.com/jtakakura) for contributing this feature. The platformer demo has been updated to use this new state for the new destructible iron crates.

### Improved
- The _Animation Tree State_ now has a new property which allows to specify the name of the state in the animation tree that should be triggered. Previously the name of the state in the state chart and in the animation tree state machine had to match exactly which was not very flexible. The new field is optional, so if you don't specify a name, the state chart will still try to find a state in the animation tree with the same name as the state in the state chart. As such this change is also backwards compatible.

### Fixed
- The state chart debugger will no longer crash when a new node is debugged and the previously debugged node was destroyed in the meantime.


## [0.2.1] - 2023-04-20
### Fixed

- Selecting a state chart node that cannot accept child nodes no longer throws an error ([#9](https://github.com/derkork/godot-statecharts/issues/9)).

## [0.2.0] - 2023-04-19
### Added
- A new UI for quickly adding states and transitions is now available. A huge thanks goes out to [Folta](https://github.com/folt-a) for contributing the first implementation of this feature. The UI is automatically visible when you select a state chart node in the scene tree. 
- The state nodes now also provide callbacks for `_input` and `_unhandled_input`. This allows to handle input depending on the current state ([#4](https://github.com/derkork/godot-statecharts/issues/4)). 

### Improved
- States which do not have anything connected to their `state_process` and `state_physics_process` signals are now no longer running every frame. Likewise, states which have not connected anything to their `state_input` or `state_unhandled_input` signals will not try to receive input. This should significantly improve performance when using a lot of state charts in a game. This way a state which only connects enter and exit states has virtually no runtime cost at all. Running delayed transitions is still possible, in this case the state chart will run every frame until the transition is triggered or the state is exited prematurely. The signal connections will be checked when the state is enabled, so technically you can connect and disconnect state signals at runtime, though this is not recommended as it can lead to confusing behavior.

### Fixed
- The state chart debugger now only shows the 300 last lines of history in the log. This should prevent the debugger from slowing down the editor when the state machine is used for a long time ([#5](https://github.com/derkork/godot-statecharts/issues/5)).
- Some icons are no longer blurry.


## [0.1.1] - 2023-04-12
### Fixed
- Transitioning from a child to a parent state should no longer throw an error when the parent is the root node ([#3](https://github.com/derkork/godot-statecharts/issues/3)).
- Transitioning from a child to a parent compound / parallel state now properly counts as [self transition](https://statecharts.dev/glossary/self-transition.html), so that the parent node is exited and re-entered.


## [0.1.0] - 2023-04-06
### Breaking changes
- The state chart debugger now is no longer a single node  but a full scene. This allows to have more complex UI in the debugger. Please replace the old debugger node with the new scene which is located at `addons/godot-statecharts/utilities/state_chart_debugger.tscn`. The debugger will no longer appear in the node list. You can quickly add it using the "Instatiate child scene" button in the scene inspector.

### Improved 
- The state charts debugger now can collect history of state changes, which helps understanding the state machine behavior and debugging it.

### Fixed
- When transitioning directly to a state nested below a compound state, the initial state of the compound state will no longer be entered and immediately exited again ([#1](https://github.com/derkork/godot-statecharts/issues/1)).


## [0.0.2] - 2023-03-31
### Fixed
- Moved theme file which is used by the demo projects to the correct location.

## [0.0.1] - 2023-03-30
- Initial release.
