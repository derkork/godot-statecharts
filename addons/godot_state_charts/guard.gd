class_name GDSGuard
extends Resource

## Returns true if the guard is satisfied, false otherwise.
func is_satisfied(context_transition:GDSTransition, context_state:GDSState) -> bool:
	push_error("GDSGuard.is_satisfied() is not implemented. Did you forget to override it?")
	return false
