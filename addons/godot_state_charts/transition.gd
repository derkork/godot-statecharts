@tool
@icon("transition.svg")
class_name Transition
extends Node

const ExpressionUtil = preload("expression_util.gd")
const DebugUtil = preload("debug_util.gd")

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
## @deprecated use the new delay_in_seconds property instead
var delay_seconds:float = 0.0:
	set(value):
		delay_in_seconds = str(value)
	get:
		if delay_in_seconds.is_valid_float():
			return float(delay_in_seconds)
		return 0.0

## An expression for the delay in seconds before the transition is taken.
## This expression can use all expression properties of the state chart.
## If the expression does not evaluate to a valid float or a negative value, 
## the delay will be 0. When the delay is 0, the transition will be taken immediately.
## The transition will only be taken if the state is still active when the delay has 
## passed and has never been left. 
var delay_in_seconds:String = "0.0":
	set(value):
		delay_in_seconds = value
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

	var parent_state:Node = get_parent()
	if parent_state == null or not (parent_state is StateChartState):
		push_error("Transitions must be children of states.")
		return false	
		
	return guard.is_satisfied(self, get_parent())


## Evaluates the delay of this transition.
func evaluate_delay() -> float:
	# if the expression just is a single float, skip the evaluation and just 
	# return the float value. This is a performance optimization.
	if delay_in_seconds.is_valid_float():
		return float(delay_in_seconds)
	
	# evaluate the expression
	var parent_state:Node = get_parent()
	if parent_state == null or not (parent_state is StateChartState):
		push_error("Transitions must be children of states.")
		return 0.0

	var result = ExpressionUtil.evaluate_expression("delay of " + DebugUtil.path_of(self), parent_state._chart, delay_in_seconds, 0.0)	
	if typeof(result) != TYPE_FLOAT:
		push_error("Expression: ", delay_in_seconds ," result: ", result,  " is not a float. Returning 0.0.")
		return 0.0

	return result

## Resolves the target state and returns it. If the target state is not found,
## this function will return null.
func resolve_target() -> StateChartState:
	if to == null or to.is_empty():
		return null

	var result:Node = get_node_or_null(to) 
	if result is StateChartState:
		return result

	return null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings:Array = []
	if get_child_count() > 0:
		warnings.append("Transitions should not have children")

	if to == null or to.is_empty():
		warnings.append("The target state is not set")
	elif resolve_target() == null:
		warnings.append("The target state " + str(to) + " could not be found")

	if not (get_parent() is StateChartState):
		warnings.append("Transitions must be children of states.")
	
	return warnings

func _get_property_list() -> Array:
	var properties:Array = []
	properties.append({
		"name": "delay_in_seconds",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_EXPRESSION
	})
	
	# hide the old delay_seconds property
	properties.append({
		"name": "delay_seconds",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_NONE
	})

	return properties
