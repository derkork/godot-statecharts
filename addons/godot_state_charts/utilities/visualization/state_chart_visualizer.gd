@tool
## The main container control for the state chart visualization editor screen.
##
## This control serves as the main screen for the "State Charts" editor tab.
## It contains:
## - A toolbar with zoom controls
## - The canvas where the state chart diagram is rendered
##
## The visualizer listens to editor selection changes and automatically
## displays the state chart that contains the currently selected node.
## Layout uses a CoSE-inspired force-directed algorithm that runs incrementally
## to avoid freezing the editor. The simulation automatically stops when stable
## and pauses when the tab is not visible.
extends Control

const StateChartCanvas = preload("state_chart_canvas.gd")

## Reference to the Godot editor interface, used for selection tracking.
var _editor_interface: EditorInterface = null

## The state chart currently being visualized.
var _current_state_chart: StateChart = null

## Whether we should fit to view after the next layout completes.
var _pending_fit_to_view: bool = false


# ----- Child Nodes -----

## The toolbar at the top of the visualizer.
@onready var _toolbar: HBoxContainer = %Toolbar

## The canvas where the diagram is drawn.
@onready var _canvas := %Canvas

## Zoom slider in the toolbar.
@onready var _zoom_slider: HSlider = %ZoomSlider

## Zoom percentage label.
@onready var _zoom_label: Label = %ZoomLabel


# ----- Initialization -----

## Called by the main plugin to provide the editor interface.
## This must be called before the visualizer can function properly.
func setup(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface

	# Connect to selection changes to update the visualization
	var selection := editor_interface.get_selection()
	selection.selection_changed.connect(_on_selection_changed)


func _ready() -> void:
	# Connect canvas signals
	_canvas.node_clicked.connect(_on_canvas_node_clicked)
	_canvas.zoom_changed.connect(_on_canvas_zoom_changed)
	_canvas.layout_completed.connect(_on_canvas_layout_completed)

	# Initialize toolbar
	if _zoom_slider:
		_zoom_slider.min_value = StateChartCanvas.MIN_ZOOM * 100
		_zoom_slider.max_value = StateChartCanvas.MAX_ZOOM * 100
		_zoom_slider.value = 100
		_zoom_slider.value_changed.connect(_on_zoom_slider_changed)

	_update_zoom_label()


# ----- Public Methods -----

## Forces a refresh of the visualization.
## Call this when the state chart structure has changed.
func refresh() -> void:
	_refresh_visualization()


# ----- Selection Tracking -----

## Called when the editor selection changes.
func _on_selection_changed() -> void:
	if _editor_interface == null:
		return

	var selection := _editor_interface.get_selection().get_selected_nodes()

	if selection.size() != 1:
		return

	var selected: Node = selection[0]

	# Find the StateChart that contains this node
	var chart: StateChart = _find_state_chart(selected)

	if chart != null and chart != _current_state_chart:
		_current_state_chart = chart
		_refresh_visualization()

	# Update selection highlight in canvas
	_canvas.set_selected_node(selected)


## Finds the StateChart ancestor of a node, or the node itself if it's a StateChart.
func _find_state_chart(node: Node) -> StateChart:
	if node is StateChart:
		return node

	if node is StateChartState or node is Transition:
		# Walk up to find the StateChart
		var parent := node.get_parent()
		while parent != null:
			if parent is StateChart:
				return parent
			parent = parent.get_parent()

	return null


# ----- Visualization -----

## Sets the state chart for visualization and starts the layout simulation.
## The simulation runs incrementally via _process() in the canvas.
func _refresh_visualization(fit_after_layout: bool = true) -> void:
	# Set pending fit flag - we'll fit to view after layout completes
	_pending_fit_to_view = fit_after_layout

	# Start the layout computation
	_canvas.set_state_chart(_current_state_chart)


# ----- Toolbar Handlers -----

func _on_zoom_slider_changed(value: float) -> void:
	# Pass false to avoid signal loop (slider -> canvas -> slider)
	_canvas.set_zoom(value / 100.0, false)
	_update_zoom_label()


func _on_canvas_zoom_changed(new_zoom: float) -> void:
	# Update slider to match canvas zoom (e.g., from mouse wheel)
	_zoom_slider.set_value_no_signal(new_zoom * 100.0)
	_update_zoom_label()


func _on_canvas_layout_completed() -> void:
	# Fit to view after layout completes if we're loading a new chart
	if _pending_fit_to_view:
		_canvas.fit_to_view()
		_pending_fit_to_view = false


func _update_zoom_label() -> void:
	_zoom_label.text = str(int(_canvas.get_zoom() * 100)) + "%"


func _on_fit_button_pressed() -> void:
	# fit_to_view emits zoom_changed which updates the slider via _on_canvas_zoom_changed
	_canvas.fit_to_view()


func _on_refresh_button_pressed() -> void:
	# Restart the layout from scratch but preserve the current view position
	_pending_fit_to_view = false
	_canvas.redraw()


# ----- Canvas Event Handlers -----

## Called when the user clicks on a node in the canvas.
func _on_canvas_node_clicked(node: Node) -> void:
	if _editor_interface == null or node == null:
		return

	# Select the node in the editor
	var selection := _editor_interface.get_selection()
	selection.clear()
	selection.add_node(node)

	# Also focus the node in the inspector
	_editor_interface.edit_node(node)
