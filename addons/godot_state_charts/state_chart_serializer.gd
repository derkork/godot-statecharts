## Helper class for serializing and deserializing state charts.
class_name StateChartSerializer

## Serializes the given state chart and returns a serialized object that
## can be stored as part of a saved game.
static func serialize(state_chart: StateChart) -> SerializedStateChart:
	state_chart.freeze()
	var result := _serialize_chart(state_chart)
	state_chart.thaw()
	return result


## Deserializes the given serialized state chart into the given state chart. Returns a set of
## error messages. If the serialized state chart was no longer compatible with the current state
## chart, nothing will happen. The operation is successful when the returned array is emtpy.
static func deserialize(serialized_state_chart: SerializedStateChart, state_chart: StateChart) -> PackedStringArray:
	var error_messages: PackedStringArray = []
	_verify_chart_compatibility(serialized_state_chart, state_chart, error_messages)
	if not error_messages.is_empty():
		return error_messages

	state_chart.freeze()
	_deserialize_chart(serialized_state_chart, state_chart)
	state_chart.thaw()

	state_chart._run_queued_transitions()
	state_chart._run_changes()

	return error_messages


## Recursively builds a Resource representation of this state chart and it's children.
## This function is intended to be used for serializing into the desired format (such as a file or JSON)
## as needed for game saves or network transmission.
## This method assumes that the StateChart will be constructed and added to the tree prior
## to loading the resource. As such, it does not store data, such as Transitions, which will be
## created in the Node Tree.
static func _serialize_chart(state_chart: StateChart) -> SerializedStateChart:
	assert(state_chart != null, "tried to serialize a null chart.")

	var result: SerializedStateChart = SerializedStateChart.new()
	result.name = state_chart.name
	result.expression_properties = state_chart._expression_properties
	result.queued_events = state_chart._queued_events
	result.property_change_pending = state_chart._property_change_pending
	result.state_change_pending = state_chart._state_change_pending
	result.locked_down = state_chart._locked_down
	result.queued_transitions = state_chart._queued_transitions
	result.transitions_processing_active = state_chart._transitions_processing_active
	result.state = _serialize_state(state_chart._state)

	return result


## Loads a state chart from a resource. This will replace the current state chart's internal state with the one in the resource.
## Events and transitions will not be processed or queued during the load process.
## Loading assumes that the state chart states have already been instantiated into your node tree. This will
## update existing nodes in the tree, but not create new nodes that do not yet exist. Data for non-existent nodes
## will be discarded. If you want to create new nodes, you need to do so manually from the resource objects prior
## to calling this method.
static func _deserialize_chart(serialized_chart: SerializedStateChart, target: StateChart) -> void:
	assert(serialized_chart != null, "tried to deserialize a null serialized state chart.")
	assert(target != null, "tried to deserialize into a null state chart.")

	# load the state chart data
	target._expression_properties = serialized_chart.expression_properties
	target._queued_events = serialized_chart.queued_events
	target._property_change_pending = serialized_chart.property_change_pending
	target._state_change_pending = serialized_chart.state_change_pending
	target._locked_down = serialized_chart.locked_down
	target._queued_transitions = serialized_chart.queued_transitions
	target._transitions_processing_active = serialized_chart.transitions_processing_active

	# and all the states
	_deserialize_state(serialized_chart.state, target._state)


## Serializes the given state chart state into a serialized state chart state.
static func _serialize_state(state: StateChartState) -> SerializedStateChartState:
	assert(state != null, "tried to serialize a null state.")
	var result := SerializedStateChartState.new()
	result.name = state.name
	result.state_type = _type_for_state(state)
	result.active = state._state_active
	result.pending_transition_name = state._pending_transition.name if state._pending_transition != null else ""
	result.pending_transition_remaining_delay = state._pending_transition_remaining_delay
	result.pending_transition_initial_delay = state._pending_transition_initial_delay
	if state is HistoryState:
		result.history = state.history

	result.children = []

	for child in state.get_children():
		if child is StateChartState:
			result.children.append(_serialize_state(child))
	return result


