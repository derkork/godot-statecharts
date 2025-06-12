extends Node2D


@export var chart : StateChart = null
@export var box_nodes: Array[ColorBox] = []


func save_state() -> void:
	var path = "user://save_resource.tres"
	var save_resource: SaveResource = SaveResource.new()
	save_resource.state_chart = StateChartSerializer.serialize(chart)
	for box in box_nodes:
		save_resource.boxes.append(box.save_state())
	ResourceSaver.save(save_resource, path)

func load_state() -> void:
	var path = "user://save_resource.tres"
	var save_resource: SaveResource = ResourceLoader.load(path, "SaveResource")
	StateChartSerializer.deserialize(save_resource.state_chart, chart)

	var box_node_hash : Dictionary = {}
	for node in box_nodes:
		box_node_hash[node.box_id] = node

	for box_resource in save_resource.boxes:
		var color_box: ColorBox = box_node_hash[box_resource.box_id]
		color_box.load_state(box_resource)


func _on_save_pressed() -> void:
	save_state()


func _on_load_pressed() -> void:
	load_state()
