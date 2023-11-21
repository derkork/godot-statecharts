## UI for the in-editor state debugger
@tool
extends Node
const DebuggerStateInfo = preload("debugger_state_info.gd")

## The tree that shows all state charts
@onready var _all_state_charts_tree = %AllStateChartsTree
## The tree that shows the current state chart
@onready var _current_state_chart_tree = %CurrentStateChartTree

## Dictionary of all state charts and their states. Key is the path to the
## state chart, value is a dictionary of states. Key is the path to the state,
## value is the state info (an array).
var _state_infos:Dictionary = {}

## Path to the currently selected state chart.
var _current_chart:NodePath = ""

func _ready():
	clear()

## Clears all state charts and state trees.
func clear():
	_clear_all()
	
## Clears all state charts and state trees.
func _clear_all():
	_all_state_charts_tree.clear()
	
	var root = _all_state_charts_tree.create_item()
	root.set_text(0, "State Charts")
	root.set_selectable(0, false)
	
	_clear_current()

## Clears the tree holding the states of the currently selected state chart.	
func _clear_current():
	_current_state_chart_tree.clear()
	var root = _current_state_chart_tree.create_item()
	root.set_text(0, "States")
	root.set_selectable(0, false)

## Adds a new state chart to the debugger.
func add_chart(path:NodePath):
	_state_infos[path] = {}
	_repaint_charts()
	
## Removes a state chart from the debugger.
func remove_chart(path:NodePath):
	_state_infos.erase(path)
	if _current_chart == path:
		_clear_current()
	_repaint_charts()
	
## Updates state information for a state chart.
func update_state(state_info:Array):
	var chart = DebuggerStateInfo.get_chart(state_info)
	var path = DebuggerStateInfo.get_state(state_info)
	
	# probably received out of order.
	if not _state_infos.has(chart):
		return
	
	_state_infos[chart][path] = state_info
	if chart == _current_chart:
		_repaint_states(_current_chart)

## Repaints the tree of all state charts.
func _repaint_charts():
	for chart in _state_infos.keys():
		_add_to_tree(_all_state_charts_tree, chart, preload("../../state_chart.svg"))
	_clear_unused_items(_all_state_charts_tree.get_root())


## Repaints the tree of the currently selected state chart.
func _repaint_states(chart:NodePath):
	for state_info in _state_infos[_current_chart].values():
		if DebuggerStateInfo.get_active(state_info):
			_add_to_tree(_current_state_chart_tree, DebuggerStateInfo.get_state(state_info), DebuggerStateInfo.get_state_icon(state_info))
		if DebuggerStateInfo.get_transition_pending(state_info):
			var transition_path = DebuggerStateInfo.get_transition_path(state_info)
			var transition_time = DebuggerStateInfo.get_transition_time(state_info)
			var name = transition_path.get_name(transition_path.get_name_count() - 1)
			_add_to_tree(_current_state_chart_tree, DebuggerStateInfo.get_transition_path(state_info), preload("../../transition.svg"), "%s (%.1fs)" % [name, transition_time])	
	_clear_unused_items(_current_state_chart_tree.get_root())


## Walks over the tree and removes all items that are not marked as in use
## removes the "in-use" marker from all remaining items
func _clear_unused_items(root:TreeItem):	
	if root == null:
		return

	for child in root.get_children():
		if not child.has_meta("__in_use"):
			root.remove_child(child)
			_free_all(child)
		else:
			child.remove_meta("__in_use")
			_clear_unused_items(child)

## Frees this tree item and all its children
func _free_all(root:TreeItem):
	if root == null:
		return

	for child in root.get_children():
		root.remove_child(child)
		_free_all(child)
		
	root.free()

## Adds an item to the tree. Will re-use existing items if possible.
## The node path will be used as structure for the tree. The created 
## leaf will have the given icon and text.
func _add_to_tree(tree:Tree, path:NodePath, icon:Texture2D, text:String = ""):
	var ref = tree.get_root()
	
	for i in path.get_name_count():
		var segment = path.get_name(i)
		# do we need to add a new child?
		var needs_new = true
		
		if ref != null:
			for child in ref.get_children():
				# re-use child if it exists
				if child.get_text(0) == segment:
					ref = child
					ref.set_meta("__in_use", true)
					needs_new = false
					break
		
		if needs_new:
			ref = tree.create_item(ref)
			ref.set_text(0, segment)
			ref.set_meta("__in_use", true)
			ref.set_selectable(0, false)
			
			
	ref.set_meta("__path", path)
	if text != "":
		ref.set_text(0, text)
	ref.set_icon(0, icon)
	ref.set_selectable(0, true)

## Called when a state chart is selected in the tree.
func _on_all_state_charts_tree_item_selected():
	var item = _all_state_charts_tree.get_selected()
	if item == null:
		return
		
	if not item.has_meta("__path"):
		return
		
	var path = item.get_meta("__path")
	_current_chart = path
	_repaint_states(_current_chart)
	
	
