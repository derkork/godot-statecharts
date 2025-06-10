class_name SerializedColorBox extends Resource

@export var box_id: String = ""
@export var color: Color = Color.GHOST_WHITE
@export var time_in_state: float = 0.0


func debug_string() -> String:
	return """SerializedColorBox(
		box_id: %s
		color: %s
		time_in_state: %s
	)""" % [box_id, color, time_in_state]
