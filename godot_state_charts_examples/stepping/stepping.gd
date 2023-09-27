extends Node2D


@onready var _add_coal_to_drill_button:Button = %AddCoalToDrillButton
@onready var _coal_available_label:Label = %CoalAvailableLabel
@onready var _coal_in_drill_label:Label = %CoalInDrillLabel
@onready var _state_chart:StateChart = %StateChart


var _coal_available:int = 0:
	set(value):
		_coal_available = value
		# update the UI when this changes
		_coal_available_label.text = str(_coal_available)
		_add_coal_to_drill_button.disabled = _coal_available == 0
		
var _coal_in_drill:int = 0:
	set(value):
		_coal_in_drill = value
		# update the UI when this changes
		_coal_in_drill_label.text = str(_coal_in_drill)
		if _coal_in_drill == 0:
			# if there is no more coal in the drill send the 
			# coal_depleted event
			_state_chart.send_event("coal_depleted")
		else:
			# otherwise send the coal_available event
			_state_chart.send_event("coal_available")


func _ready():
	_coal_available = 1 # we start with 1 coal
	

func _on_add_coal_to_drill_button_pressed():
	# take one coal from the pile and put it into the generator
	_coal_available -= 1
	_coal_in_drill += 1
	

func _on_drill_has_coal_state_stepped():
	# when we are in this state, we produce 2 coal and consume one of the coal in
	# the drill
	_coal_available += 2
	_coal_in_drill -= 1


func _on_drill_has_no_coal_state_stepped():
	# when we are in this state, the drill has no coal so we just flash
	# the label red.
	_coal_in_drill_label.modulate = Color.RED
	create_tween().tween_property(_coal_in_drill_label, "modulate", Color.WHITE, 0.5)


func _on_next_round_button_pressed():
	# when the next round button is pressed we handle all currently active states
	_state_chart.step()


