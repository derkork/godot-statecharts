class_name StateChartDebugger
extends Tree

## Whether or not the debugger is enabled.
@export var enabled:bool = true:
	set(value):
		enabled = value
		if not Engine.is_editor_hint():
			_setup_processing(enabled)

# the state chart we track
var _state_chart:StateChart
var _root:Node

func _init():
	scroll_horizontal_enabled = false
	scroll_vertical_enabled = false

## Sets up the debugger to track the given state chart. If the given node is not 
## a state chart, it will search the children for a state chart. If no state chart
## is found, the debugger will be disabled.
func debug_node(root:Node) -> bool:
	# if we are not enabled, we do nothing
	if not enabled:
		return false
	
	_root = root
	var success = _debug_node(root)

	# if we have no success, we disable the debugger
	if not success:
		push_warning("No state chart found. Disabling debugger.")
		_setup_processing(false)
		_state_chart = null
	else:
		_setup_processing(true)

	return success


func _debug_node(root:Node) -> bool:
	# if we have no root, we use the scene root
	if not is_instance_valid(root):
		return false

	if root is StateChart:
		_state_chart = root
		return true

	# no luck, search the children
	for child in root.get_children():
		if _debug_node(child):
			# found one, return			
			return true

	# no luck, return false
	return false


func _setup_processing(enabled:bool):
	process_mode = Node.PROCESS_MODE_ALWAYS if enabled else Node.PROCESS_MODE_DISABLED
	visible = enabled


func _process(delta):
	# Clear contents
	clear()

	if not is_instance_valid(_state_chart):
		return

	var root = create_item()
	root.set_text(0, _root.name)

	# walk over the state chart and find all active states
	_collect_active_states(_state_chart, root )
	
	# also show the values of all variables
	var items = _state_chart._expression_properties.keys()
	
	if items.size() <= 0:
		return # nothing to show
	
	# sort by name so it doesn't flicker all the time
	items.sort()
	
	var properties_root = root.create_child()
	properties_root.set_text(0, "< Expression properties >")
	
	for item in items:
		var value = str(_state_chart._expression_properties.get(item))
		
		var property_line = properties_root.create_child()
		property_line.set_text(0, "%s = %s" % [item, value])
	
	
	
	
	
	

func _collect_active_states(root:Node, parent:TreeItem):
	for child in root.get_children():
		if child is State:
			if child.active:
				var state_item = create_item(parent)
				state_item.set_text(0, child.name)

				if is_instance_valid(child._pending_transition):
					var transition_item = state_item.create_child()
					transition_item.set_text(0, ">> %s (%.2f)" % [child._pending_transition.name, child._pending_transition_time])

				_collect_active_states(child, state_item)
		
	
