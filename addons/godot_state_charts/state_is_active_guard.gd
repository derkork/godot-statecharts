## A guard that checks if a certain state is active.
class_name StateIsActiveGuard
extends Guard

## The state to be checked. When null this guard will return false.
@export var state: State

func is_satisfied() -> bool:
	if state == null:
		return false
	return state.active
