extends ProgressBar


@onready var the_frog = %TheFrog


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	value = the_frog.stamina
