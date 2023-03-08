class_name AnimationTreeDebugger
extends Tree


## The animation tree to be debugged.
@export_node_path("AnimationTree") var animation_tree:NodePath

## The actual animation tree.
@onready var _animation_tree:AnimationTree = get_node(animation_tree)


func _process(delta):
	if not is_instance_valid(_animation_tree):
		push_warning("No animation tree is set up for tracking. Disabling debugger.")
		process_mode = Node.PROCESS_MODE_DISABLED

	clear()

	var root = create_item()
	hide_root = true

	var current_state_item := root.create_child()
	current_state_item.set_text(0, "State: %s" % _animation_tree.get("parameters/playback").get_current_node())

