class_name Sensor
extends Node

## The state chart that should be notified
@export_node_path("StateChart") var state_chart:NodePath

# the state chart we track
@onready var _state_chart:StateChart = get_node_or_null(state_chart)

func send_event(event:StringName):
	if is_instance_valid(_state_chart):
		_state_chart.send_event(event)
	else:
		push_error("No state chart is set, cannot send event: " + event)