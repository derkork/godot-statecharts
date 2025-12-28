@tool
## The canvas control that renders the state chart visualization.
##
## This control handles:
## - Drawing states as nested rounded rectangles with labels
## - Drawing transitions as arrows with styled labels
## - Pan and zoom navigation
## - Click-to-select functionality for states and transitions
##
## The canvas uses a transform to support zooming and panning. All state and
## transition coordinates are in "canvas space" which is then transformed to
## screen space for rendering.
##
## Layout uses the Sugiyama algorithm which is deterministic and runs once per
## structure change.
extends Control

const VisualState = preload("visual_state.gd")
const VisualTransition = preload("visual_transition.gd")
const VisualizationTheme = preload("visualization_theme.gd")
const VisualLabelSegment = preload("visual_label_segment.gd")
const LayoutEngine = preload("layout_engine.gd")

## Emitted when the user clicks on a state or transition node.
## The editor interface uses this to select the node in the scene tree.
signal node_clicked(node: Node)

## Emitted when the zoom level changes (e.g., from mouse wheel).
## The visualizer uses this to sync the zoom slider.
signal zoom_changed(new_zoom: float)

## Emitted when the layout computation completes.
## The visualizer uses this to fit the view when a new chart is loaded.
signal layout_completed()


# ----- Layout Engine -----

## The layout engine instance that computes the Sugiyama layout.
var _layout_engine: LayoutEngine = LayoutEngine.new()

## The state chart currently being laid out.
var _current_state_chart: StateChart = null


# ----- Layout Data -----

## The visual states to render, ordered parent-first for correct z-order.
var _visual_states: Array[VisualState] = []

## The visual transitions to render.
var _visual_transitions: Array[VisualTransition] = []


# ----- View Transform -----

## Current zoom level. 1.0 = 100%, 0.5 = 50%, 2.0 = 200%.
var _zoom: float = 1.0

## Pan offset in screen coordinates. This is how much the canvas origin
## is shifted from the control's top-left corner.
var _pan_offset: Vector2 = Vector2.ZERO

## Minimum allowed zoom level.
const MIN_ZOOM: float = 0.1

## Maximum allowed zoom level.
const MAX_ZOOM: float = 4.0

## How much zoom changes per mouse wheel tick.
const ZOOM_STEP: float = 0.1


# ----- Interaction State -----

## Whether the user is currently panning (middle mouse held).
var _is_panning: bool = false

## Mouse position when panning started, used to calculate pan delta.
var _pan_start_mouse: Vector2 = Vector2.ZERO

## Pan offset when panning started.
var _pan_start_offset: Vector2 = Vector2.ZERO

## The currently selected node (for highlighting).
var _selected_node: Node = null


# ----- Cached Fonts -----

var _font_regular: Font
var _font_bold: Font
var _font_italic: Font
var _font_bold_italic: Font
var _font_mono: Font

# ----- Cached State Icons -----


## Cached state type icons, keyed by state type string.
const _state_icons: Dictionary = {
	"atomic": preload("../../atomic_state.svg"),
	"compound": preload("../../compound_state.svg"),
	"parallel": preload("../../parallel_state.svg"),
	"history": preload("../../history_state.svg"),
}


# ----- Public Methods -----

## Sets the state chart to visualize and computes the layout.
## If the chart is the same and structure unchanged, does nothing.
func set_state_chart(state_chart: StateChart) -> void:
	_current_state_chart = state_chart
	redraw()


## Redraws the graph
func redraw():
	var layout := _layout_engine.layout(_current_state_chart)
	_visual_states = layout.states
	_visual_transitions = layout.transitions
	queue_redraw()
	layout_completed.emit()

# ----- Layout Lifecycle -----

func _ready() -> void:
	_font_regular = VisualizationTheme.get_font(self)
	_font_bold = VisualizationTheme.get_bold_font(self)
	_font_italic = VisualizationTheme.get_italic_font(self)
	_font_bold_italic = VisualizationTheme.get_bold_italic_font(self)
	_font_mono = VisualizationTheme.get_mono_font(self)
	redraw()


