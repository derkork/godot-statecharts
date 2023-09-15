extends CharacterBody2D

## Emitted when this node is clicked with a mouse 
signal clicked(node:Node2D)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var _state_chart: StateChart = $StateChart
@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _animation_state_machine: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/playback")

# Current facing direction (positive one is right, negative one is left)
var _facing_direction := 1.0

# In all states, move and slide and handle left/right movement and gravity.
func _physics_process(delta):

	# handle left/right movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# handle gravity
	if is_on_floor():
		_state_chart.send_event("grounded")
		velocity.y = 0
	else:
		## apply gravity
		velocity.y += gravity * delta
		_state_chart.send_event("airborne")

	# let the state machine know if we are moving or not
	if velocity.length_squared() <= 0.005:
		_state_chart.send_event("idle")
	else:
		_state_chart.send_event("moving")

	# update facing direction only when moving horizontaly
	if not is_zero_approx(velocity.x):
		_facing_direction = signf(velocity.x)

	# set the velocity to the animation tree, so it can blend between animations
	# _facing_direction "nudges" the parameters to avoid unwanted flipping when velocity is zero
	_animation_tree["parameters/Idle/blend_position"] = velocity.x + _facing_direction
	_animation_tree["parameters/Move/blend_position"] = velocity + Vector2(_facing_direction, 0.0)
	_animation_tree["parameters/DoubleJump/blend_position"] = velocity.x + _facing_direction

	
		
## Called in states that allow jumping, we process jumps only in these.
func _on_jump_enabled_state_physics_processing(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		_state_chart.send_event("jump")



func _on_double_jump_state_event_received(event:StringName):
	# if we get an event "jump" while in the double jump state we play the double jump animation
	if event == "jump":
		# print("playing double jump")
		_animation_state_machine.travel("DoubleJump")


func _on_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	# if the left mouse button is up emit the clicked signal
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == false:
			clicked.emit(self)
