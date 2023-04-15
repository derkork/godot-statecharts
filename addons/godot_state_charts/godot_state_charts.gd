@tool
extends EditorPlugin

# Sidebar
var ui_sidebar_canvas:Control
var ui_sidebar_spatial:Control

func _ready():

	# Sidebar
	ui_sidebar_canvas.set_interface(get_editor_interface())
	ui_sidebar_spatial.set_interface(get_editor_interface())

func _enter_tree():
	# Initialization of the plugin goes here.

	# Sidebar
	ui_sidebar_canvas = load("res://addons/godot_state_charts/utilities/editor_sidebar.tscn").instantiate()
	ui_sidebar_canvas.hide()
	ui_sidebar_spatial = load("res://addons/godot_state_charts/utilities/editor_sidebar.tscn").instantiate()
	ui_sidebar_spatial.hide()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar_spatial)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT, ui_sidebar_canvas)
	get_editor_interface().get_selection().connect("selection_changed", self._on_selection_changed)


func _exit_tree():

	# Remove Sidebar
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar_spatial)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT, ui_sidebar_canvas)
	if ui_sidebar_canvas:
		ui_sidebar_canvas.free()
	if ui_sidebar_spatial:
		ui_sidebar_spatial.free()


## Scene Tree Node Select
func _on_selection_changed() -> void:
	# Sidebar
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if selection.size() == 1:
		if(selection[0] is StateChart
		or selection[0] is State\
		or selection[0] is Transition):
			ui_sidebar_canvas.show()
			ui_sidebar_canvas.change_selected_node(selection[0])
			ui_sidebar_spatial.show()
			ui_sidebar_spatial.change_selected_node(selection[0])
		else:
			ui_sidebar_canvas.hide()
			ui_sidebar_spatial.hide()
	else:
		ui_sidebar_canvas.hide()
		ui_sidebar_spatial.hide()
