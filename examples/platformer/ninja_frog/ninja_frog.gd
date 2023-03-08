extends CharacterBody2D

@export var state_chart:StateChart
@export var animation_tree:AnimationTree

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation_state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")


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
		state_chart.send_event("grounded")
		velocity.y = 0
	else:
		## apply gravity
		velocity.y += gravity * delta
		state_chart.send_event("airborne")

	# let the state machine know if we are moving or not
	if velocity.length_squared() <= 0.005:
		state_chart.send_event("idle")
	else:
		state_chart.send_event("moving")

	# set the velocity to the animation tree, so it can blend between animations
	animation_tree["parameters/Idle/blend_position"] = velocity.x
	animation_tree["parameters/Move/blend_position"] = velocity
	animation_tree["parameters/DoubleJump/blend_position"] = velocity.x

	
		
## Called in states that allow jumping, we process jumps only in these.
func _on_jump_enabled_state_physics_processing(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		state_chart.send_event("jump")



func _on_double_jump_state_event_received(event:StringName):
	# if we get an event "jump" while in the double jump state we play the double jump animation
	if event == "jump":
		print("playing double jump")
		animation_state_machine.travel("DoubleJump")
