extends CharacterBody2D

const SPEED:float = 50.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _animation_player:AnimationPlayer = $AnimationPlayer

var _direction:Vector2

# When we enter walk state ...
func _on_walk_state_entered():
	# pick a random direction to walk in (360 degrees)
	_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	# and play the walk animation
	_animation_player.play("walk")
	# flip the sprite. since we keep this direction for as long as 
	# we are in the walk state, we don't need to do this per frame.
	_sprite.flip_h = _direction.x < 0


# While we are in walk state... 
func _on_walk_state_physics_processing(_delta):
	# set a new velocity
	velocity = _direction * SPEED
	# and move into the given direction
	move_and_slide()
	# and update scale
	rescale()
	
	
# When we enter idle state ...
func _on_idle_state_entered():
	# clear the direction
	_direction = Vector2.ZERO
	# and play the idle animation
	_animation_player.play("idle")
	# also rescale here in case we entered idle state first
	rescale()
	
	
func rescale():
	# scale the frog depending on its y position to achieve some pseudo-3d effect
	# this is hard-coded for resolution of this project which has 480 vertical pixels
	# so we assume 240 to be 100% size, 0 would be 50% size and 480 would be 150% size.
	var scale_factor = 1.0  + ((global_position.y - 240) / 480)
	scale = Vector2(scale_factor, scale_factor)	
	
	

