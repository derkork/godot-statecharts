extends Node2D

## Path where we save our "game". This saved resource
## contains the state of the state chart itself and
## any other game specific state we want to save.
const SAVE_PATH: StringName = "user://save_resource.tres"

@onready var _state_chart: StateChart = %StateChart

var _boxes: Array[ColorBox]


func _ready():
	# grab all color boxes
	_boxes.assign(get_tree().get_nodes_in_group("colorbox"))
	# send an event whenever a box requests a color change
	for box in _boxes:
		box.color_change_requested.connect(func(): _state_chart.send_event(box.box_id + "-click"))


## Called when the "Save" button is pressed.
func save_state() -> void:
	var save_resource: SaveResource = SaveResource.new()
	save_resource.state_chart = StateChartSerializer.serialize(_state_chart)
	for box in _boxes:
		save_resource.boxes.append(box.save_state())

	ResourceSaver.save(save_resource, SAVE_PATH)

## Called when the "Load" button is pressed.
func load_state() -> void:
	var save_resource: SaveResource = ResourceLoader.load(SAVE_PATH)
	## restore the state of the state chart
	StateChartSerializer.deserialize(save_resource.state_chart, _state_chart)

	# make a lookup table for the boxes
	var box_lut: Dictionary = {}
	for node in _boxes:
		box_lut[node.box_id] = node

	# load the state of each box
	for box_resource in save_resource.boxes:
		var color_box: ColorBox = box_lut[box_resource.box_id]
		color_box.load_state(box_resource)

