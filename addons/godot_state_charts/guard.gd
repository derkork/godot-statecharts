class_name Guard
extends Resource

## Returns true if the guard is satisfied, false otherwise.
func is_satisfied(context_transition:Transition, context_state:StateChartState) -> bool:
	push_error("Guard.is_satisfied() is not implemented. Did you forget to override it?")
	return false
