# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


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
