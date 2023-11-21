@tool
@icon("any_of_guard.svg")

## A composite guard, that is satisfied if any of the guards are satisfied.
class_name AnyOfGuard
extends GDSGuard

## The guards  of which at least one must be satisfied. If empty, this guard is not satisfied.
@export var guards: Array[GDSGuard] = []

func is_satisfied(context_transition:GDSTransition, context_state:GDSState) -> bool:
	for guard in guards:
		if guard.is_satisfied(context_transition, context_state):
			return true
	return false
