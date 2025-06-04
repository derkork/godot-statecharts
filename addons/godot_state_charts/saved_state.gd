## This represents the saved state of a state chart (or a part of it).
## It is used to save the state of a state chart to a file and to restore it later.
## It is also used in History states.
class_name SavedState
extends Resource

## The saved states of any active child states
## Key is the name of the child state, value is the SavedState of the child state
@export var child_states: Dictionary = {} 

## The path to the currently pending transition, if any
@export var pending_transition_name: NodePath

## The remaining time of the active transition, if any
@export var pending_transition_remaining_delay: float = 0

## The initial time of the active transition, if any
@export var pending_transition_initial_delay: float = 0

## History of the state, if this state is a history state, otherwise null
@export var history:SavedState = null


## Adds the given substate to this saved state
func add_substate(state:StateChartState, saved_state:SavedState):
	child_states[state.name] = saved_state

## Returns the saved state of the given substate, or null if it does not exist
func get_substate_or_null(state:StateChartState) -> SavedState:
	return child_states.get(state.name)


func export_child_states(child_states: Dictionary) -> Dictionary:
	var exported_child_states := Dictionary()
	for child_state_name in child_states:
		exported_child_states[child_state_name] = child_states[child_state_name]._export_to_resource()
	return exported_child_states


func debug_string() -> String:
	return """SavedState(
		child_states: %s
		pending_transition_name: %s
		pending_transition_remaining_delay: %s
		pending_transition_initial_delay: %s
		history: %s
	)""" % [
		JSON.stringify(child_states, "\t"),
		pending_transition_name,
		pending_transition_remaining_delay,
		pending_transition_initial_delay,
		history.debug_string() if history != null else "null"
	]
