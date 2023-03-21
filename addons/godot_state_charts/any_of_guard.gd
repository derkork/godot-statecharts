@tool
@icon("any_of_guard.svg")

## A composite guard, that is satisfied if any of the guards are satisfied.
class_name AnyOfGuard
extends Guard

## The guards  of which at least one must be satisfied. If empty, this guard is not satisfied.
@export var guards: Array[Guard] = []

func is_satisfied(context_transition:Transition, context_state:State) -> bool:
	for guard in guards:
		if guard.is_satisfied(context_transition, context_state):
			return true
	return false
