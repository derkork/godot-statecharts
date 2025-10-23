@tool
@icon("history_state.svg")
class_name HistoryState
extends StateChartState

## Whether this state is a deep history state. A deep history state
## will remember all nested states, while a shallow history state will
## only remember the last active state of the parent state.
@export var deep:bool = false

## The default state to transition to if no history is available.
@export_node_path("StateChartState") var default_state:NodePath:
	set(value):
		default_state = value
		update_configuration_warnings()


## The stored history, if any.
var history:SavedState = null


func _state_save(_saved_state:SavedState, _child_levels:int = -1) -> void:
	# nothing to do here, as this is a pseude state. history is managed
	# by parent compound state.
	pass

func _state_restore(_saved_state:SavedState, _child_levels:int = -1) -> void:
	# nothing to do here, as this is a pseude state. history is managed
	# by parent compound state.
	pass


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()

	# a history state must be a child of a compound state otherwise it is useless
	var parent_state := get_parent()
	if not parent_state is CompoundState:
		warnings.append("A history state must be a child of a compound state.")

	# the default state must be a state
	var default_state_node := get_node_or_null(default_state)
	if not default_state_node is StateChartState:
		warnings.append("The default state is not set or is not a state.")
	else:
		# the default state must be a child of the parent state
		if not get_parent().is_ancestor_of(default_state_node):
			warnings.append("The default state must be a child of the parent state.")

	# a history state must not have any children
	if get_child_count() > 0:
		warnings.append("History states cannot have child nodes.")

	return warnings
