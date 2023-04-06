extends Node

@onready var state_chart:StateChart = $StateChart

func _on_area_2d_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# on release send clicked event to state chart
			if not event.is_pressed():
				state_chart.send_event("clicked")
	