## Deserializes a serialized state chart state into	a state chart state.
static func _deserialize_state(serialized_state: SerializedStateChartState, target: StateChartState) -> void:
	assert(serialized_state != null, "tried to deserialize a null serialized state.")
	assert(target != null, "tried to deserialize into a null state.")

	target._state_active = serialized_state.active

	if serialized_state.pending_transition_name != "":
		target._pending_transition = target.get_node(serialized_state.pending_transition_name)
	else:
		target._pending_transition = null

	target._pending_transition_remaining_delay = serialized_state.pending_transition_remaining_delay
	target._pending_transition_initial_delay = serialized_state.pending_transition_initial_delay
	if target is HistoryState:
		target.history = serialized_state.history

	for child_serialized_state in serialized_state.children:
		var child_state: StateChartState = target.get_node(NodePath(child_serialized_state.name))
		_deserialize_state(child_serialized_state, child_state)

	if target is CompoundState:
		# ensure _active_state is set to the currently active child
		if target._state_active:
			# find the currently active child
			for child in target.get_children():
				if child is StateChartState and child._state_active:
					target._active_state = child
					break


## Verify that the serialized state chart can actually be restored on the target state chart.
static func _verify_chart_compatibility(serialized_state_chart: SerializedStateChart, target: StateChart, error_messages: PackedStringArray) -> void:
	var message_prefix: String = "[%s]:" % [target.get_path()]
	if serialized_state_chart.version != 1:
		error_messages.append("%s Unsupported serialized state chart version %s != %s." % [message_prefix, serialized_state_chart.version, 1])

	_verify_state_compatiblity(serialized_state_chart.state, target._state, error_messages)


## Checks if the given serialized state can be restored on the given state.
static func _verify_state_compatiblity(serialized_state: SerializedStateChartState, target: StateChartState, error_messages: PackedStringArray) -> void:
	var message_prefix: String = "[%s]:" % [_get_state_path(target)]

	if serialized_state.name != target.name:
		error_messages.append("%s State name mismatch: %s != %s" % [message_prefix, target.name, serialized_state.name])

	if serialized_state.state_type != _type_for_state(target):
		error_messages.append("%s State type mismatch: %s != %s " % [message_prefix, _type_for_state(target), serialized_state.state_type])

	if not serialized_state.pending_transition_name.is_empty() \
	and target.get_node_or_null(serialized_state.pending_transition_name) == null:
		error_messages.append("%s Pending transition %s not found" % [message_prefix, serialized_state.pending_transition_name])

	var states_in_tree: Array[StringName] = []

	var states_in_serialized_version: Array[StringName] = []

	for child in target.get_children():
		if child is StateChartState:
			states_in_tree.append(child.name)

	for serialized_child in serialized_state.children:
		states_in_serialized_version.append(serialized_child.name)

		var child: Node = target.get_node_or_null(NodePath(serialized_child.name))
		if child == null:
			error_messages.append("%s Serialized state has child state %s but no such state exists in the tree." % [message_prefix, serialized_child.name])
		else:
			_verify_state_compatiblity(serialized_child, child, error_messages)

	var in_tree_but_missing_in_serialized: Array = states_in_tree.filter(func(it): return not states_in_serialized_version.has(it))
	for item in in_tree_but_missing_in_serialized:
		error_messages.append("%s Tree has child state %s but no such child state exists in the serialized state." % [message_prefix, str(item)])


## Returns an integer giving the state type.
static func _type_for_state(state: StateChartState) -> int:
	if state is AtomicState:
		return 0
	if state is CompoundState:
		return 1
	if state is ParallelState:
		return 2
	if state is HistoryState:
		return 3
	assert(false, "Unknown state type")
	return -1


## Returns the path from the state's chart to the state.
static func _get_state_path(state: StateChartState) -> String:
	if state == null or state._chart == null:
		return ""
	return str(state._chart.get_path_to(state))


## Serializes the given state chart to a network-safe PackedByteArray.
## This method converts the state chart to JSON, which is safe for network transmission
## as it does not serialize arbitrary objects or scripts (avoiding var_to_bytes_with_objects security risks).
## Returns a PackedByteArray that can be sent over the network via RPC.
static func serialize_to_bytes(state_chart: StateChart) -> PackedByteArray:
	var serialized := serialize(state_chart)
	var dict := _serialized_chart_to_dict(serialized)
	var json := JSON.stringify(dict)
	return json.to_utf8_buffer()


