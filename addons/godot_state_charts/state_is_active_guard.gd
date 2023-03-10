## A guard that checks if a certain state is active.
class_name StateIsActiveGuard
extends Guard

## The state to be checked. When null this guard will return false.
@export_node_path("State") var state: NodePath

func is_satisfied(context_transition:Transition, context_state:State) -> bool:
	## resolve the state, relative to the transition
	var actual_state = context_transition.get_node_or_null(state)
	
	if actual_state == null:
		return false
	return actual_state.active
