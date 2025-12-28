@tool
extends EditorPlugin

## Scene holding the main screen plugin
var _main_screen_scene: PackedScene = preload("utilities/state_charts_main_screen_plugin.tscn")

## The main screen control for the state chart plugin
var _main_screen: Control

var _debugger_plugin: EditorDebuggerPlugin
var _inspector_plugin: EditorInspectorPlugin

## Whether the sidebar is on the left side in the main screen.
var _sidebar_on_left: bool = false


func _enter_tree() -> void:
	# Add the debugger plugin
	_debugger_plugin = preload("utilities/editor_debugger/editor_debugger_plugin.gd").new()
	_debugger_plugin.initialize(get_editor_interface().get_editor_settings())
	add_debugger_plugin(_debugger_plugin)

	# add the inspector plugin for events
	_inspector_plugin = preload("utilities/event_editor/event_inspector_plugin.gd").new()
	add_inspector_plugin(_inspector_plugin)

	# Create the main screen plugin and add it to the editor
	_main_screen = _main_screen_scene.instantiate()
	_main_screen.hide()
	get_editor_interface().get_editor_main_screen().add_child(_main_screen)


func _set_window_layout(configuration) -> void:
	_sidebar_on_left = configuration.get_value("GodotStateCharts", "sidebar_on_left", false)
	if _main_screen and _main_screen.has_method("set_sidebar_on_left"):
		_main_screen.set_sidebar_on_left(_sidebar_on_left)


func _get_window_layout(configuration) -> void:
	if _main_screen and _main_screen.has_method("is_sidebar_on_left"):
		_sidebar_on_left = _main_screen.is_sidebar_on_left()
	configuration.set_value("GodotStateCharts", "sidebar_on_left", _sidebar_on_left)


func _ready() -> void:
	_inspector_plugin.setup(get_undo_redo())

	# initialize the main screen plugin
	if _main_screen and _main_screen.has_method("setup"):
		_main_screen.setup(get_editor_interface(), get_undo_redo())
		_main_screen.set_sidebar_on_left(_sidebar_on_left)


func _exit_tree() -> void:
	# remove the debugger plugin
	remove_debugger_plugin(_debugger_plugin)

	# remove the inspector plugin
	remove_inspector_plugin(_inspector_plugin)

	# remove the main screen plugin
	if is_instance_valid(_main_screen):
		_main_screen.queue_free()


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
