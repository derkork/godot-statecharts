extends Node


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_SPACE:
		get_tree().paused = not get_tree().paused
		print("Paused ", get_tree().paused)
