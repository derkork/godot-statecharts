class_name Counter
extends Node

signal counter_modified(new_value:int)

## The current value of the counter.
@export var value:int = 0

## The state chart to which events should be sent. Can be left empty
## in which case no events will be sent.
@export_node_path("StateChart") var state_chart:NodePath

## Property under which the value of this counter should be
## registered in the state chart. If empty or null no property
## will be registered.
@export var state_chart_property:StringName = ""

## Event which should be sent to the state chart when the counter
## changes. If empty or null no event will be sent.
@export var event_on_change:StringName = ""


var _state_chart:StateChart = null

func _ready():
	_state_chart = get_node_or_null(state_chart)
	

func increase():
	value += 1
	_notify()
	
func decrease():
	value -= 1
	_notify()
	
	
func _notify():
	counter_modified.emit(value)
	
	if not is_instance_valid(_state_chart):
		return
		
	if state_chart_property != null and !state_chart_property.is_empty():
		_state_chart.set_expression_property(state_chart_property, value)
		
	if event_on_change != null and !event_on_change.is_empty():
		_state_chart.send_event(event_on_change)
	
