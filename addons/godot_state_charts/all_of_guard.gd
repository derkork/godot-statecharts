@tool
@icon("all_of_guard.svg")

## A composite guard that is satisfied when all of its guards are satisfied.
class_name GDSAllOfGuard
extends GDSGuard

## The guards that need to be satisified. When empty, returns true.
@export var guards:Array[GDSGuard] = [] 

func is_satisfied(context_transition:GDSTransition, context_state:GDSState) -> bool:
	for guard in guards:
		if not guard.is_satisfied(context_transition, context_state):
			return false
	return true
