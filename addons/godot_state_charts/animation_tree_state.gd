@tool
@icon("animation_tree_state.svg")
class_name AnimationTreeState
extends AtomicState


## Animation tree that this state will use.
@export_node_path("AnimationTree") var animation_tree:NodePath:
	set(value):
		animation_tree = value
		update_configuration_warnings()


var _animation_tree_state_machine:AnimationNodeStateMachinePlayback

func _ready():

	var the_tree = get_node_or_null(animation_tree)

	if is_instance_valid(the_tree):
		var state_machine = the_tree.get("parameters/playback") 
		if state_machine is AnimationNodeStateMachinePlayback:
			_animation_tree_state_machine = state_machine
		else:
			push_error("The animation tree does not have a state machine as root node. This node will not work.")
	else:
		push_error("The animation tree is invalid. This node will not work.")


func _state_enter(expect_transition:bool = false):
	super._state_enter()

	if not is_instance_valid(_animation_tree_state_machine):
		return

	# mirror this state to the animation tree
	_animation_tree_state_machine.travel(name)


func _get_configuration_warnings():
	var warnings = super._get_configuration_warnings()

	if animation_tree.is_empty():
		warnings.append("No animation tree is set.")
	elif get_node_or_null(animation_tree) == null:
		warnings.append("The animation tree path is invalid.")

	return warnings
