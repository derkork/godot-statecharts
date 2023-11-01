extends Node2D

@onready var state_chart: StateChart = $StateChart
var property_name: String = "b_property"
var c_property: float

func _ready():
	set_process(false)

func _process(delta):
	c_property = c_property + delta
	state_chart.set_expression_property(property_name, c_property)

func _on_b_state_entered():
	set_process(true)


func _on_b_state_exited():
	c_property = 0
	state_chart.set_expression_property(property_name, c_property)
	set_process(false)
