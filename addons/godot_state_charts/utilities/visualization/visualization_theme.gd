@tool
## Provides theme-aware colors and styling constants for the state chart visualization.
## All colors are derived from the Godot editor theme to ensure readability in both
## light and dark themes. State types are distinguished by tinting the base color
## rather than using hardcoded colors.
extends RefCounted


# ----- Size Constants -----
# These define the visual proportions of the state chart diagram.

## Minimum width for any state rectangle. Ensures labels remain readable.
const MIN_STATE_WIDTH: float = 100.0

## Minimum height for any state rectangle.
const MIN_STATE_HEIGHT: float = 50.0

## Space between child states within a composite state.
const CHILD_SPACING: float = 15.0

## Padding inside composite states between their border and children.
## Also provides space for the state's label at the top.
const STATE_PADDING: float = 15.0

## Extra vertical space at the top of composite states for the label.
const LABEL_HEIGHT: float = 25.0

## Corner radius for rounded state rectangles.
const CORNER_RADIUS: float = 6.0

## Width of state border lines.
const BORDER_WIDTH: float = 2.0

## Width of transition arrow lines.
const TRANSITION_LINE_WIDTH: float = 1.5

## Size of the arrowhead at the end of transitions.
const ARROWHEAD_SIZE: float = 10.0

## Radius of the initial state indicator circle.
const INITIAL_INDICATOR_RADIUS: float = 5.0

## Font size for state labels.
const STATE_LABEL_FONT_SIZE: int = 14

## Font size for transition event labels.
const TRANSITION_LABEL_FONT_SIZE: int = 12


# ----- Color Functions -----
# All colors are derived from the editor theme to support light/dark modes.

## Returns the fill color for a state based on its type.
## The color is computed by tinting the editor's base color with a type-specific hue.
## This ensures states are visually distinct while remaining readable in any theme.
static func get_state_fill_color(control: Control, state_type: String) -> Color:
	var base_color := _get_base_color(control)
	match state_type:
		"atomic":
			return base_color.lerp(Color(0.4, 0.6, 0.9), 0.25)  # Blue tint
		"compound":
			return base_color.lerp(Color(0.4, 0.8, 0.5), 0.25)  # Green tint
		"parallel":
			return base_color.lerp(Color(0.95, 0.6, 0.3), 0.35)  # Stronger orange tint
		"history":
			return base_color.lerp(Color(0.7, 0.5, 0.9), 0.25)  # Purple tint
	return base_color


## Returns the border color for a state, derived from its fill color.
static func get_state_border_color(control: Control, state_type: String) -> Color:
	return get_state_fill_color(control, state_type).darkened(0.3)


## Returns the color for text labels (state names, event names).
static func get_font_color(control: Control) -> Color:
	return control.get_theme_color(&"font_color", &"Editor")


## Returns the color for transition arrows.
static func get_transition_color(control: Control) -> Color:
	# Use a slightly muted version of the font color for arrows
	return get_font_color(control).lerp(_get_base_color(control), 0.3)


## Returns the color for the initial state indicator arrow.
static func get_initial_indicator_color(control: Control) -> Color:
	# Use a green tint that works in both light and dark themes
	var base := _get_base_color(control)
	return base.lerp(Color(0.2, 0.7, 0.3), 0.7)


## Returns the color for selection highlighting.
static func get_selection_color(control: Control) -> Color:
	# Use the editor's accent/selection color if available
	return control.get_theme_color(&"accent_color", &"Editor")


## Returns the background color for the canvas.
static func get_background_color(control: Control) -> Color:
	return control.get_theme_color(&"dark_color_2", &"Editor")


## Returns the default font from the editor theme.
static func get_font(control: Control) -> Font:
	return control.get_theme_font(&"font", &"Label")


## Returns the bold font from the editor theme.
static func get_bold_font(control: Control) -> Font:
	# Try to get the bold font, fall back to regular if not available
	var bold := control.get_theme_font(&"bold", &"EditorFonts")
	if bold != null:
		return bold
	return get_font(control)


## Returns an italic font by applying a slant transform to the regular font.
## EditorFonts doesn't include italic variants, so we create one using FontVariation.
static func get_italic_font(control: Control) -> Font:
	var base_font := get_font(control)
	var italic := FontVariation.new()
	italic.base_font = base_font
	# Apply an italic slant (positive values slant right)
	italic.variation_transform = Transform2D(Vector2(1, 0.2), Vector2(0, 1), Vector2.ZERO)
	return italic


## Returns a bold-italic font by applying a slant transform to the bold font.
static func get_bold_italic_font(control: Control) -> Font:
	var base_font := get_bold_font(control)
	var bold_italic := FontVariation.new()
	bold_italic.base_font = base_font
	# Apply an italic slant (positive values slant right)
	bold_italic.variation_transform = Transform2D(Vector2(1, 0.2), Vector2(0, 1), Vector2.ZERO)
	return bold_italic


## Returns the monospace font from the editor theme.
## This is the same font used in the script editor.
static func get_mono_font(control: Control) -> Font:
	var mono := control.get_theme_font(&"source", &"EditorFonts")
	if mono != null:
		return mono
	# Fallback
	mono = control.get_theme_font(&"output_source", &"EditorFonts")
	if mono != null:
		return mono
	return get_font(control)


# ----- Private Helpers -----

## Gets the editor's base color, which adapts to light/dark theme.
static func _get_base_color(control: Control) -> Color:
	return control.get_theme_color(&"base_color", &"Editor")
