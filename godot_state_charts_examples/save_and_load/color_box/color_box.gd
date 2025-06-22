class_name ColorBox
extends Container

## The three colors that this box can have.
const COLORS: Array[Color] = [Color.DARK_RED, Color.FOREST_GREEN, Color.CORNFLOWER_BLUE]
## Emitted when someone presses the button
signal color_change_requested()
## The ID of this box. Used for saving.
@export var box_id: StringName

## The color rect for the background color
@onready var _color_rect: ColorRect = %ColorRect
## Label showing the time we're in the current state
@onready var _time_in_state_label: Label = %TimeInStateLabel
## Label showing the pending transition time
@onready var _transition_time_label: Label = %TransitionTimeLabel

var _time_in_state: float = 0.0
var _current_color_index: int = 0


func _ready():
	# emit the signal when the button is pressed
	%Button.pressed.connect(func(): color_change_requested.emit())
	# set the id
	%IdLabel.text = box_id
	# and initialize the color
	_switch_to(0)

## Called when this box should switch to red.
func switch_to_red():
	_switch_to(0)

	
## Called when this box should switch to green.
func switch_to_green():
	_switch_to(1)

## Called when this box should switch to blue.
func switch_to_blue():
	_switch_to(2)


func _switch_to(index: int):
	_current_color_index = index
	_color_rect.color = COLORS[index]
	_transition_time_label.text = ""
	_time_in_state = 0

## Called every frame while a color change is pending
func show_pending(_initial_delay: float, remaining_delay: float):
	_transition_time_label.text = "Time Remaining: %.1f" % remaining_delay


func _physics_process(delta):
	_time_in_state += delta
	_time_in_state_label.text = "Time in State: %.1f" % _time_in_state


func save_state() -> SerializedColorBox:
	var result: SerializedColorBox = SerializedColorBox.new()
	result.box_id = box_id
	result.color_index = _current_color_index
	result.time_in_state = _time_in_state
	return result


func load_state(state: SerializedColorBox) -> void:
	_switch_to(state.color_index)
	_time_in_state = state.time_in_state
