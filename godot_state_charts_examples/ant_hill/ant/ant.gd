extends CharacterBody2D

signal clicked(node:Node2D)

@export var marker_scene:PackedScene

## The navigation agent we use.
@onready var navigation_agent:NavigationAgent2D = $NavigationAgent2D

## The state chart
@onready var state_chart:StateChart = $StateChart

## Set of close food markers
var food_markers:Dictionary = {}

## Set of close nest markers
var nest_markers:Dictionary = {}

## Set of food nearby
var food:Dictionary = {}

## The nest, if nearby
var nest:Node2D = null

## The currently carried food
var carried_food:Node = null

const SEGMENT_LENGTH = 150

func _ready():
	# start the state chart
	state_chart.send_event.call_deferred("initialized")


## Called when we are seeking for food and need a new target.
func _on_idle_seeking_food():

	var current_position := get_global_position()

	# if we have food nearby grab it
	if food.size() > 0:
		state_chart.send_event("food_detected")
		return

	var target_position := Vector2()
	# if we have food markers nearby travel into the general direction of the closest one points
	if food_markers.size() > 0:
		var closest_food_marker := _find_closest(food_markers.keys(), current_position)
		var direction = Vector2.RIGHT.rotated(closest_food_marker.get_rotation())
		target_position = current_position + (direction * SEGMENT_LENGTH)

	# otherwise or if we couldn't reach the last target position, pick a random 
	# direction
	if food_markers.size() == 0 or not navigation_agent.is_target_reachable():
		# otherwise pick a random position in a radius of SEGMENT_LENGTH pixels
		# first calculate a random angle in radians
		var random_angle := randf() * 2 * PI
		# then calculate the x and y components of the vector
		var random_x := cos(random_angle) * SEGMENT_LENGTH
		var random_y := sin(random_angle) * SEGMENT_LENGTH

		# add the random vector to the current position
		target_position = current_position + Vector2(random_x, random_y)
	

	navigation_agent.set_target_position(target_position)
	state_chart.set_expression_property("target_position", target_position)
	state_chart.send_event("destination_set")


## Called when we have found food nearby and want to go to it
func _on_food_detected():
	# set the target position to the closest food
	var closest_food_position = _find_closest(food.keys(), get_global_position()).global_position
	navigation_agent.set_target_position(closest_food_position)


## Called when we arrived at the food and want to pick it up
func _on_food_reached():
	var closest_food = _find_closest(food.keys(), get_global_position())
	if not is_instance_valid(closest_food):
		# some other ant must have picked it up
		state_chart.send_event("food_vanished")
		return
		
	closest_food.get_parent().remove_child(closest_food)
	carried_food = closest_food
	# remove it from the food set
	food.erase(closest_food)
	# it's collected, so remove it from the food group
	closest_food.remove_from_group("food")
	# add it to our ant so it moves with us
	add_child(closest_food)
	closest_food.position = Vector2.ZERO
	closest_food.scale = Vector2(0.5, 0.5)
	
	# place a marker pointing to the food (0 means point into the current direction)
	var marker = _place_marker(Marker.MarkerType.FOOD, global_position, 0)
	food_markers[marker] = true

	# notify the state chart that we picked up food
	state_chart.send_event("food_picked_up")
	
 

## Called when we are returning home and need a new target.
func _on_idle_returning_home():
	var current_position := get_global_position()

	# if the nest is nearby, drop off the food
	if nest != null:
		state_chart.send_event("nest_detected")
		return 

	var target_position := Vector2()
	# if we have nest markers nearby travel into the general direction of the closest one points
	if nest_markers.size() > 0:
		# refresh them
		for marker in nest_markers.keys():
			marker.refresh()
			
		var closest_nest_marker := _find_closest(nest_markers.keys(), current_position)
		var direction = Vector2.RIGHT.rotated(closest_nest_marker.get_rotation()) 
		target_position = current_position + (direction * SEGMENT_LENGTH)
	
	# if we have no nest markers or the navigation agent couldn't reach
	# the position of the last target pick a random direction
	if nest_markers.size() == 0 or not navigation_agent.is_target_reachable():
		var random_angle := randf() * 2 * PI
		# then calculate the x and y components of the vector
		var random_x := cos(random_angle) * SEGMENT_LENGTH
		var random_y := sin(random_angle) * SEGMENT_LENGTH

		# add the random vector to the current position
		target_position = current_position + Vector2(random_x, random_y)

	navigation_agent.set_target_position(target_position)
	state_chart.set_expression_property("target_position", target_position)
	state_chart.send_event("destination_set")
	return

