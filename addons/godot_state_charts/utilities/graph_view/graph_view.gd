@tool
extends MarginContainer

# PlantUML generator
const PlantUml = preload("plantuml.gd")

# Sidebar
const EditorSidebar = preload("../editor_sidebar.gd")
const EditorSidebarScene = preload("../editor_sidebar.tscn")

## Constants for the settings
const SETTINGS_ROOT:String = "godot_state_charts/graph_view/"
const SETTINGS_ENABLE_RENDERING:String = SETTINGS_ROOT + "enable_graph_rendering"
const SETTINGS_RENDER_SERVER_URL:String = SETTINGS_ROOT + "render_server_url"

@onready var _texture_rect:TextureRect = %TextureRect
@onready var _copy_button:Button = %CopyButton
@onready var _http_request:HTTPRequest = %HTTPRequest
@onready var _left_side_bar:Container = %LeftSideBar
@onready var _right_side_bar:Container = %RightSideBar
@onready var _disabled_label:Label = %DisabledLabel
@onready var _disclaimer_label:Label = %DisclaimerLabel
@onready var _no_chart_label:Label = %NoChartLabel
@onready var _render_enable_checkbox:CheckBox = %RenderEnableCheckbox
@onready var _scroll_container:ScrollContainer = %ScrollContainer
@onready var _server_url_line_edit:LineEdit = %ServerUrl
@onready var _skin = %Skin

var _editor_sidebar:EditorSidebar
var _current_chart:StateChart
var _last_rendered_uml:String = ""

var _fetching:bool = false
var _editor_interface:EditorInterface
var _editor_settings:EditorSettings


func setup(editor_plugin:EditorPlugin):
	_editor_interface = editor_plugin.get_editor_interface()
	_editor_settings = _editor_interface.get_editor_settings()
	_editor_sidebar = EditorSidebarScene.instantiate()
	_editor_sidebar.setup(_editor_interface, editor_plugin.get_undo_redo())
	
func _set_window_layout(configuration:ConfigFile) -> void:
	pass

func _get_window_layout(configuration:ConfigFile) -> void:
	pass
	
	
func _ready():
	# this is only set when being run as part of the plugin, so we need to 
	# add this check to avoid spurious errors when editing the graph view scene file
	if _editor_settings == null:
		return

	_server_url_line_edit.text = _get_server_url()
	_left_side_bar.add_child(_editor_sidebar)
	_update_ui_state()	

func _update_ui_state():
	var rendering_enabled = _is_rendering_enabled()
	var chart_selected = _current_chart != null
	
	_disabled_label.visible = not rendering_enabled
	_render_enable_checkbox.set_pressed_no_signal(rendering_enabled)
	_no_chart_label.visible = rendering_enabled and not chart_selected
	_disclaimer_label.visible = rendering_enabled and chart_selected
	_scroll_container.visible = rendering_enabled and chart_selected
	_copy_button.disabled = not chart_selected
	
	
func change_selected_node(node:Node):
	var chart = node
	while chart != null and not chart is StateChart:
		chart = chart.get_parent()
		
	if chart != _current_chart:
		_last_rendered_uml = ""
		
	_current_chart = chart
	
	_editor_sidebar.visible = chart != null
	if chart != null:
		_editor_sidebar.change_selected_node(node)
		
	_update_ui_state()
	
		
func _on_copy_button_pressed():
	if _current_chart == null:
		return

	var uml = PlantUml.as_plantuml(_current_chart)
	DisplayServer.clipboard_set(uml)
		


func _on_timer_timeout():
	# no chart right now, skip
	if _current_chart == null:
		return
		
	# if we're currently still fetching, skip		
	if _fetching:
		return
		
	
	# rendering disabled, skip
	if not _is_rendering_enabled():
		return
		
	var new_uml = PlantUml.as_plantuml(_current_chart, _skin.get_skin())

	# nothing changed, skip
	if new_uml == _last_rendered_uml:
		return
		
	_last_rendered_uml = new_uml
		
	
	var renderer = preload("renderers/kroki_renderer.gd").new(_http_request)
	var base_url = _get_server_url()
	if base_url.is_empty():
		base_url = "https://kroki.io"
		
	renderer.base_url = base_url

	_fetching = true
	var result := await renderer.render_async(new_uml)
	_fetching = false
	
	if not result.successful:
		push_error("Error while loading image: ", result.error_message)
		return
		
		
	var img = Image.new()
	img.load_png_from_buffer(result.data)	
	
	var texture = ImageTexture.new()
	texture.set_image(img)
	_texture_rect.texture = texture
		

func _get_setting(name:String, default:Variant) -> Variant:
	if _editor_settings.has_setting(name):
		return _editor_settings.get_setting(name)
	return default
	
func _is_rendering_enabled() -> bool:
	return _get_setting(SETTINGS_ENABLE_RENDERING, false)
	
func _get_server_url() -> String:
	return _get_setting(SETTINGS_RENDER_SERVER_URL, "")

func _on_render_enable_checkbox_toggled(button_pressed):
	_editor_settings.set_setting(SETTINGS_ENABLE_RENDERING, button_pressed)
	_update_ui_state()
	
func _on_server_url_text_changed(new_text):
	_editor_settings.set_setting(SETTINGS_RENDER_SERVER_URL, new_text)
