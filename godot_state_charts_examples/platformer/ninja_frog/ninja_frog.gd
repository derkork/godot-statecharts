extends CharacterBody2D

## Emitted when this node is clicked with a mouse 
signal clicked(node:Node2D)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var _sprite: Sprite2D = $Sprite
@onready var _state_chart: StateChart = $StateChart
@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _animation_state_machine: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/playback")

# In all states, move and slide and handle left/right movement and gravity.
func _physics_process(delta):

	# handle left/right movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# flip the sprite. we do this before moving, so it flips
	# even if we stand at a wall
	if signf(velocity.x) != 0:
		_sprite.flip_h = velocity.x < 0

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

	# set the velocity to the animation tree, so it can blend between animations
	_animation_tree["parameters/Move/blend_position"] = signf(velocity.y)
	
		
## Called in states that allow jumping, we process jumps only in these.
func _on_jump_enabled_state_physics_processing(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		_state_chart.send_event("jump")


## Called when the jump transition is taken in the double-jump
## state. Only used to play the double jump animation.
func _on_double_jump_jump():
	_animation_state_machine.travel("DoubleJump")


func _on_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	# if the left mouse button is up emit the clicked signal
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == false:
			clicked.emit(self)

