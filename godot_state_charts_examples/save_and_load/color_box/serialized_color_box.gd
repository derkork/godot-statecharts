class_name SerializedColorBox extends Resource

@export var box_id: String = ""
@export var color_index: int = 0
@export var time_in_state: float = 0.0


func _to_string() -> String:
	return """SerializedColorBox(
		box_id: %s
		color_index: %s
		time_in_state: %s
	)""" % [box_id, color_index, time_in_state]
