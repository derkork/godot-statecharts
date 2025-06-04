# This class is used to serialize a saved state to a resource. It is intended 
# to make it easier to save and load state charts, as well as to transfer them
# over the network if needed. See also SerializedStateChart.
class_name SerializedSavedState
extends Resource

@export var child_states: Dictionary = {}
@export var pending_transition_name: NodePath = NodePath("")
@export var pending_transition_remaining_delay: float = 0.0
@export var pending_transition_initial_delay: float = 0.0
@export var history: SerializedSavedState = null


func debug_string() -> String:
	return """SerializedSavedState(
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