## Adjusts pan and zoom to fit all states in the visible area with some margin.
func fit_to_view() -> void:
	if _visual_states.is_empty():
		_zoom = 1.0
		_pan_offset = Vector2.ZERO
		queue_redraw()
		zoom_changed.emit(_zoom)
		return

	# Calculate bounding box of all states
	var bounds: Rect2 = _visual_states[0].rect
	for state in _visual_states:
		bounds = bounds.merge(state.rect)

	# Add margin around the content
	bounds = bounds.grow(30.0)

	# Calculate zoom to fit
	var view_size := size
	if view_size.x <= 0 or view_size.y <= 0:
		return

	var zoom_x := view_size.x / bounds.size.x
	var zoom_y := view_size.y / bounds.size.y
	_zoom = clamp(min(zoom_x, zoom_y), MIN_ZOOM, MAX_ZOOM)

	# Center the content
	var content_center := bounds.get_center() * _zoom
	var view_center := view_size / 2.0
	_pan_offset = view_center - content_center

	queue_redraw()
	zoom_changed.emit(_zoom)


## Sets the currently selected node for highlighting.
func set_selected_node(node: Node) -> void:
	_selected_node = node
	queue_redraw()


## Returns the current zoom level.
func get_zoom() -> float:
	return _zoom


## Sets the zoom level, clamped to valid range.
func set_zoom(new_zoom: float, emit_signal: bool = true) -> void:
	var old_zoom := _zoom
	_zoom = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)
	queue_redraw()
	if emit_signal and _zoom != old_zoom:
		zoom_changed.emit(_zoom)


# ----- Drawing -----

func _draw() -> void:
	# Draw background
	var bg_color := VisualizationTheme.get_background_color(self)
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)

	# Draw a placeholder message if we have nothing to draw.
	if _visual_states.is_empty():
		_draw_empty_message()
		return

	# Draw states (parent first, so children appear on top)
	for vs in _visual_states:
		# Skip if the state node has been freed
		if not is_instance_valid(vs.state_node):
			continue
		_draw_state(vs)

	# Draw transition arrows on top of states
	for vt in _visual_transitions:
		# Skip if source or target state node has been freed
		if not is_instance_valid(vt.source_state) or not is_instance_valid(vt.target_state):
			continue
		if not is_instance_valid(vt.source_state.state_node) or not is_instance_valid(vt.target_state.state_node):
			continue
		_draw_transition_arrow(vt)

	# Draw transition labels on top of arrows
	for vt in _visual_transitions:
		if not is_instance_valid(vt.source_state) or not is_instance_valid(vt.target_state):
			continue
		if not is_instance_valid(vt.source_state.state_node) or not is_instance_valid(vt.target_state.state_node):
			continue
		_draw_transition_label(vt)


## Draws a placeholder message when no state chart is visualized.
func _draw_empty_message() -> void:
	var font := _font_regular if _font_regular else VisualizationTheme.get_font(self)
	var font_color := VisualizationTheme.get_font_color(self)
	var message := "Select a StateChart to visualize"
	var text_size := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var pos := (size - text_size) / 2.0
	draw_string(font, pos + Vector2(0, text_size.y), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, font_color)


