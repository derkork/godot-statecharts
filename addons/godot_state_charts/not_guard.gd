@tool
@icon("not_guard.svg")
## A guard which is satisfied when the given guard is not satisfied.
class_name GDSNotGuard
extends GDSGuard

## The guard that should not be satisfied. When null, this guard is always satisfied.
@export var guard: GDSGuard

func is_satisfied(context_transition:GDSTransition, context_state:GDSState) -> bool:
	if guard == null:
		return true
	return not guard.is_satisfied(context_transition, context_state)
