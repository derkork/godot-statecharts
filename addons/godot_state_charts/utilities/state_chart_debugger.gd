@icon("state_chart_debugger.svg")
extends Control

## Whether or not the debugger is enabled.
@export var enabled:bool = true:
	set(value):
		enabled = value
		if not Engine.is_editor_hint():
			_setup_processing(enabled)

## Whether or not the debugger should automatically track state changes.
@export var auto_track_state_changes:bool = true

## The list of collected events.
var _events:Array[Dictionary] = []

## The initial node that should be watched. Optional, if not set
## then no node will be watched. You can set the node that should
## be watched at runtime by calling debug_node().
@export var initial_node_to_watch:NodePath

## The tree that shows the state chart.
@onready var _tree:Tree = %Tree
## The text field with the history.
@onready var _historyEdit:TextEdit = %HistoryEdit

# the state chart we track
var _state_chart:StateChart
var _root:Node

# the states we are currently connected to
var _connected_states:Array[State] = []

func _ready():
	# always run, even if the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS	

	%CopyToClipboardButton.pressed.connect(func (): DisplayServer.clipboard_set(_historyEdit.text))
	%ClearButton.pressed.connect(func (): _historyEdit.text = "")

	var to_watch = get_node_or_null(initial_node_to_watch)
	if is_instance_valid(to_watch):
		debug_node(to_watch)

## Adds an item to the history list.
func add_history_entry(text:String):
	var seconds = Time.get_ticks_msec() / 1000.0
	_historyEdit.text += "[%.3f]: %s \n" % [seconds, text]
	_historyEdit.scroll_vertical = _historyEdit.get_line_count() - 1


## Sets up the debugger to track the given state chart. If the given node is not 
## a state chart, it will search the children for a state chart. If no state chart
## is found, the debugger will be disabled.
func debug_node(root:Node) -> bool:
	# if we are not enabled, we do nothing
	if not enabled:
		return false
	
	_root = root
	var success = _debug_node(root)
	
	# disconnect all existing signals
	_disconnect_all_signals()

	# if we have no success, we disable the debugger
	if not success:
		push_warning("No state chart found. Disabling debugger.")
		_setup_processing(false)
		_state_chart = null
	else:
		# find all state nodes below the state chart and connect their signals
		_connect_all_signals()
		# clear the history
		_historyEdit.text = ""
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

## Disconnects all signals from the currently connected states.
func _disconnect_all_signals():
	for state in _connected_states:
		state.state_entered.disconnect(_on_state_entered)
		state.state_exited.disconnect(_on_state_exited)


## Connects all signals from the currently processing state chart
func _connect_all_signals():
	_connected_states.clear()

	if not auto_track_state_changes:
		return
	
	if not is_instance_valid(_state_chart):
		return

	# find all state nodes below the state chart and connect their signals
	for child in _state_chart.get_children():
		if child is State:
			_connect_signals(child)


func _connect_signals(state:State):
	state.state_entered.connect(_on_state_entered.bind(state))
	state.state_exited.connect(_on_state_exited.bind(state))
	_connected_states.append(state)

	# recurse into children
	for child in state.get_children():
		if child is State:
			_connect_signals(child)


func _process(delta):
	# Clear contents
	_tree.clear()

	if not is_instance_valid(_state_chart):
		return

	var root = _tree.create_item()
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
				var state_item = _tree.create_item(parent)
				state_item.set_text(0, child.name)

				if is_instance_valid(child._pending_transition):
					var transition_item = state_item.create_child()
					transition_item.set_text(0, ">> %s (%.2f)" % [child._pending_transition.name, child._pending_transition_time])

				_collect_active_states(child, state_item)
		
	
func _on_state_entered(state:State):
	add_history_entry("Enter: %s" % state.name)


func _on_state_exited(state:State):
	add_history_entry("exiT : %s" % state.name)
