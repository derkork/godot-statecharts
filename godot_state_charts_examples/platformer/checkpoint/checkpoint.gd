extends Node2D

## emitted when this checkpoint is clicked with the mouse
signal clicked(checkpoint:Node2D)

## emitted when this checkpoint is activated
signal activated(checkpoint:Node2D)

## emitted when this checkpoint is deactivated
signal deactivated(checkpoint:Node2D)

@onready var _state_chart:StateChart = get_node("StateChart")


func _on_area_2d_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	# if event was left mouse button up, emit clicked signal
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == false:
		# print("Checkpoint clicked")
		clicked.emit(self)


func _on_area_2d_body_entered(body:Node2D):
	if body.is_in_group("player"):
		_state_chart.send_event("player_entered")


func _on_area_2d_body_exited(body:Node2D):
	if body.is_in_group("player"):
		_state_chart.send_event("player_exited")
		
		
func emit_activated():
	activated.emit(self)
	
func emit_deactivated():
	deactivated.emit(self)
