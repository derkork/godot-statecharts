@icon("state_chart.svg")
@tool
class_name StateChart 
extends Node

var _state:State = null

func _ready():
	if Engine.is_editor_hint():
		return 

	# check if we have exactly one child that is a state
	if get_child_count() != 1:
		push_error("StateChart must have exactly one child")
		return

	# check if the child is a state
	var child = get_child(0)
	if not child is State:
		push_error("StateMachine's child must be a State")
		return

	# initialize the state machine
	_state = child as State
	_state._state_init()

	# enter the state
	_state._state_enter()


func send_event(event:StringName):
	if not is_instance_valid(_state):
		push_error("StateMachine is not initialized")
		return

	_state._state_event(event)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if get_child_count() != 1:
		warnings.append("StateChart must have exactly one child")
	else:
		var child = get_child(0)
		if not child is State:
			warnings.append("StateChart's child must be a State")
	return warnings
