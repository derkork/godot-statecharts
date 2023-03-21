@tool
@icon("all_of_guard.svg")

## A composite guard that is satisfied when all of its guards are satisfied.
class_name AllOfGuard
extends Guard

## The guards that need to be satisified. When empty, returns true.
@export var guards:Array[Guard] = [] 

func is_satisfied(context_transition:Transition, context_state:State) -> bool:
	for guard in guards:
		if not guard.is_satisfied(context_transition, context_state):
			return false
	return true