## Draws a single state as a rounded rectangle with label.
func _draw_state(vs: VisualState) -> void:
	var screen_rect := _canvas_to_screen_rect(vs.rect)

	# Skip if completely off-screen
	if not _is_rect_visible(screen_rect):
		return

	var fill_color := VisualizationTheme.get_state_fill_color(self, vs.state_type)
	var border_color := VisualizationTheme.get_state_border_color(self, vs.state_type)
	var font_color := VisualizationTheme.get_font_color(self)

	# Draw filled rounded rectangle
	_draw_rounded_rect(screen_rect, fill_color, true)

	# Draw border
	_draw_rounded_rect(screen_rect, border_color, false)

	# Draw selection highlight if this state is selected
	if vs.state_node == _selected_node:
		var highlight_color := VisualizationTheme.get_selection_color(self)
		var highlight_rect := screen_rect.grow(3.0 * _zoom)
		_draw_rounded_rect(highlight_rect, highlight_color, false, 3.0)

	# Draw state icon and name
	var font := _font_regular if _font_regular else VisualizationTheme.get_font(self)
	var font_size := int(VisualizationTheme.STATE_LABEL_FONT_SIZE * _zoom)
	if font_size >= 6:  # Don't draw tiny text
		var label_pos := screen_rect.position + Vector2(8, 20) * _zoom
		var state_name: String = vs.state_node.name

		# Draw state type icon before the name
		var icon: Texture2D = _state_icons.get(vs.state_type)
		if icon != null:
			var icon_size := font_size  # Scale icon to match font size
			var icon_pos := label_pos - Vector2(0, icon_size * 0.8)  # Align with text baseline
			draw_texture_rect(icon, Rect2(icon_pos, Vector2(icon_size, icon_size)), false)
			label_pos.x += icon_size + 4 * _zoom  # Add spacing after icon

		draw_string(font, label_pos, state_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)

	# Draw initial state indicator
	if vs.is_initial:
		_draw_initial_indicator(screen_rect)


## Draws a rounded rectangle (filled or outline).
func _draw_rounded_rect(rect: Rect2, color: Color, filled: bool, line_width: float = -1.0) -> void:
	var radius := VisualizationTheme.CORNER_RADIUS * _zoom
	var width := line_width if line_width > 0 else VisualizationTheme.BORDER_WIDTH * _zoom

	# For simplicity, draw regular rectangles when zoomed out (rounded corners too small to see)
	if radius < 2.0:
		if filled:
			draw_rect(rect, color, true)
		else:
			draw_rect(rect, color, false, width)
		return

	# Draw rounded rectangle using polygon approximation
	var points := _get_rounded_rect_points(rect, radius)
	if filled:
		draw_polygon(points, [color])
	else:
		draw_polyline(points, color, width, true)


## Generates points for a rounded rectangle polygon.
func _get_rounded_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()

	# Clamp radius to not exceed half the smaller dimension
	radius = min(radius, rect.size.x / 2.0, rect.size.y / 2.0)

	var corners := [
		rect.position + Vector2(radius, 0),  # Top-left start
		rect.position + Vector2(rect.size.x - radius, 0),  # Top-right start
		rect.position + Vector2(rect.size.x, radius),  # Right-top start
		rect.position + Vector2(rect.size.x, rect.size.y - radius),  # Right-bottom start
		rect.position + Vector2(rect.size.x - radius, rect.size.y),  # Bottom-right start
		rect.position + Vector2(radius, rect.size.y),  # Bottom-left start
		rect.position + Vector2(0, rect.size.y - radius),  # Left-bottom start
		rect.position + Vector2(0, radius),  # Left-top start
	]

	var corner_centers := [
		rect.position + Vector2(radius, radius),  # Top-left
		rect.position + Vector2(rect.size.x - radius, radius),  # Top-right
		rect.position + Vector2(rect.size.x - radius, rect.size.y - radius),  # Bottom-right
		rect.position + Vector2(radius, rect.size.y - radius),  # Bottom-left
	]

	var segments_per_corner := 4

	# Top edge
	points.append(corners[0])
	points.append(corners[1])

	# Top-right corner
	for i in range(segments_per_corner + 1):
		var angle := -PI / 2.0 + (PI / 2.0) * float(i) / float(segments_per_corner)
		points.append(corner_centers[1] + Vector2(cos(angle), sin(angle)) * radius)

	# Right edge
	points.append(corners[3])

	# Bottom-right corner
	for i in range(segments_per_corner + 1):
		var angle := 0.0 + (PI / 2.0) * float(i) / float(segments_per_corner)
		points.append(corner_centers[2] + Vector2(cos(angle), sin(angle)) * radius)

	# Bottom edge
	points.append(corners[5])

	# Bottom-left corner
	for i in range(segments_per_corner + 1):
		var angle := PI / 2.0 + (PI / 2.0) * float(i) / float(segments_per_corner)
		points.append(corner_centers[3] + Vector2(cos(angle), sin(angle)) * radius)

	# Left edge
	points.append(corners[7])

	# Top-left corner
	for i in range(segments_per_corner + 1):
		var angle := PI + (PI / 2.0) * float(i) / float(segments_per_corner)
		points.append(corner_centers[0] + Vector2(cos(angle), sin(angle)) * radius)

	# Close the shape
	points.append(corners[0])

	return points


