extends CharacterBody2D

# We can move 100 pixels per second
const SPEED = 100.0

# We recover 20 stamina per second
const RECOVER_RATE = 20.0

@onready var state_chart:StateChart = %StateChart
@onready var animation_player = %AnimationPlayer

var stamina:float = 100

	

### WALKING CONTROL STATES

# In the "Can Walk" state we can walk around and lose stamina.
func _on_can_walk_state_physics_processing(delta):
	# Get the direction
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Calculate velocity
	velocity = direction * SPEED
	
	
	# if we moved, subtract stamina
	if velocity.length() > 0:
		stamina = max(0, stamina - RECOVER_RATE * delta)
	else:
	# else add it.
		stamina = min(100, stamina + RECOVER_RATE * delta)
		
	if stamina <= 0:
		state_chart.send_event("exhausted")
	
	move_and_slide()

# If our stamina hits 0, we enter the "Needs rest" state which
# only allows us to recover stamina.
func _on_needs_rest_state_physics_processing(delta):
	stamina = min(100, stamina + RECOVER_RATE * delta)

### ANIMATION CONTROL STATES
func _on_pulsating_red_state_entered():
	animation_player.play("pulsate")

func _on_normal_state_entered():
	animation_player.play("RESET")
