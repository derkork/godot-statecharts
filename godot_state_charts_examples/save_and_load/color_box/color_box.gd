class_name ColorBox extends Container

var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]

@export var color: Color = colors[0]
@export var box_id: String = "box-1"
@export var chart : StateChart = null
@export var compound_state: CompoundState = null
@export var red_state: StateChartState = null
@export var green_state: StateChartState = null
@export var blue_state: StateChartState = null

var _time_in_state: float = 0.0
var _label: Label = null
var _timer: Label = null
var _transition_timer: Label = null


func _ready() -> void:
	_label = find_child("ID")
	_label.text = box_id

	_timer = find_child("Timer")
	_timer.text = str(_time_in_state)

	_transition_timer = find_child("TransitionTimer")
	_transition_timer.text = "Time Remaining: N/A"

	red_state.state_entered.connect(_on_red_state_entered)
	green_state.state_entered.connect(_on_green_state_entered)
	blue_state.state_entered.connect(_on_blue_state_entered)

	compound_state.state_processing.connect(_on_state_processing)
	red_state.transition_pending.connect(_on_transition_pending)
	green_state.transition_pending.connect(_on_transition_pending)
	blue_state.transition_pending.connect(_on_transition_pending)


func _on_red_state_entered() -> void:
	color = colors[0]
	_update_state(color)

func _on_green_state_entered() -> void:
	color = colors[1]
	_update_state(color)

func _on_blue_state_entered() -> void:
	color = colors[2]
	_update_state(color)

func _update_state(new_color: Color, time_in_state: float = 0.0, transition_time_remaining: float = 0.0) -> void:
	_time_in_state = time_in_state
	color = new_color
	if transition_time_remaining > 0.0:
		_transition_timer.text = "Time Remaining: %.1f" % transition_time_remaining
	else:
		_transition_timer.text = "Time Remaining: N/A"
	find_child("ColorRect").color = color


func _on_state_processing(delta: float) -> void:
	_time_in_state += delta
	_timer.text = "Time in State: %.1f" % _time_in_state

func _on_transition_pending(_initial_delay: float, remaining_delay: float) -> void:
	_transition_timer.text = "Time Remaining: %.1f" % remaining_delay


func _on_button_pressed() -> void:
	chart.send_event("%s-click" % box_id)


func save_state() -> SerializedColorBox:
	var serialized_color_box: SerializedColorBox = SerializedColorBox.new()
	serialized_color_box.box_id = box_id
	serialized_color_box.color = color
	serialized_color_box.time_in_state = _time_in_state
	print("Saving state for %s" % box_id)
	print(JSON.stringify(serialized_color_box, "\t"))
	return serialized_color_box


func load_state(state: SerializedColorBox) -> void:
	print("Loading state for %s" % box_id)
	print(JSON.stringify(state, "\t"))

	color = state.color
	_time_in_state = state.time_in_state
	_update_state(color, _time_in_state)
