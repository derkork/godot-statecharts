class_name StateChartDebugger
extends Tree

## The state chart that should be debugged.
@export_node_path("StateChart") var state_chart:NodePath

## Whether or not the debugger is enabled.
@export var enabled:bool = true:
	set(value):
		enabled = value
		process_mode = Node.PROCESS_MODE_ALWAYS if enabled else Node.PROCESS_MODE_DISABLED
		visible = enabled

# the state chart we track
@onready var _state_chart:StateChart = get_node_or_null(state_chart)

func _init():
	scroll_horizontal_enabled = false
	scroll_vertical_enabled = false


func _process(delta):
	if not is_instance_valid(_state_chart):
		push_warning("No state chart set up for tracking. Disabling debugger.")
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	# Clear contents
	clear()
	var root = create_item()
	root.set_text(0, "States")

	# walk over the state chart and find all active states
	_collect_active_states(_state_chart, root )
	

func _collect_active_states(root:Node, parent:TreeItem):
	for child in root.get_children():
		if child is State:
			if child.active:
				var state_item = create_item(parent)
				state_item.set_text(0, child.name)
				_collect_active_states(child, state_item)
		
	
