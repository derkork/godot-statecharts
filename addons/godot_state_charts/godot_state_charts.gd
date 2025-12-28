@tool
extends EditorPlugin

## The sidebar control for 2D
var _ui_sidebar_canvas:Control
## The sidebar control for 3D
var _ui_sidebar_spatial:Control

## Scene holding the sidebar
var _sidebar_ui:PackedScene = preload("utilities/editor_sidebar.tscn")

## Scene holding the main screen visualizer
var _visualizer_scene:PackedScene = preload("utilities/visualization/state_chart_visualizer.tscn")

## The main screen control for the state chart visualizer
var _main_screen:Control

var _debugger_plugin:EditorDebuggerPlugin
var _inspector_plugin:EditorInspectorPlugin

enum SidebarLocation {
	LEFT = 1,
	RIGHT = 2
}

## The current location of the sidebar. Default is left.
var _current_sidebar_location:SidebarLocation = SidebarLocation.LEFT


func _enter_tree() -> void:
	# prepare a copy of the sidebar for both 2D and 3D.
	_ui_sidebar_canvas = _sidebar_ui.instantiate()
	_ui_sidebar_canvas.sidebar_toggle_requested.connect(_toggle_sidebar)
	_ui_sidebar_canvas.hide()
	_ui_sidebar_spatial = _sidebar_ui.instantiate()
	_ui_sidebar_spatial.sidebar_toggle_requested.connect(_toggle_sidebar)
	_ui_sidebar_spatial.hide()


	# and add it to the right place in the editor ui
	_add_sidebars()
	# get notified when selection changes so we can
	# update the sidebar contents accordingly
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)

	# Add the debugger plugin
	_debugger_plugin = preload("utilities/editor_debugger/editor_debugger_plugin.gd").new()
	_debugger_plugin.initialize(get_editor_interface().get_editor_settings())
	add_debugger_plugin(_debugger_plugin)

	# add the inspector plugin for events
	_inspector_plugin = preload("utilities/event_editor/event_inspector_plugin.gd").new()
	add_inspector_plugin(_inspector_plugin)

	# Create the main screen visualizer and add it to the editor
	_main_screen = _visualizer_scene.instantiate()
	_main_screen.hide()
	get_editor_interface().get_editor_main_screen().add_child(_main_screen)


func _set_window_layout(configuration) -> void:
	_remove_sidebars()
	_current_sidebar_location = configuration.get_value("GodotStateCharts", "sidebar_location", SidebarLocation.LEFT)
	_add_sidebars()


func _get_window_layout(configuration) -> void:
	configuration.set_value("GodotStateCharts", "sidebar_location", _current_sidebar_location)


func _toggle_sidebar() -> void:
	_remove_sidebars()
	_current_sidebar_location = SidebarLocation.RIGHT if _current_sidebar_location == SidebarLocation.LEFT else SidebarLocation.LEFT
	_add_sidebars()
	queue_save_layout()


func _add_sidebars() -> void:
	if _current_sidebar_location == SidebarLocation.LEFT:
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _ui_sidebar_spatial)
		add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT, _ui_sidebar_canvas)
	else:
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, _ui_sidebar_spatial)
		add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, _ui_sidebar_canvas)


func _remove_sidebars() -> void:
	if _current_sidebar_location == SidebarLocation.LEFT:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT,_ui_sidebar_canvas)
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _ui_sidebar_spatial)
	else:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT,_ui_sidebar_canvas)
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, _ui_sidebar_spatial)



func _ready() -> void:
	# inititalize the side bars
	_ui_sidebar_canvas.setup(get_editor_interface(), get_undo_redo())
	_ui_sidebar_spatial.setup(get_editor_interface(), get_undo_redo())
	_inspector_plugin.setup(get_undo_redo())

	# initialize the main screen visualizer
	if _main_screen and _main_screen.has_method("setup"):
		_main_screen.setup(get_editor_interface())



func _exit_tree() -> void:
	# remove the debugger plugin
	remove_debugger_plugin(_debugger_plugin)

	# remove the inspector plugin
	remove_inspector_plugin(_inspector_plugin)

	# remove the side bars
	_remove_sidebars()
	if is_instance_valid(_ui_sidebar_canvas):
		_ui_sidebar_canvas.queue_free()
	if is_instance_valid(_ui_sidebar_spatial):
		_ui_sidebar_spatial.queue_free()

	# remove the main screen visualizer
	if is_instance_valid(_main_screen):
		_main_screen.queue_free()


func _on_selection_changed() -> void:
	# get the current selection
	var selection := get_editor_interface().get_selection().get_selected_nodes()

	# show sidebar if we selected a chart or a state
	if selection.size() == 1:
		var selected_node := selection[0]
		if selected_node is StateChart \
			or selected_node is StateChartState \
			or selected_node is Transition:
			_ui_sidebar_canvas.show()
			_ui_sidebar_canvas.change_selected_node(selected_node)
			_ui_sidebar_spatial.show()
			_ui_sidebar_spatial.change_selected_node(selected_node)
			return

	# otherwise hide it
	_ui_sidebar_canvas.hide()
	_ui_sidebar_spatial.hide()


# ----- Main Screen Plugin Interface -----
# These methods implement the main screen plugin interface, which adds a
# "State Charts" tab alongside the 2D, 3D, and Script editor tabs.

## Returns true to indicate this plugin provides a main screen tab.
func _has_main_screen() -> bool:
	return true


## Returns the name shown on the main screen tab.
func _get_plugin_name() -> String:
	return "State Charts"


## Returns the icon for the main screen tab.
func _get_plugin_icon() -> Texture2D:
	return preload("state_chart.svg")


## Called when the main screen should be shown or hidden.
## This happens when the user switches between editor tabs (2D, 3D, Script, State Charts).
func _make_visible(visible: bool) -> void:
	if is_instance_valid(_main_screen):
		_main_screen.visible = visible