## Deserializes a state chart from a network-safe PackedByteArray.
## This method converts JSON bytes back to a SerializedStateChart object,
## then uses the existing deserialize() method to restore the state chart.
## Returns a set of error messages. If the serialized state chart was no longer
## compatible with the current state chart, nothing will happen. The operation
## is successful when the returned array is empty.
static func deserialize_from_bytes(bytes: PackedByteArray, state_chart: StateChart) -> PackedStringArray:

	# Check for empty byte array
	if bytes.is_empty():
		return ["Cannot deserialize empty byte array."]

	var json_string := bytes.get_string_from_utf8()

	# Check for invalid UTF-8 (results in empty string for non-empty bytes)
	if json_string.is_empty():
		return ["Failed to decode bytes as UTF-8."]

	var json := JSON.new()
	var parse_error := json.parse(json_string)

	if parse_error != OK:
		return ["Failed to parse JSON: %s" % json.get_error_message()]

	# Verify the parsed data is a dictionary
	if not json.data is Dictionary:
		return ["Invalid JSON structure: expected object at root."]

	var dict: Dictionary = json.data
	var error_messages: PackedStringArray = []

	# Validate the dictionary structure before conversion
	_validate_chart_dict(dict, error_messages)
	if not error_messages.is_empty():
		return error_messages

	var serialized := _dict_to_serialized_chart(dict, error_messages)
	if not error_messages.is_empty():
		return error_messages

	return deserialize(serialized, state_chart)


## Converts a SerializedStateChart to a plain Dictionary for JSON serialization.
static func _serialized_chart_to_dict(serialized: SerializedStateChart) -> Dictionary:
	return {
		"version": serialized.version,
		"name": serialized.name,
		"expression_properties": serialized.expression_properties,
		"queued_events": Array(serialized.queued_events),
		"property_change_pending": serialized.property_change_pending,
		"state_change_pending": serialized.state_change_pending,
		"locked_down": serialized.locked_down,
		"queued_transitions": serialized.queued_transitions,
		"transitions_processing_active": serialized.transitions_processing_active,
		"state": _serialized_state_to_dict(serialized.state) if serialized.state != null else null
	}


## Validates a chart dictionary has all required fields with correct types.
static func _validate_chart_dict(dict: Dictionary, error_messages: PackedStringArray) -> void:
	# Check required fields exist
	if not dict.has("version"):
		error_messages.append("Missing required field 'version' in serialized chart.")
	elif not (dict["version"] is int or dict["version"] is float): # json parser parses every number as float, so we need to accept that as well
		error_messages.append("Field 'version' must be an integer, got %s." % typeof(dict["version"]))

	if not dict.has("name"):
		error_messages.append("Missing required field 'name' in serialized chart.")
	elif not dict["name"] is String:
		error_messages.append("Field 'name' must be a string, got %s." % typeof(dict["name"]))

	if not dict.has("state"):
		error_messages.append("Missing required field 'state' in serialized chart.")
	elif dict["state"] == null:
		error_messages.append("Field 'state' cannot be null.")
	elif not dict["state"] is Dictionary:
		error_messages.append("Field 'state' must be an object, got %s." % typeof(dict["state"]))
	else:
		_validate_state_dict(dict["state"], "state", error_messages)

	# Validate optional fields have correct types if present
	if dict.has("expression_properties") and not dict["expression_properties"] is Dictionary:
		error_messages.append("Field 'expression_properties' must be an object.")

	if dict.has("queued_events") and not dict["queued_events"] is Array:
		error_messages.append("Field 'queued_events' must be an array.")

	if dict.has("property_change_pending") and not dict["property_change_pending"] is bool:
		error_messages.append("Field 'property_change_pending' must be a boolean.")

	if dict.has("state_change_pending") and not dict["state_change_pending"] is bool:
		error_messages.append("Field 'state_change_pending' must be a boolean.")

	if dict.has("locked_down") and not dict["locked_down"] is bool:
		error_messages.append("Field 'locked_down' must be a boolean.")

	if dict.has("queued_transitions") and not dict["queued_transitions"] is Array:
		error_messages.append("Field 'queued_transitions' must be an array.")

	if dict.has("transitions_processing_active") and not dict["transitions_processing_active"] is bool:
		error_messages.append("Field 'transitions_processing_active' must be a boolean.")


