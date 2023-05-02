extends StaticBody2D

signal clicked(node)

@export var health:int = 3
@onready var _state_chart:StateChart = $StateChart
@onready var _label:Label = $Label

func _ready():
	_label.text = str(health)


func _on_idle_event_received(event):
	if event == "player_entered":
		health = max(0, health-1)
		_label.text = str(health)
		_state_chart.set_expression_property("health", health)
		_state_chart.send_event("health_changed")


func _on_break_animation_event_received(event):
	if event == "animation_finished":
		# the break animation is finished, we can now destroy ourselves.
		queue_free()


func _on_input_event(_viewport, event, _shape_idx):
	# if the left mouse button is up emit the clicked signal
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == false:
			clicked.emit(self)


func _on_animation_player_animation_finished(_anim_name):
	# pass the animation finished event to the state chart
	# so it can switch to the proper state
	_state_chart.send_event("animation_finished")


func _on_detection_area_body_entered(_body):
	# When someone enters the area, notify the state 
	# chart.
	_state_chart.send_event("player_entered")
