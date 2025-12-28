@tool
## Represents the visual layout data for a single state in the state chart visualization.
## This class holds the computed position, size, and metadata needed to render a state
## as a nested rectangle in the visualization canvas. It forms a tree structure mirroring
## the state hierarchy, with parent states containing their children visually. This is the 
## output of the layout engine and the input for the StateChartCanvas.
extends RefCounted

## The bounding rectangle of this state in canvas coordinates.
## For composite states, this includes the area needed for all children plus padding.
var rect: Rect2 = Rect2()

## Reference to the actual StateChartState node this visual represents.
## Used for click-to-select functionality and accessing state properties.
var state_node: StateChartState = null

## The type of state for visual styling. One of: "atomic", "compound", "parallel", "history".
## Determines the color tint and any special visual indicators (like history "H" symbol).
var state_type: String = ""

## Whether this state is the initial state of its parent compound state.
## When true, an entry indicator (small arrow) is drawn pointing to this state.
var is_initial: bool = false

## Child visual states nested inside this one.
## Only populated for compound and parallel states. The children's rects are
## positioned relative to this state's rect during layout.
## This is an array of VisualState but we cannot refer to our own class here.
var children: Array = []
