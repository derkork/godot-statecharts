extends ProgressBar


@onready var the_frog:Node = %TheFrog


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta:float) -> void:
	value = the_frog.stamina
