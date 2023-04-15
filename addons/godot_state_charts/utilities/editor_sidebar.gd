@tool
extends Control

var selected_node:Node
var interface:EditorInterface

@onready var selected_node_line_edit:LineEdit = %SelectedNodeLineEdit

@onready var add_label:Label = %AddLabel
@onready var add_node_name_line_edit:LineEdit = %AddNodeNameLineEdit
@onready var add_grid_container:GridContainer = %AddGridContainer

const animation_tree_state_script = preload("res://addons/godot_state_charts/animation_tree_state.gd")
const atomic_state_script = preload("res://addons/godot_state_charts/atomic_state.gd")
const compound_state_script = preload("res://addons/godot_state_charts/compound_state.gd")
const history_state_script = preload("res://addons/godot_state_charts/history_state.gd")
const parallel_state_script = preload("res://addons/godot_state_charts/parallel_state.gd")
const transition_script = preload("res://addons/godot_state_charts/transition.gd")

func set_interface(__interface:EditorInterface):
	interface = __interface

func change_selected_node(node):
	if(
		# StateChart must have exactly one child
		(node is StateChart \
		and node.get_child_count() == 0) \
	or node is CompoundState\
	or node is ParallelState):
		_toggle_add_visible(true)
		_toggle_states_visible(true)
	elif node is AtomicState:
		_toggle_add_visible(true)
		_toggle_states_visible(false)
	else:
		_toggle_add_visible(false)

	selected_node = node
	selected_node_line_edit.text = node.name

func _toggle_add_visible(is_visible:bool):
	add_label.visible = is_visible
	add_node_name_line_edit.visible = is_visible
	add_grid_container.visible = is_visible

func _toggle_states_visible(is_visible:bool):
	for btn in add_grid_container.get_children():
		if btn.is_in_group("statebutton"):
			btn.visible = is_visible

func _get_node_name(default) -> String:
	var nodename:String = add_node_name_line_edit.text
	if nodename.length() == 0:
		return default
	else:
		return nodename

func create_node(script:GDScript,default_node_name):
	var node:Node = script.new()
	selected_node.add_child(node)
	node.owner = selected_node.get_tree().edited_scene_root
	node.name = _get_node_name(default_node_name)
	interface.edit_node(node)

#
## Buttons
#

func _on_atomic_state_pressed():
	create_node(atomic_state_script,"AtomicState")

func _on_compound_state_pressed():
	create_node(compound_state_script,"CompoundState")

func _on_parallel_state_pressed():
	create_node(parallel_state_script,"ParallelState")

func _on_history_state_pressed():
	create_node(history_state_script,"HistoryState")

func _on_transition_pressed():
	create_node(transition_script,"Transition")

func _on_animation_tree_state_pressed():
	create_node(animation_tree_state_script,"AnimationTreeState")

###



func _on_selected_node_line_edit_text_changed(new_text):
	selected_node.name = new_text


func _on_node_duplicate_pressed():
#	var duplicate_node = selected_node.duplicate()
	var parent = selected_node.get_parent()
	var duplicate_node = duplicate_recursive(selected_node,parent)
	if parent == null:
		return
#	parent.add_child(duplicate_node)
#	duplicate_node.owner = selected_node.get_tree().edited_scene_root
#	duplicate_node.name = selected_node.name
	interface.edit_node(duplicate_node)

func duplicate_recursive(node:Node,parent:Node) -> Node:
	var duplicate_node := node.duplicate(
		DUPLICATE_SIGNALS|\
		DUPLICATE_GROUPS|\
		DUPLICATE_SCRIPTS|\
		DUPLICATE_USE_INSTANTIATION
	)
	parent.add_child(duplicate_node)
	duplicate_node.name = node.name
	for child in node.get_children():
		var duplicate_child := duplicate_recursive(child, duplicate_node)
		duplicate_child.name = child.name
	duplicate_node.owner = parent.get_tree().edited_scene_root
	return duplicate_node

func _on_node_remove_pressed():
	selected_node.get_parent().remove_child(selected_node)
	selected_node.queue_free()
