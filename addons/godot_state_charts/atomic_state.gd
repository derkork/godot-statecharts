@tool
@icon("atomic_state.svg")
## This is a state that has no sub-states.
class_name AtomicState
extends State




func _get_configuration_warnings() -> PackedStringArray :
	var warnings = super._get_configuration_warnings()
	# check if we have any child nodes which are not transitions
	for child in get_children():
		if child is State:
			warnings.append("Atomic states cannot have child states. These will be ignored.")
			break
	return warnings
