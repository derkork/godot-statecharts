@tool
## Helper class for serializing/deserializing state information from the game
## into a format that can be used by the editor.

## State types that can be serialized
enum StateTypes {
	AtomicState = 1,
	CompoundState = 2,
	ParallelState = 3,
	AnimationPlayerState = 4,
	AnimationTreeState = 5
}

## Create an array from the given state information.
static func make_array( \
	## The owning chart
	chart:NodePath, \
	## Path of the state
	path:NodePath, \
	## Whether it is currently active
	active:bool, \
	## Whether a transition is currently pending for this state
	transition_pending:bool, \
	## The path of the pending transition if any.
	transition_path:NodePath, \
	## The remaining transition time for the pending transition if any.
	transition_time:float, \
	## The kind of state
	state:State \
) -> Array:
	return [ \
		chart, \
		_strip_common_prefix(path, chart), \
		active, \
		transition_pending, \
		_strip_common_prefix(transition_path, chart), \
		transition_time, \
		type_for_state(state) ]

## Get the state type for the given state.
static func type_for_state(state:State) -> StateTypes:
	if state is CompoundState:
		return StateTypes.CompoundState
	elif state is ParallelState:
		return StateTypes.ParallelState
	elif state is AnimationPlayerState:
		return StateTypes.AnimationPlayerState
	elif state is AnimationTreeState:
		return StateTypes.AnimationTreeState
	else:
		return StateTypes.AtomicState

## Accessors for the array.
static func get_chart(array:Array) -> NodePath:
	return array[0]

static func get_state(array:Array) -> NodePath:
	return array[1]

static func get_active(array:Array) -> bool:
	return array[2]

static func get_transition_pending(array:Array) -> bool:
	return array[3]

static func get_transition_path(array:Array) -> NodePath:
	return array[4]

static func get_transition_time(array:Array) -> float:
	return array[5]

static func get_state_type(array:Array) -> StateTypes:
	return array[6]

## Returns an icon for the state type of the given array.
static func get_state_icon(array:Array) -> Texture2D:
	var type = get_state_type(array)
	if type == StateTypes.AtomicState:
		return preload("../../atomic_state.svg")
	elif type == StateTypes.CompoundState:
		return preload("../../compound_state.svg")
	elif type == StateTypes.ParallelState:
		return preload("../../parallel_state.svg")
	elif type == StateTypes.AnimationPlayerState:
		return preload("../../animation_player_state.svg")
	elif type == StateTypes.AnimationTreeState:
		return preload("../../animation_tree_state.svg")
	else:
		return null

## Strips the common prefix from the given path.	
static func _strip_common_prefix(input:NodePath, other:NodePath) -> NodePath:
	var input_segments = input.get_name_count()
	var other_segments = other.get_name_count()
	
	var common_segments = 0
	for i in range(0, min(input_segments, other_segments)):
		if input.get_name(i) == other.get_name(i):
			common_segments += 1
		else:
			break
			
	var output = ""
	for i in range(common_segments, input_segments):
		output += input.get_name(i)
		if i + 1 < input_segments:
			output += "/"
		
	return NodePath(output)
