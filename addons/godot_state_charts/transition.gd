@tool
@icon("transition.svg")
class_name Transition
extends Node

## Fired when this transition is taken. For delayed transitions, this signal
## will be fired when the transition is actually executed (e.g. when its delay
## has elapsed and the transition has not been arborted before). The signal will
## always be fired before the state is exited.
signal taken()

## The target state to which the transition should switch
@export_node_path("StateChartState") var to:NodePath:
	set(value):
		to = value
		update_configuration_warnings()

## The event that should trigger this transition, can be empty in which case
## the transition will immediately be tried when the state is entered
@export var event:StringName = "":
	set(value):
		event = value
		update_configuration_warnings()

## An expression that must evaluate to true for the transition to be taken. Can be
## empty in which case the transition will always be taken
@export var guard:Guard:
	set(value):
		guard = value
		update_configuration_warnings()

## A delay in seconds before the transition is taken. Can be 0 in which case
## the transition will be taken immediately. The transition will only be taken
## if the state is still active when the delay has passed and has never been left.
@export var delay_seconds:float = 0.0:
	set(value):
		delay_seconds = value
		update_configuration_warnings()


## Read-only property that returns true if the transition has an event specified.
var has_event:bool:
	get:
		return event != null and event.length() > 0

## Evaluates the guard expression and returns true if the transition should be taken.
## If no guard expression is specified, this function will always return true.
func evaluate_guard() -> bool:
	if guard == null: 
		return true

	var parent_state = get_parent()
	if parent_state == null or not (parent_state is StateChartState):
		push_error("Transitions must be children of states.")
		return false	
		
	return guard.is_satisfied(self, get_parent())

## Resolves the target state and returns it. If the target state is not found,
## this function will return null.
func resolve_target() -> StateChartState:
	if to == null or to.is_empty():
		return null

	var result = get_node_or_null(to) 
	if result is StateChartState:
		return result

	return null


func _get_configuration_warnings():
	var warnings = []
	if get_child_count() > 0:
		warnings.append("Transitions should not have children")

	if to == null or to.is_empty():
		warnings.append("The target state is not set")
	elif resolve_target() == null:
		warnings.append("The target state " + str(to) + " could not be found")

	if not (get_parent() is StateChartState):
		warnings.append("Transitions must be children of states.")
	
	return warnings

