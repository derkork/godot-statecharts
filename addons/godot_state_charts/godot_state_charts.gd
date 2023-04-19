@tool
extends EditorPlugin

## The sidebar control for 2D
var _ui_sidebar_canvas:Control
## The sidebar control for 3D
var _ui_sidebar_spatial:Control

## Scene holding the sidebar
var _sidebar_ui:PackedScene = preload("utilities/editor_sidebar.tscn")


func _enter_tree():
	# prepare a copy of the sidebar for both 2D and 3D.
	_ui_sidebar_canvas = _sidebar_ui.instantiate()
	_ui_sidebar_canvas.hide()
	_ui_sidebar_spatial = _sidebar_ui.instantiate()
	_ui_sidebar_spatial.hide()
	# and add it to the right place in the editor ui
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _ui_sidebar_spatial)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT, _ui_sidebar_canvas)
	# get notified when selection changes so we can 
	# update the sidebar contents accordingly
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)


func _ready():
	# inititalize the side bars
	_ui_sidebar_canvas.setup(get_editor_interface(), get_undo_redo())
	_ui_sidebar_spatial.setup(get_editor_interface(), get_undo_redo())


func _exit_tree():
	# remove the side bars
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _ui_sidebar_spatial)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT, _ui_sidebar_canvas)
	if is_instance_valid(_ui_sidebar_canvas):
		_ui_sidebar_canvas.queue_free()
	if is_instance_valid(_ui_sidebar_spatial):
		_ui_sidebar_spatial.queue_free()


func _on_selection_changed() -> void:
	# get the current selection
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	
	# show sidebar if we selected a chart or a state 
	if selection.size() == 1:
		var selected_node = selection[0]
		if selected_node is StateChart \
			or selected_node is State \
			or selected_node is Transition:
			_ui_sidebar_canvas.show()
			_ui_sidebar_canvas.change_selected_node(selected_node)
			_ui_sidebar_spatial.show()
			_ui_sidebar_spatial.change_selected_node(selected_node)
			return
			
	# otherwise hide it
	_ui_sidebar_canvas.hide()
	_ui_sidebar_spatial.hide()
