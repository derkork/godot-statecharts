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


func serialize_child_states(child_states: Dictionary) -> Dictionary:
	var serialized_child_states := Dictionary()
	for child_state_name in child_states:
		serialized_child_states[child_state_name] = child_states[child_state_name]._export_to_dict()
	return serialized_child_states


# Export the saved state of this node as part of exporting the full state chart.
func _export_to_dict() -> Dictionary:
	var our_export_dict := {}
	if child_states.size() > 0:
		our_export_dict.child_states = serialize_child_states(child_states)
	else:
		our_export_dict.child_states = Dictionary()
	our_export_dict.pending_transition_name = String(pending_transition_name) if pending_transition_name != null else ""
	our_export_dict.pending_transition_remaining_delay = pending_transition_remaining_delay
	our_export_dict.pending_transition_initial_delay = pending_transition_initial_delay
	if history != null:
		our_export_dict.history = history._export_to_dict()
	else:
		our_export_dict.history = Dictionary()
	return our_export_dict