## Draws the initial state indicator (a filled circle with arrow pointing to the state).
func _draw_initial_indicator(screen_rect: Rect2) -> void:
	var color := VisualizationTheme.get_initial_indicator_color(self)
	var radius := VisualizationTheme.INITIAL_INDICATOR_RADIUS * _zoom

	# Position the indicator to the left of the state
	var circle_center := Vector2(
		screen_rect.position.x - radius * 3,
		screen_rect.position.y + screen_rect.size.y / 2.0
	)

	# Draw filled circle
	draw_circle(circle_center, radius, color)

	# Draw arrow pointing to the state
	var arrow_start := circle_center + Vector2(radius, 0)
	var arrow_end := Vector2(screen_rect.position.x, circle_center.y)

	draw_line(arrow_start, arrow_end, color, VisualizationTheme.TRANSITION_LINE_WIDTH * _zoom)

	# Draw arrowhead
	_draw_arrowhead(arrow_end, arrow_start, color)


## Draws a transition arrow (line and arrowhead only, no label).
func _draw_transition_arrow(vt: VisualTransition) -> void:
	if vt.path.size() < 2:
		return

	var color := VisualizationTheme.get_transition_color(self)
	var line_width := VisualizationTheme.TRANSITION_LINE_WIDTH * _zoom

	# Transform path to screen coordinates
	var screen_path := PackedVector2Array()
	for point in vt.path:
		screen_path.append(_canvas_to_screen(point))

	# Check if visible
	var path_rect := _get_path_bounds(screen_path)
	if not _is_rect_visible(path_rect):
		return

	# Highlight if any transition in this group is selected
	var is_selected := _is_transition_selected(vt)
	if is_selected:
		var highlight_color := VisualizationTheme.get_selection_color(self)
		draw_polyline(screen_path, highlight_color, line_width * 3)

	# Draw the line
	draw_polyline(screen_path, color, line_width)

	# Draw arrowhead at the end
	var end_point := screen_path[screen_path.size() - 1]
	var prev_point := screen_path[screen_path.size() - 2]
	_draw_arrowhead(end_point, prev_point, color)


## Checks if any transition in the visual transition group is currently selected.
func _is_transition_selected(vt: VisualTransition) -> bool:
	for t in vt.transition_nodes:
		if t == _selected_node:
			return true
	return false


## Draws an arrowhead at the end of a line.
func _draw_arrowhead(tip: Vector2, from: Vector2, color: Color) -> void:
	var direction := (tip - from).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var arrow_size := VisualizationTheme.ARROWHEAD_SIZE * _zoom

	var points := PackedVector2Array([
		tip,
		tip - direction * arrow_size + perpendicular * arrow_size * 0.5,
		tip - direction * arrow_size - perpendicular * arrow_size * 0.5
	])

	draw_polygon(points, [color])