## Validates a state dictionary has all required fields with correct types.
static func _validate_state_dict(dict: Dictionary, path: String, error_messages: PackedStringArray) -> void:
	# Check required fields
	if not dict.has("name"):
		error_messages.append("Missing required field 'name' in %s." % path)
	elif not dict["name"] is String:
		error_messages.append("Field 'name' must be a string in %s, got %s." % [path, typeof(dict["name"])])

	if not dict.has("state_type"):
		error_messages.append("Missing required field 'state_type' in %s." % path)
	elif not (dict["state_type"] is int or dict["state_type"] is float): # json parser parses every number as float, so we need to accept that as well
		error_messages.append("Field 'state_type' must be an integer in %s, got %s." % [path, typeof(dict["state_type"])])
	else:
		var state_type: int = int(dict["state_type"])
		if state_type < 0 or state_type > 3:
			error_messages.append("Invalid state_type %d in %s. Must be 0 (Atomic), 1 (Compound), 2 (Parallel), or 3 (History)." % [state_type, path])

	if not dict.has("active"):
		error_messages.append("Missing required field 'active' in %s." % path)
	elif not dict["active"] is bool:
		error_messages.append("Field 'active' must be a boolean in %s, got %s." % [path, typeof(dict["active"])])

	if not dict.has("children"):
		error_messages.append("Missing required field 'children' in %s." % path)
	elif not dict["children"] is Array:
		error_messages.append("Field 'children' must be an array in %s, got %s." % [path, typeof(dict["children"])])
	else:
		# Validate each child
		var children: Array = dict["children"]
		for i in range(children.size()):
			var child = children[i]
			if not child is Dictionary:
				error_messages.append("Child at index %d must be an object in %s." % [i, path])
			else:
				var child_name: String = child.get("name", "child_%d" % i)
				_validate_state_dict(child, "%s.children[%s]" % [path, child_name], error_messages)

	# Validate optional fields have correct types if present
	if dict.has("pending_transition_name") and not dict["pending_transition_name"] is String:
		error_messages.append("Field 'pending_transition_name' must be a string in %s." % path)

	if dict.has("pending_transition_remaining_delay"):
		var delay = dict["pending_transition_remaining_delay"]
		if not (delay is int or delay is float):
			error_messages.append("Field 'pending_transition_remaining_delay' must be a number in %s." % path)

	if dict.has("pending_transition_initial_delay"):
		var delay = dict["pending_transition_initial_delay"]
		if not (delay is int or delay is float):
			error_messages.append("Field 'pending_transition_initial_delay' must be a number in %s." % path)

	if dict.has("history") and dict["history"] != null:
		if not dict["history"] is Dictionary:
			error_messages.append("Field 'history' must be an object in %s." % path)
		else:
			_validate_saved_state_dict(dict["history"], "%s.history" % path, error_messages)


## Validates a saved state dictionary has correct types.
static func _validate_saved_state_dict(dict: Dictionary, path: String, error_messages: PackedStringArray) -> void:
	if dict.has("child_states"):
		if not dict["child_states"] is Dictionary:
			error_messages.append("Field 'child_states' must be an object in %s." % path)
		else:
			for key in dict["child_states"]:
				var child = dict["child_states"][key]
				if not child is Dictionary:
					error_messages.append("Child state '%s' must be an object in %s." % [key, path])
				else:
					_validate_saved_state_dict(child, "%s.child_states[%s]" % [path, key], error_messages)

	if dict.has("pending_transition_name") and not dict["pending_transition_name"] is String:
		error_messages.append("Field 'pending_transition_name' must be a string in %s." % path)

	if dict.has("pending_transition_remaining_delay"):
		var delay = dict["pending_transition_remaining_delay"]
		if not (delay is int or delay is float):
			error_messages.append("Field 'pending_transition_remaining_delay' must be a number in %s." % path)

	if dict.has("pending_transition_initial_delay"):
		var delay = dict["pending_transition_initial_delay"]
		if not (delay is int or delay is float):
			error_messages.append("Field 'pending_transition_initial_delay' must be a number in %s." % path)

	if dict.has("history") and dict["history"] != null:
		if not dict["history"] is Dictionary:
			error_messages.append("Field 'history' must be an object in %s." % path)
		else:
			_validate_saved_state_dict(dict["history"], "%s.history" % path, error_messages)


