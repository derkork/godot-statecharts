extends StaticBody2D

signal clicked(node)

@export var health:int = 3
@onready var _state_chart:StateChart = %StateChart
@onready var _label:Label = %Label
@onready  var _animation_player:AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	_label.text = str(health)


func _on_idle_state_entered() -> void:
	# When we enter idle state we play the idle animation
	_animation_player.play("Idle")

	
func _on_detection_area_body_entered(_body:Node) -> void:
	# When someone enters the area, reduce the health
	# and notify the state chart.
	health = max(0, health-1)
	_label.text = str(health)
	_state_chart.set_expression_property("health", health)
	_state_chart.send_event("health_changed")


func _on_blinking_state_entered() -> void:
	# when we enter blinking state, play the hit animation
	_animation_player.play("Hit")
	

func _on_dying_state_entered() -> void:
	# When we enter dying state, play the final death animation
	_animation_player.play("Break")

	
func _on_dead_state_entered() -> void:
	# When we enter dead state, we're done and can free the node.
	queue_free()


func _on_animation_player_animation_finished(_anim_name:String) -> void:
	# Forward animation_finished events to the state chart
	_state_chart.send_event("animation_finished")


# This is to make the box clickable. Clicking it will show it in the debugger.
func _on_input_event(_viewport:Node, event:InputEvent, _shape_idx:int) -> void:
	# if the left mouse button is up emit the clicked signal
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == false:
			clicked.emit(self)

