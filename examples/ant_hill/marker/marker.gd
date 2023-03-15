class_name Marker
extends Node2D

## How long should the marker live for?
@export var lifetime_seconds:float = 30.0


var expired_time:float = 0


enum MarkerType {
	## A marker guiding towards food.
	FOOD,
	## A marker guiding towards a nest.
	NEST
}

func initialize(type:MarkerType):
	add_to_group("marker")
	match type:
		MarkerType.FOOD:
			modulate = Color.YELLOW
			add_to_group("food")
		MarkerType.NEST:
			modulate = Color.BROWN
			add_to_group("nest")


func _process(delta):
	expired_time += delta
	# Fade out the marker as it expires.
	modulate.a = max(0, 1 - (expired_time / lifetime_seconds))
	if expired_time > lifetime_seconds:
		queue_free()


func __draw():
	var offset = 0.0 if is_in_group("food") else PI
	var start_angle = - PI / 2 + offset
	var end_angle = PI / 2 + offset
	draw_arc(Vector2.ZERO, 30, start_angle, end_angle, 10, modulate, 1, true )
	