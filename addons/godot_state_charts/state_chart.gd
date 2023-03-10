@icon("state_chart.svg")
@tool
## This is statechart. It contains a root state (commonly a compound or parallel state) and is the entry point for 
## the state machine.
class_name StateChart 
extends Node

## The root state of the state chart.
var _state:State = null

## This dictonary contains known properties used in expression guards. Use the 
## [method set_expression_property] to add properties to this dictionary.
var _expression_properties:Dictionary = {
}


func _ready() -> void:
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

## Sends an event to this state chart. The event will be passed to the innermost active state first and
## is then moving up in the tree until it is consumed. Events will trigger transitions and actions via emitted
## signals.	
func send_event(event:StringName) -> void:
	if not is_instance_valid(_state):
		push_error("StateMachine is not initialized")
		return

	_state._state_event(event)

## Sets a property that can be used in expression guards. The property will be available as a global variable
## with the same name. E.g. if you set the property "foo" to 42, you can use the expression "foo == 42" in
## an expression guard.
func set_expression_property(name:StringName, value) -> void:
	_expression_properties[name] = value


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if get_child_count() != 1:
		warnings.append("StateChart must have exactly one child")
	else:
		var child = get_child(0)
		if not child is State:
			warnings.append("StateChart's child must be a State")
	return warnings
