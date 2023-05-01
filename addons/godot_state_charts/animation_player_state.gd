@tool
@icon("animation_player_state.svg")
class_name AnimationPlayerState
extends AtomicState

## Animation player that this state will use.
@export_node_path("AnimationPlayer") var animation_player: NodePath:
	set(value):
		animation_player = value
		update_configuration_warnings()

@export var custom_blend: float = -1.0

@export var custom_speed: float = 1.0

@export var from_end: bool = false

var _animation_player: AnimationPlayer

func _ready():
	var the_player = get_node_or_null(animation_player)

	if is_instance_valid(the_player):
		_animation_player = the_player
	else:
		push_error("The animation player is invalid. This node will not work.")

func _state_enter(expect_transition: bool = false):
	super._state_enter()

	if not is_instance_valid(_animation_player):
		return

	if _animation_player.current_animation == name and _animation_player.is_playing():
		return

	_animation_player.play(name, custom_blend, custom_speed, from_end)

func _get_configuration_warnings():
	var warnings = super._get_configuration_warnings()

	if animation_player.is_empty():
		warnings.append("No animation player is set.")
	elif get_node_or_null(animation_player) == null:
		warnings.append("The animation player path is invalid.")

	return warnings
