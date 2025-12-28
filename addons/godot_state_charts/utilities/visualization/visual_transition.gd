@tool
## Represents the visual layout data for a transition arrow in the state chart visualization.
##
## This class holds the computed arrow path and metadata needed to render a transition
## as a line with an arrowhead connecting two states. When multiple transitions exist
## between the same source and target states, they are grouped into a single visual
## with a combined label showing all transition conditions.
##
## For transitions with labels, the path goes through the label position, creating
## a bent arrow: source → label → target.
const VisualState = preload("visual_state.gd")
const VisualLabel = preload("visual_label.gd")

## The visual state where this transition originates.
## The arrow starts from the edge of this state's rectangle.
var source_state: VisualState = null

## The visual state where this transition leads to.
## The arrow ends at the edge of this state's rectangle with an arrowhead.
var target_state: VisualState = null

## All transition nodes that this visual represents.
## When transitions between the same states are grouped, this contains all of them.
## The first transition is considered the "primary" for selection purposes.
var transition_nodes: Array[Transition] = []

## The points defining the arrow path from source to target.
## For labeled transitions: 3 points (source edge → label center → target edge).
## For unlabeled transitions: 2 points (source edge → target edge).
var path: PackedVector2Array = PackedVector2Array()

## Position where the label should be drawn (center of label).
## For labeled transitions, this is on the path between source and target.
var label_position: Vector2 = Vector2.ZERO

## The label which is attached to the position. Can be an empty label but not null.
var label:VisualLabel = null


func _init(source_state:VisualState, target_state:VisualState, label:VisualLabel, transitions:Array[Transition]):
	assert(is_instance_valid(source_state))
	assert(is_instance_valid(target_state))
	assert(is_instance_valid(label))
	assert(transitions != null and transitions.size() > 0)
	
	self.source_state = source_state
	self.target_state = target_state
	self.label = label
	self.transition_nodes.append_array(transitions)

## Returns the primary transition node for selection purposes.
## This is the first transition in the group.
func get_primary_transition() -> Transition:
	if transition_nodes.is_empty():
		return null
	return transition_nodes[0]

## Returns true, if the transition has a visible label.
func has_label() -> bool:
	return label.label_width > 0