## Called when we are returning home and detected the nest
func _on_nest_detected():
	# travel to the nest
	navigation_agent.set_target_position(nest.global_position)
	state_chart.set_expression_property("target_position", nest.global_position)


## Called when we have arrived at the nest and want to drop off the food
func _on_nest_reached():
	# drop off the food
	carried_food.get_parent().remove_child(carried_food)
	carried_food.queue_free()
	carried_food = null
	# notify the state chart that we dropped off the food
	state_chart.send_event("food_dropped")


## Called while travelling to a destination
func _on_travelling_state_physics_processing(_delta):
	# get the next position on the path
	var path_position = navigation_agent.get_next_path_position()
	# and move towards it
	velocity = (path_position - get_global_position()).normalized() * navigation_agent.max_speed
	look_at(path_position)
	move_and_slide()


func _on_input_event(_viewport, event, _shape_idx):
	# if the left mouse button is up emit the clicked signal
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == false:
		# print("clicked")
		clicked.emit(self)


## Called when the ant is sensing something nearby.
func _on_sensor_area_area_entered(area:Area2D):
	var node = area
	if area.has_meta("owner"):
		node = area.get_node(area.get_meta("owner"))


	if node.is_in_group("marker"):
		# it's a marker
		if node.is_in_group("food"):
			food_markers[node] = true
		elif node.is_in_group("nest"):
			nest_markers[node] = true
	elif node.is_in_group("food"):
		# it's food
		food[node] = true
	elif node.is_in_group("nest"):
		# it's the nest
		nest = node

	state_chart.set_expression_property("nest_markers", nest_markers.size())
	state_chart.set_expression_property("food_markers", food_markers.size())



func _on_sensor_area_area_exited(area:Area2D):
	var node = area
	if area.has_meta("owner"):
		node = area.get_node(area.get_meta("owner"))
	
	if node.is_in_group("marker"):
		# it's a marker
		if node.is_in_group("food"):
			food_markers.erase(node)
		elif node.is_in_group("nest"):
			nest_markers.erase(node)
	elif node.is_in_group("food"):
		# it's food
		food.erase(node)
	elif node.is_in_group("nest"):
		# it's the nest
		nest = null
		
	state_chart.set_expression_property("nest_markers", nest_markers.size())
	state_chart.set_expression_property("food_markers", nest_markers.size())
	



## Finds the closest position to the given position from the given list of nodes.
func _find_closest(targets:Array, from:Vector2) -> Node2D:
	var shortest_distance := 99999999.00
	var result = null

	for target in targets:
		var distance := from.distance_squared_to(target.get_global_position())
		if distance < shortest_distance:
			shortest_distance = distance
			result = target
	
	return result


## Places a marker of the given type at the given position	
func _place_marker(type:Marker.MarkerType, target_position:Vector2, offset:float = PI) -> Marker:
	var marker = marker_scene.instantiate()
	marker.initialize(type)
	# add to the tree on our parent
	get_parent().add_child.call_deferred(marker)
	# set the position to our current position
	marker.set_global_position(target_position)
	# set the marker rotation to look opposite to the direction we are facing
	marker.set_rotation(get_rotation() + offset)
	return marker
	

func _place_nest_marker():
	# if there are already nest markers around, just refresh them
	if nest_markers.size() > 0:
		for marker in nest_markers:
			marker.refresh()
	else:
		# otherwise place a new one
		_place_marker(Marker.MarkerType.NEST, global_position)


func _place_food_marker():
	_place_marker(Marker.MarkerType.FOOD, global_position)


func _maintenance(_delta):
	# remove all markers which are no longer valid
	for marker in food_markers.keys():
		if not is_instance_valid(marker):
			food_markers.erase(marker)
			
	for marker in nest_markers.keys():
		if not is_instance_valid(marker):
			nest_markers.erase(marker)
		
		