## Converts a Dictionary back to a SerializedStateChart.
## Assumes validation has already been performed.
static func _dict_to_serialized_chart(dict: Dictionary, error_messages: PackedStringArray) -> SerializedStateChart:
	var result := SerializedStateChart.new()
	result.version = int(dict.get("version", 1))
	result.name = dict.get("name", "")
	result.expression_properties = dict.get("expression_properties", {})

	# Convert queued_events array back to Array[StringName]
	var queued_events_array: Array[StringName] = []
	for event in dict.get("queued_events", []):
		queued_events_array.append(StringName(event))
	result.queued_events = queued_events_array

	result.property_change_pending = dict.get("property_change_pending", false)
	result.state_change_pending = dict.get("state_change_pending", false)
	result.locked_down = dict.get("locked_down", false)

	# Convert queued_transitions array back to Array[Dictionary]
	var queued_transitions_array: Array[Dictionary] = []
	for transition_dict in dict.get("queued_transitions", []):
		queued_transitions_array.append(transition_dict)
	result.queued_transitions = queued_transitions_array

	result.transitions_processing_active = dict.get("transitions_processing_active", false)

	var state_dict = dict.get("state")
	result.state = _dict_to_serialized_state(state_dict, error_messages) if state_dict != null else null

	return result


## Converts a SerializedStateChartState to a plain Dictionary.
static func _serialized_state_to_dict(state: SerializedStateChartState) -> Dictionary:
	var children_array := []
	for child in state.children:
		children_array.append(_serialized_state_to_dict(child))
	
	return {
		"name": String(state.name),
		"state_type": state.state_type,
		"active": state.active,
		"pending_transition_name": state.pending_transition_name,
		"pending_transition_remaining_delay": state.pending_transition_remaining_delay,
		"pending_transition_initial_delay": state.pending_transition_initial_delay,
		"children": children_array,
		"history": _saved_state_to_dict(state.history) if state.history != null else null
	}


## Converts a Dictionary back to a SerializedStateChartState.
## Assumes validation has already been performed.
static func _dict_to_serialized_state(dict: Dictionary, error_messages: PackedStringArray) -> SerializedStateChartState:
	var result := SerializedStateChartState.new()
	result.name = StringName(dict.get("name", ""))
	result.state_type = int(dict.get("state_type", -1))
	result.active = dict.get("active", false)
	result.pending_transition_name = dict.get("pending_transition_name", "")
	result.pending_transition_remaining_delay = float(dict.get("pending_transition_remaining_delay", 0.0))
	result.pending_transition_initial_delay = float(dict.get("pending_transition_initial_delay", 0.0))

	# Convert children array
	var children: Array[SerializedStateChartState] = []
	for child_dict in dict.get("children", []):
		children.append(_dict_to_serialized_state(child_dict, error_messages))
	result.children = children

	# Convert history if present
	var history_dict = dict.get("history")
	result.history = _dict_to_saved_state(history_dict) if history_dict != null else null

	return result


## Converts a SavedState to a plain Dictionary.
static func _saved_state_to_dict(saved_state: SavedState) -> Dictionary:
	var child_states_dict := {}
	for key in saved_state.child_states:
		child_states_dict[String(key)] = _saved_state_to_dict(saved_state.child_states[key])
	
	return {
		"child_states": child_states_dict,
		"pending_transition_name": String(saved_state.pending_transition_name),
		"pending_transition_remaining_delay": saved_state.pending_transition_remaining_delay,
		"pending_transition_initial_delay": saved_state.pending_transition_initial_delay,
		"history": _saved_state_to_dict(saved_state.history) if saved_state.history != null else null
	}


## Converts a Dictionary back to a SavedState.
static func _dict_to_saved_state(dict: Dictionary) -> SavedState:
	var result := SavedState.new()
	
	# Convert child_states
	var child_states_dict: Dictionary = dict.get("child_states", {})
	for key in child_states_dict:
		result.child_states[StringName(key)] = _dict_to_saved_state(child_states_dict[key])
	
	result.pending_transition_name = NodePath(dict.get("pending_transition_name", ""))
	result.pending_transition_remaining_delay = dict.get("pending_transition_remaining_delay", 0.0)
	result.pending_transition_initial_delay = dict.get("pending_transition_initial_delay", 0.0)
	
	# Convert history if present
	var history_dict = dict.get("history")
	result.history = _dict_to_saved_state(history_dict) if history_dict != null else null
	
	return result