## Draws the styled label for a transition at its computed position.
## Uses different fonts for different styles (bold, italic, monospace).
func _draw_transition_label(vt: VisualTransition) -> void:
	if not vt.has_label():
		return

	var font_size := int(VisualizationTheme.TRANSITION_LABEL_FONT_SIZE * _zoom)

	if font_size < 6:
		return

	var font_color := VisualizationTheme.get_font_color(self)

	# Get the appropriate font for each style
	var fonts := {
		VisualLabelSegment.Style.NORMAL: _font_regular if _font_regular else VisualizationTheme.get_font(self),
		VisualLabelSegment.Style.ITALIC: _font_italic if _font_italic else _font_regular,
		VisualLabelSegment.Style.BOLD: _font_bold if _font_bold else _font_regular,
		VisualLabelSegment.Style.BOLD_ITALIC: _font_bold_italic if _font_bold_italic else _font_bold,
		VisualLabelSegment.Style.MONO: _font_mono if _font_mono else _font_regular,
	}

	# First pass: measure total text width for centering
	var total_width := 0.0
	var max_ascent := 0.0
	var max_descent := 0.0

	for segment in vt.label.label_segments:
		var seg: VisualLabelSegment = segment
		var font: Font = fonts.get(seg.style, fonts[VisualLabelSegment.Style.NORMAL])
		var segment_size := font.get_string_size(seg.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		total_width += segment_size.x

		var ascent := font.get_ascent(font_size)
		var descent := font.get_descent(font_size)
		max_ascent = max(max_ascent, ascent)
		max_descent = max(max_descent, descent)

	# Use the computed label position
	var label_center := _canvas_to_screen(vt.label_position)

	# Calculate the starting position (left edge of centered text)
	var label_start := label_center - Vector2(total_width / 2.0, 0)

	# Calculate background rectangle that properly covers descenders
	var padding := 3.0 * _zoom
	var bg_rect := Rect2(
		label_start.x - padding,
		label_center.y - max_ascent - padding,
		total_width + padding * 2,
		max_ascent + max_descent + padding * 2
	)

	# Draw semi-transparent background for readability
	var bg_color := VisualizationTheme.get_background_color(self)
	bg_color.a = 0.9
	draw_rect(bg_rect, bg_color)

	# Second pass: draw each segment with appropriate font
	var x_offset := 0.0
	for segment in vt.label.label_segments:
		var seg: VisualLabelSegment = segment
		var font: Font = fonts.get(seg.style, fonts[VisualLabelSegment.Style.NORMAL])
		var draw_pos := label_start + Vector2(x_offset, 0)

		draw_string(font, draw_pos, seg.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)

		# Advance x position for next segment
		var segment_size := font.get_string_size(seg.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		x_offset += segment_size.x


# ----- Input Handling -----

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_zoom_at_point(event.position, ZOOM_STEP)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_zoom_at_point(event.position, -ZOOM_STEP)
		MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_is_panning = true
				_pan_start_mouse = event.position
				_pan_start_offset = _pan_offset
			else:
				_is_panning = false
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_click(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_panning:
		_pan_offset = _pan_start_offset + (event.position - _pan_start_mouse)
		queue_redraw()


## Zooms the view at a specific screen point (keeps that point stationary).
func _zoom_at_point(screen_point: Vector2, delta: float) -> void:
	var old_zoom := _zoom
	_zoom = clamp(_zoom + delta, MIN_ZOOM, MAX_ZOOM)

	if _zoom == old_zoom:
		return

	# Adjust pan to keep the mouse position stationary
	var canvas_point := _screen_to_canvas(screen_point)
	var new_screen_point := canvas_point * _zoom + _pan_offset
	_pan_offset += screen_point - new_screen_point

	queue_redraw()
	zoom_changed.emit(_zoom)


## Handles a click at the given screen position.
func _handle_click(screen_pos: Vector2) -> void:
	var canvas_pos := _screen_to_canvas(screen_pos)

	# Check transition labels FIRST (they're rendered on top of everything)
	for vt in _visual_transitions:
		if vt.has_label():
			var label_rect := _get_transition_label_rect(vt)
			if label_rect.has_point(canvas_pos):
				var primary := vt.get_primary_transition()
				if primary != null:
					node_clicked.emit(primary)
				return

	# Check transition arrows (rendered on top of states)
	for vt in _visual_transitions:
		if _point_near_path(canvas_pos, vt.path, 10.0 / _zoom):
			var primary := vt.get_primary_transition()
			if primary != null:
				node_clicked.emit(primary)
			return

	# Check states in reverse order (children first, since they're drawn on top)
	for i in range(_visual_states.size() - 1, -1, -1):
		var vs := _visual_states[i]
		if vs.rect.has_point(canvas_pos):
			node_clicked.emit(vs.state_node)
			return


## Calculates the bounding rectangle for a transition's label in canvas coordinates.
func _get_transition_label_rect(vt: VisualTransition) -> Rect2:
	if not vt.has_label():
		return Rect2()

	var font_size := int(VisualizationTheme.TRANSITION_LABEL_FONT_SIZE * _zoom)
	if font_size < 6:
		return Rect2()

	var fonts := {
		VisualLabelSegment.Style.NORMAL: _font_regular if _font_regular else VisualizationTheme.get_font(self),
		VisualLabelSegment.Style.ITALIC: _font_italic if _font_italic else _font_regular,
		VisualLabelSegment.Style.BOLD: _font_bold if _font_bold else _font_regular,
		VisualLabelSegment.Style.BOLD_ITALIC: _font_bold_italic if _font_bold_italic else _font_bold,
		VisualLabelSegment.Style.MONO: _font_mono if _font_mono else _font_regular,
	}

	# Measure label dimensions
	var total_width := 0.0
	var max_ascent := 0.0
	var max_descent := 0.0

	for segment in vt.label.label_segments:
		var seg: VisualLabelSegment = segment
		var font: Font = fonts.get(seg.style, fonts[VisualLabelSegment.Style.NORMAL])
		var segment_size := font.get_string_size(seg.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		total_width += segment_size.x
		max_ascent = max(max_ascent, font.get_ascent(font_size))
		max_descent = max(max_descent, font.get_descent(font_size))

	var label_height := max_ascent + max_descent

	# Use the computed label position (same as _draw_transition_label)
	var canvas_center := vt.label_position
	var padding := 3.0
	var canvas_width := (total_width + padding * 2) / _zoom
	var canvas_height := (label_height + padding * 2) / _zoom

	return Rect2(
		canvas_center.x - canvas_width / 2.0,
		canvas_center.y - canvas_height / 2.0,
		canvas_width,
		canvas_height
	)


# ----- Coordinate Transforms -----

## Converts a point from canvas coordinates to screen coordinates.
func _canvas_to_screen(canvas_pos: Vector2) -> Vector2:
	return canvas_pos * _zoom + _pan_offset


## Converts a rect from canvas coordinates to screen coordinates.
func _canvas_to_screen_rect(canvas_rect: Rect2) -> Rect2:
	return Rect2(
		_canvas_to_screen(canvas_rect.position),
		canvas_rect.size * _zoom
	)


## Converts a point from screen coordinates to canvas coordinates.
func _screen_to_canvas(screen_pos: Vector2) -> Vector2:
	return (screen_pos - _pan_offset) / _zoom


## Checks if a screen-space rect is visible (intersects the viewport).
func _is_rect_visible(screen_rect: Rect2) -> bool:
	var viewport := Rect2(Vector2.ZERO, size)
	return viewport.intersects(screen_rect)


## Gets the bounding rect of a path in screen coordinates.
func _get_path_bounds(path: PackedVector2Array) -> Rect2:
	if path.is_empty():
		return Rect2()

	var min_x := path[0].x
	var min_y := path[0].y
	var max_x := path[0].x
	var max_y := path[0].y

	for point in path:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)

	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


## Checks if a point is near any segment of a path.
func _point_near_path(point: Vector2, path: PackedVector2Array, threshold: float) -> bool:
	for i in range(path.size() - 1):
		if _point_to_segment_distance(point, path[i], path[i + 1]) < threshold:
			return true
	return false


## Calculates the distance from a point to a line segment.
func _point_to_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := p - a
	var ab_len_sq := ab.dot(ab)

	if ab_len_sq < 0.0001:
		return p.distance_to(a)

	var t := clamp(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return p.distance_to(closest)
