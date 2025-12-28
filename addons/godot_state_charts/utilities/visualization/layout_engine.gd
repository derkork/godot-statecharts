@tool
## Computes the layout for visualizing a state chart as nested rectangles with transition arrows.
##
## Uses the Sugiyama algorithm (layered graph drawing):
## 1. Cycle removal - temporarily reverse back edges
## 2. Layer assignment - assign nodes to horizontal layers
## 3. Crossing minimization - order nodes within layers to reduce edge crossings
## 4. Coordinate assignment - compute final x,y positions
##
## The algorithm runs once per structure change (not continuously like force-directed).
## Each compound/parallel state is laid out independently, bottom-up.
const StateChartUtil = preload("../state_chart_util.gd")
const VisualLabel = preload("visual_label.gd")
const VisualState = preload("visual_state.gd")
const VisualTransition = preload("visual_transition.gd")
const VisualizationTheme = preload("visualization_theme.gd")
const TransitionLabelBuilder = preload("transition_label_builder.gd")

# ----- Layout Constants -----

## Minimum horizontal spacing between nodes in the same layer.
const NODE_SPACING_H: float = 30.0

## Minimum vertical spacing between layers.
const LAYER_SPACING: float = 50.0

## Extra spacing for labels on edges.
const LABEL_SPACING: float = 20.0

## Vertical offset for self-transition label above the node.
const SELF_TRANSITION_LABEL_OFFSET: float = 30.0

## Pixels per character for label width estimation.
const PIXELS_PER_CHAR: float = 7.0

## Estimated height of a single label line in pixels.
const LABEL_LINE_HEIGHT: float = 20.0

## Estimated icon width for state type icons.
const ICON_WIDTH: float = 16.0

## Padding around state name text.
const STATE_NAME_PADDING: float = 20.0


# ----- Inner Classes -----

## Result of layout computation, containing the visual states and transitions.
class LayoutResult:
	var states: Array[VisualState] = []
	var transitions: Array[VisualTransition] = []


## A group of transitions between the same source and target states.
class TransitionGroup:
	var source: StateChartState
	var target: StateChartState
	var transitions: Array[Transition] = []
	var visual_label: VisualLabel


## Represents a node in the Sugiyama layout graph.
## Can be either a real state node or a virtual label node.
class LayoutNode:
	var visual: VisualState  # null for label nodes
	var layer: int = -1  # Assigned layer (0 = top)
	var position_in_layer: int = 0  # Order within layer
	var x: float = 0.0  # Final x coordinate
	var y: float = 0.0  # Final y coordinate
	var width: float = 0.0  # Node width (for label nodes)
	var height: float = 0.0  # Node height (for label nodes)
	var is_label_node: bool = false  # True for virtual label nodes
	var group_key: String = ""  # For label nodes: the transition group key
	var label_type: String = "internal"  # "internal" or "cross_subtree"
	var source_ancestor_idx: int = -1  # For cross-subtree: index of source ancestor in layout
	var target_ancestor_idx: int = -1  # For cross-subtree: index of target ancestor in layout

	func _init(v: VisualState = null) -> void:
		visual = v
		if v != null:
			width = v.rect.size.x
			height = v.rect.size.y

	## Creates a label node with the given dimensions.
	static func create_label_node(w: float, h: float, key: String) -> LayoutNode:
		var node := LayoutNode.new(null)
		node.is_label_node = true
		node.width = w
		node.height = h
		node.group_key = key
		return node


## Represents an edge in the Sugiyama layout graph.
class LayoutEdge:
	var source_idx: int
	var target_idx: int
	var reversed: bool = false  # True if edge was reversed for cycle removal
	var group_key: String = ""  # Key for looking up transition group


# ----- Instance State -----

## The root visual state (top of hierarchy).
var _root_visual: VisualState = null

## Grouped transitions for the entire chart.
var _grouped_transitions: Dictionary = {}

## The state chart being visualized.
var _state_chart: StateChart = null

## Computed label positions from layout, keyed by transition group key.
## Each entry is a Dictionary with:
##   - "position": Vector2 - label center in parent's local coordinate space
##   - "parent": VisualState - the compound state containing the label
##   - "type": String - "internal", "incoming", or "outgoing"
##   - "target_local_pos": Vector2 - (incoming only) target node position in parent's local space
##   - "source_local_pos": Vector2 - (outgoing only) source node position in parent's local space
## Position is in parent's local coordinate space; use parent.rect.position
## (after _assign_absolute_positions) to compute absolute position.
var _label_positions: Dictionary = {}


# ----- Public API -----

## Initializes the layout engine with a state chart computes and returns a layout result.
## Returns true if the chart changed and layout needs recomputing.
func layout(state_chart: StateChart) -> LayoutResult:
	var result := LayoutResult.new()

	if not is_instance_valid(state_chart):
		return result

	var root_state := state_chart.get_child(0) as StateChartState
	if not is_instance_valid(root_state):
		return result

	_state_chart = state_chart
	_label_positions.clear()

	# Build the visual structure
	_collect_and_group_transitions(state_chart)

	# Build visual tree (sizes computed during layout)
	_root_visual = _build_visual_tree(root_state)

	# Run Sugiyama layout bottom-up for each compound/parallel state
	_layout_recursive(_root_visual)

	# Assign absolute positions top-down
	_assign_absolute_positions(_root_visual, Vector2.ZERO)

	# Flatten hierarchy into parent-first order
	_collect_visuals(_root_visual, result.states)

	# Finalize transitions with paths
	_finalize_transitions(result.states, result.transitions)

	return result


# ----- Structure Building -----

## Collects all state and transition nodes.
func _collect_all_nodes(node: Node) -> Array:
	var result := []
	if node is StateChartState or node is Transition:
		result.append(node)
	for child in node.get_children():
		result.append_array(_collect_all_nodes(child))
	return result


## Builds the visual tree with initial sizes.
func _build_visual_tree(state: StateChartState) -> VisualState:
	var visual := VisualState.new()
	visual.state_node = state
	visual.state_type = _get_state_type(state)
	visual.is_initial = _is_initial_state(state)

	# Collect child states
	var child_states: Array[StateChartState] = []
	for child in state.get_children():
		if child is StateChartState:
			child_states.append(child)

	if child_states.is_empty():
		# Leaf node: size based on name
		var name_width := _estimate_state_name_width(state)
		var min_width: float = VisualizationTheme.MIN_STATE_WIDTH
		if name_width > min_width:
			min_width = name_width
		visual.rect = Rect2(0, 0, min_width, VisualizationTheme.MIN_STATE_HEIGHT)
	else:
		# Recursive: build children first
		for child_state in child_states:
			var child_visual := _build_visual_tree(child_state)
			visual.children.append(child_visual)

		# Size will be computed during layout
		visual.rect = Rect2(Vector2.ZERO, Vector2(100, 100))

	return visual


# ----- Sugiyama Layout -----

## Recursively applies Sugiyama layout bottom-up.
func _layout_recursive(visual: VisualState) -> void:
	# First, layout all children (bottom-up)
	for child in visual.children:
		_layout_recursive(child)

	# Now layout this level's children
	if not visual.children.is_empty():
		_layout_level(visual)


## Applies Sugiyama layout to the children of a compound/parallel state.
## Uses a two-phase approach:
## 1. Layer assignment on state nodes only (ignores labels)
## 2. Insert label nodes at midpoint layers, then run crossing minimization
## This ensures bidirectional edges (A->B and B->A) have labels at the same layer.
##
## Also handles cross-hierarchy transitions by including their labels in the layout.
func _layout_level(parent_visual: VisualState) -> void:
	var num_states := parent_visual.children.size()
	if num_states == 0:
		return

	# ===== PHASE 1: Layer assignment on state nodes only =====

	# Build layout nodes for state children only
	var state_nodes: Array[LayoutNode] = []
	var state_index_map := {}  # StateChartState -> index

	for i in range(num_states):
		var child: VisualState = parent_visual.children[i]
		var node := LayoutNode.new(child)
		state_nodes.append(node)
		state_index_map[child.state_node] = i

	# Build direct edges between states (ignore labels for now)
	var state_edges: Array[LayoutEdge] = []
	var parent_state := parent_visual.state_node
	var transition_info: Array = []  # Store {key, source_idx, target_idx, label_size} for later

	# Track self-transitions per state
	var self_transitions_per_state: Dictionary = {}  # StateChartState -> {key, label_size, state_idx}

	for key in _grouped_transitions:
		var group: TransitionGroup = _grouped_transitions[key]
		var source: StateChartState = group.source
		var target: StateChartState = group.target

		# Find the direct child of parent_state that contains each endpoint
		var source_ancestor := _find_child_ancestor(source, parent_state)
		var target_ancestor := _find_child_ancestor(target, parent_state)

		# Skip if either endpoint is not inside this compound's subtree
		if source_ancestor == null or target_ancestor == null:
			continue

		# Handle self-transitions specially
		if source == target:
			# Self-transition: source and target are the same state
			# Only handle if the state is a direct child of this parent
			if source_ancestor == source:
				var label_size := _estimate_label_size(group)
				self_transitions_per_state[source] = {
					"key": key,
					"label_size": label_size,
					"state_idx": state_index_map[source]
				}
			continue

		# Skip if both are in the same subtree (handled at a deeper level)
		if source_ancestor == target_ancestor:
			continue

		# Get the indices of the ancestor nodes in our layout
		var source_idx: int = -1
		var target_idx: int = -1
		if state_index_map.has(source_ancestor):
			source_idx = state_index_map[source_ancestor]
		if state_index_map.has(target_ancestor):
			target_idx = state_index_map[target_ancestor]

		if source_idx < 0 or target_idx < 0:
			continue

		# Create edge between the ancestor nodes for layer assignment
		var edge := LayoutEdge.new()
		edge.source_idx = source_idx
		edge.target_idx = target_idx
		edge.group_key = key
		state_edges.append(edge)

		# Store transition info for label insertion
		var label_size := _estimate_label_size(group)
		var is_cross_hierarchy := (source != source_ancestor) or (target != target_ancestor)

		transition_info.append({
			"key": key,
			"source_idx": source_idx,
			"target_idx": target_idx,
			"label_size": label_size,
			"is_cross_hierarchy": is_cross_hierarchy,
			"source_ancestor": source_ancestor,
			"target_ancestor": target_ancestor
		})

	# Run cycle removal and layer assignment on STATE NODES ONLY
	_remove_cycles(state_nodes, state_edges)
	_assign_layers(state_nodes, state_edges)

	# ===== PHASE 2: Insert label nodes and finalize layout =====

	# Find max layer
	var max_state_layer := 0
	for node in state_nodes:
		if node.layer > max_state_layer:
			max_state_layer = node.layer

	# Identify layers where we need to insert space for labels
	var layers_to_insert: Array[int] = []

	for info in transition_info:
		var label_size: Vector2 = info["label_size"]
		if label_size.x <= 0:
			continue

		var source_idx: int = info["source_idx"]
		var target_idx: int = info["target_idx"]
		var source_layer := state_nodes[source_idx].layer
		var target_layer := state_nodes[target_idx].layer

		# Check if states are adjacent or on same layer - need to insert label layer
		var layer_diff := absi(target_layer - source_layer)

		if layer_diff <= 1:
			# Need to insert a label layer after the earlier state
			var insert_after := mini(source_layer, target_layer)
			if not layers_to_insert.has(insert_after):
				layers_to_insert.append(insert_after)

	# Sort insertion points in descending order so we can shift without invalidating indices
	layers_to_insert.sort()
	layers_to_insert.reverse()

	# Shift state layers to make room for label layers
	for insert_after in layers_to_insert:
		for node in state_nodes:
			if node.layer > insert_after:
				node.layer += 1
		max_state_layer += 1

	# Now build the full node list with labels
	var all_nodes: Array[LayoutNode] = []
	var all_edges: Array[LayoutEdge] = []

	# Copy state nodes (with shifted layers)
	for node in state_nodes:
		all_nodes.append(node)

	# Create label nodes for all transitions
	for info in transition_info:
		var source_idx: int = info["source_idx"]
		var target_idx: int = info["target_idx"]
		var label_size: Vector2 = info["label_size"]
		var key: String = info["key"]
		var is_cross_hierarchy: bool = info["is_cross_hierarchy"]

		if label_size.x > 0:
			var source_layer := state_nodes[source_idx].layer
			var target_layer := state_nodes[target_idx].layer

			# Calculate label layer as midpoint
			var min_layer := mini(source_layer, target_layer)
			var max_layer := maxi(source_layer, target_layer)
			var label_layer := min_layer + int((max_layer - min_layer + 1) / 2.0)

			# Create label node
			var label_node := LayoutNode.create_label_node(label_size.x, label_size.y, key)
			label_node.layer = label_layer

			# Mark cross-hierarchy labels for special path handling
			if is_cross_hierarchy:
				label_node.label_type = "cross_subtree"
				label_node.source_ancestor_idx = source_idx
				label_node.target_ancestor_idx = target_idx

			var label_idx := all_nodes.size()
			all_nodes.append(label_node)

			# Create edges: source -> label, label -> target (for crossing minimization)
			var edge1 := LayoutEdge.new()
			edge1.source_idx = source_idx
			edge1.target_idx = label_idx
			edge1.group_key = key
			all_edges.append(edge1)

			var edge2 := LayoutEdge.new()
			edge2.source_idx = label_idx
			edge2.target_idx = target_idx
			edge2.group_key = key
			all_edges.append(edge2)
		else:
			# No label, create direct edge (for crossing minimization)
			var edge := LayoutEdge.new()
			edge.source_idx = source_idx
			edge.target_idx = target_idx
			edge.group_key = key
			all_edges.append(edge)

	# Step 3: Crossing minimization (with all nodes including labels)
	_minimize_crossings(all_nodes, all_edges)

	# Step 4: Coordinate assignment
	_assign_coordinates(all_nodes, all_edges, parent_visual)

	# Step 5: Position self-transition labels above their states
	_position_self_transition_labels(self_transitions_per_state, state_nodes, parent_visual)


## Positions labels for self-transitions above their respective state nodes.
func _position_self_transition_labels(
	self_transitions_per_state: Dictionary,
	state_nodes: Array[LayoutNode],
	parent_visual: VisualState
) -> void:
	for state in self_transitions_per_state:
		var trans_info: Dictionary = self_transitions_per_state[state]
		var key: String = trans_info["key"]

		# Get the state's layout node to find its position
		# Use the visual's rect which has already been offset-adjusted by _assign_coordinates
		var state_idx: int = trans_info["state_idx"]
		var state_node := state_nodes[state_idx]
		var state_rect := state_node.visual.rect

		# Label centered horizontally above the state
		var label_center_x := state_rect.position.x + state_rect.size.x / 2.0
		var label_center_y := state_rect.position.y - SELF_TRANSITION_LABEL_OFFSET

		# Store label position with "self" type for special path handling
		_label_positions[key] = {
			"position": Vector2(label_center_x, label_center_y),
			"parent": parent_visual,
			"type": "self",
			"state_rect": state_rect
		}


## Step 1: Remove cycles by reversing back edges (DFS-based).
func _remove_cycles(nodes: Array[LayoutNode], edges: Array[LayoutEdge]) -> void:
	var n := nodes.size()
	if n == 0:
		return

	# Build adjacency list
	var adj: Array = []
	adj.resize(n)
	for i in range(n):
		adj[i] = []

	for i in range(edges.size()):
		var edge := edges[i]
		adj[edge.source_idx].append(i)  # Store edge index

	# DFS to find back edges
	var WHITE := 0
	var GRAY := 1
	var BLACK := 2

	var color: Array[int] = []
	color.resize(n)
	for i in range(n):
		color[i] = WHITE

	for start in range(n):
		if color[start] != WHITE:
			continue

		var stack: Array = [[start, 0]]  # [node, edge_index_in_adj]

		while not stack.is_empty():
			var current: Array = stack[stack.size() - 1]
			var node: int = current[0]
			var edge_idx: int = current[1]

			if edge_idx == 0:
				color[node] = GRAY

			var found_next := false
			var adj_list: Array = adj[node]

			while edge_idx < adj_list.size():
				var ei: int = adj_list[edge_idx]
				var edge := edges[ei]
				var target := edge.target_idx
				edge_idx += 1
				current[1] = edge_idx

				if color[target] == WHITE:
					stack.append([target, 0])
					found_next = true
					break
				elif color[target] == GRAY:
					# Back edge found - reverse it
					edge.reversed = true
					var temp := edge.source_idx
					edge.source_idx = edge.target_idx
					edge.target_idx = temp

			if not found_next:
				color[node] = BLACK
				stack.pop_back()


## Step 2: Assign nodes to layers using longest path from sources.
func _assign_layers(nodes: Array[LayoutNode], edges: Array[LayoutEdge]) -> void:
	var n := nodes.size()
	if n == 0:
		return

	# Build in-degree count and adjacency
	var in_degree: Array[int] = []
	in_degree.resize(n)
	var out_adj: Array = []
	out_adj.resize(n)

	for i in range(n):
		in_degree[i] = 0
		out_adj[i] = []

	for edge in edges:
		in_degree[edge.target_idx] += 1
		out_adj[edge.source_idx].append(edge.target_idx)

	# Find sources (in_degree == 0)
	var sources: Array[int] = []
	for i in range(n):
		if in_degree[i] == 0:
			sources.append(i)

	# If no sources (all nodes in cycles somehow), use all nodes
	if sources.is_empty():
		for i in range(n):
			sources.append(i)

	# Longest path from sources using topological order
	var dist: Array[int] = []
	dist.resize(n)
	for i in range(n):
		dist[i] = 0

	# Process in topological order
	var queue := sources.duplicate()
	var remaining := in_degree.duplicate()

	while not queue.is_empty():
		var node: int = queue.pop_front()
		var adj_list: Array = out_adj[node]
		for target in adj_list:
			var new_dist := dist[node] + 1
			if new_dist > dist[target]:
				dist[target] = new_dist
			remaining[target] -= 1
			if remaining[target] == 0:
				queue.append(target)

	# Handle disconnected nodes - place them on layer 0
	for i in range(n):
		nodes[i].layer = dist[i]


## Step 3: Minimize crossings using barycenter heuristic.
func _minimize_crossings(nodes: Array[LayoutNode], edges: Array[LayoutEdge]) -> void:
	var n := nodes.size()
	if n == 0:
		return

	# Find max layer
	var max_layer := 0
	for node in nodes:
		if node.layer > max_layer:
			max_layer = node.layer

	# Group nodes by layer
	var layers: Array = []
	layers.resize(max_layer + 1)
	for i in range(max_layer + 1):
		layers[i] = []

	for i in range(n):
		layers[nodes[i].layer].append(i)

	# Build adjacency for barycenter calculation
	var in_adj: Array = []
	var out_adj: Array = []
	in_adj.resize(n)
	out_adj.resize(n)
	for i in range(n):
		in_adj[i] = []
		out_adj[i] = []

	for edge in edges:
		out_adj[edge.source_idx].append(edge.target_idx)
		in_adj[edge.target_idx].append(edge.source_idx)

	# Initial ordering by position
	for layer_idx in range(layers.size()):
		var layer: Array = layers[layer_idx]
		for pos in range(layer.size()):
			nodes[layer[pos]].position_in_layer = pos

	# Iterate barycenter heuristic (sweep down then up)
	for _iteration in range(4):
		# Sweep down
		for layer_idx in range(1, layers.size()):
			var layer: Array = layers[layer_idx]
			_order_layer_by_barycenter(nodes, layer, in_adj, true)

		# Sweep up
		for layer_idx in range(layers.size() - 2, -1, -1):
			var layer: Array = layers[layer_idx]
			_order_layer_by_barycenter(nodes, layer, out_adj, false)


## Orders nodes in a layer by barycenter of neighbors.
func _order_layer_by_barycenter(nodes: Array[LayoutNode], layer: Array, adj: Array, use_in: bool) -> void:
	if layer.size() <= 1:
		return

	# Calculate barycenter for each node
	var barycenters: Array = []
	for node_idx in layer:
		var neighbors: Array = adj[node_idx]
		if neighbors.is_empty():
			# Keep current position if no neighbors
			barycenters.append([node_idx, float(nodes[node_idx].position_in_layer)])
		else:
			var sum := 0.0
			for neighbor in neighbors:
				sum += float(nodes[neighbor].position_in_layer)
			barycenters.append([node_idx, sum / float(neighbors.size())])

	# Sort by barycenter
	barycenters.sort_custom(func(a: Array, b: Array) -> bool:
		return a[1] < b[1]
	)

	# Update positions
	for pos in range(barycenters.size()):
		var node_idx: int = barycenters[pos][0]
		nodes[node_idx].position_in_layer = pos

	# Update layer array order
	layer.clear()
	for entry in barycenters:
		layer.append(entry[0])


## Step 4: Assign x,y coordinates to nodes.
func _assign_coordinates(nodes: Array[LayoutNode], edges: Array[LayoutEdge], parent_visual: VisualState) -> void:
	var n := nodes.size()
	if n == 0:
		return

	# Find max layer
	var max_layer := 0
	for node in nodes:
		if node.layer > max_layer:
			max_layer = node.layer

	# Group nodes by layer and sort by position
	var layers: Array = []
	layers.resize(max_layer + 1)
	for i in range(max_layer + 1):
		layers[i] = []

	for i in range(n):
		layers[nodes[i].layer].append(i)

	for layer in layers:
		layer.sort_custom(func(a: int, b: int) -> bool:
			return nodes[a].position_in_layer < nodes[b].position_in_layer
		)

	# Calculate layer heights and max widths
	# Use node.width/height which works for both state nodes and label nodes
	var layer_heights: Array[float] = []
	var layer_widths: Array[float] = []
	layer_heights.resize(max_layer + 1)
	layer_widths.resize(max_layer + 1)

	for layer_idx in range(layers.size()):
		var layer: Array = layers[layer_idx]
		var max_height := 0.0
		var total_width := 0.0

		for node_idx in layer:
			var node := nodes[node_idx]
			if node.height > max_height:
				max_height = node.height
			total_width += node.width

		# Add spacing
		if layer.size() > 1:
			total_width += NODE_SPACING_H * (layer.size() - 1)

		layer_heights[layer_idx] = max_height
		layer_widths[layer_idx] = total_width

	# Calculate total dimensions
	var total_height := 0.0
	for i in range(layer_heights.size()):
		total_height += layer_heights[i]
	if max_layer > 0:
		total_height += LAYER_SPACING * max_layer

	var max_width := 0.0
	for w in layer_widths:
		if w > max_width:
			max_width = w

	# Assign y coordinates (top to bottom)
	var current_y := 0.0
	for layer_idx in range(layers.size()):
		var layer: Array = layers[layer_idx]
		var layer_height := layer_heights[layer_idx]

		# Center nodes vertically within layer
		for node_idx in layer:
			var node := nodes[node_idx]
			node.y = current_y + (layer_height - node.height) / 2.0

		current_y += layer_height + LAYER_SPACING

	# Assign x coordinates (centered in each layer)
	for layer_idx in range(layers.size()):
		var layer: Array = layers[layer_idx]
		var layer_width := layer_widths[layer_idx]

		# Start x to center the layer
		var start_x := (max_width - layer_width) / 2.0
		var current_x := start_x

		for node_idx in layer:
			var node := nodes[node_idx]
			node.x = current_x
			current_x += node.width + NODE_SPACING_H

	# First pass: apply positions to state visuals
	for node in nodes:
		if not node.is_label_node:
			node.visual.rect.position = Vector2(node.x, node.y)

	# Second pass: extract label positions with routing info
	for node in nodes:
		if node.is_label_node:
			var label_info := {
				"position": Vector2(
					node.x + node.width / 2.0,
					node.y + node.height / 2.0
				),
				"parent": parent_visual,
				"type": node.label_type
			}

			# For cross-subtree labels, store the ancestor node rects for path routing
			if node.label_type == "cross_subtree":
				if node.source_ancestor_idx >= 0:
					var src_ancestor := nodes[node.source_ancestor_idx]
					label_info["source_ancestor_rect"] = Rect2(
						src_ancestor.x, src_ancestor.y,
						src_ancestor.width, src_ancestor.height
					)
				if node.target_ancestor_idx >= 0:
					var tgt_ancestor := nodes[node.target_ancestor_idx]
					label_info["target_ancestor_rect"] = Rect2(
						tgt_ancestor.x, tgt_ancestor.y,
						tgt_ancestor.width, tgt_ancestor.height
					)

			_label_positions[node.group_key] = label_info

	# Calculate parent size
	var padding := VisualizationTheme.STATE_PADDING
	var label_height := VisualizationTheme.LABEL_HEIGHT

	var container_width := max_width + padding * 2
	var container_height := total_height + padding * 2 + label_height

	# Ensure minimum size
	var name_width := _estimate_state_name_width(parent_visual.state_node)
	if name_width > container_width:
		container_width = name_width
	if VisualizationTheme.MIN_STATE_WIDTH > container_width:
		container_width = VisualizationTheme.MIN_STATE_WIDTH
	if VisualizationTheme.MIN_STATE_HEIGHT > container_height:
		container_height = VisualizationTheme.MIN_STATE_HEIGHT

	parent_visual.rect.size = Vector2(container_width, container_height)

	# Offset children to account for padding and label
	var offset := Vector2(padding, padding + label_height)
	for node in nodes:
		if node.is_label_node:
			# Update the stored label position and ancestor rects
			var label_info: Dictionary = _label_positions[node.group_key]
			label_info["position"] += offset
			if label_info.has("source_ancestor_rect"):
				var rect: Rect2 = label_info["source_ancestor_rect"]
				label_info["source_ancestor_rect"] = Rect2(rect.position + offset, rect.size)
			if label_info.has("target_ancestor_rect"):
				var rect: Rect2 = label_info["target_ancestor_rect"]
				label_info["target_ancestor_rect"] = Rect2(rect.position + offset, rect.size)
		else:
			node.visual.rect.position += offset


## Assigns absolute positions by adding parent positions.
func _assign_absolute_positions(visual: VisualState, parent_pos: Vector2) -> void:
	visual.rect.position = parent_pos + visual.rect.position

	for child in visual.children:
		_assign_absolute_positions(child, visual.rect.position)


# ----- Transition Handling -----

## Collects all transitions from the chart and groups by source/target.
func _collect_and_group_transitions(chart: StateChart) -> void:
	var grouped := {}  # String -> TransitionGroup
	var all_transitions := StateChartUtil.transitions_of(chart)

	for transition in all_transitions:
		var source_state := transition.get_parent() as StateChartState
		if source_state == null: # can happen if a transition node is added at the wrong place
			continue

		var target_state := transition.resolve_target()
		if target_state == null: # can happen if target is not yet set or points to a wrong node
			continue

		var key := str(source_state.get_path()) + "->" + str(target_state.get_path())

		if not grouped.has(key):
			var group := TransitionGroup.new()
			group.source = source_state
			group.target = target_state
			grouped[key] = group

		var group: TransitionGroup = grouped[key]
		group.transitions.append(transition)


	# now we have all transitions that go into each group so we can build the
	# labels. we need these later for routing (and display)
	for group in grouped.values():
		group.visual_label = TransitionLabelBuilder.build_label(group.transitions)

	_grouped_transitions = grouped


## Collects all visual states into a flat array, parent-first order.
func _collect_visuals(visual: VisualState, result: Array[VisualState]) -> void:
	result.append(visual)
	for child in visual.children:
		_collect_visuals(child, result)


## Creates the final visual transitions with computed paths.
func _finalize_transitions(
	visuals: Array[VisualState],
	result: Array[VisualTransition]
) -> void:
	# Build lookup table
	var visual_map := {}
	for v in visuals:
		visual_map[v.state_node.get_path()] = v

	# Create visual transitions
	for key in _grouped_transitions:
		var group: TransitionGroup = _grouped_transitions[key]
		var source: StateChartState = group.source
		var target: StateChartState = group.target

		var source_visual: VisualState = visual_map.get(source.get_path())
		var target_visual: VisualState = visual_map.get(target.get_path())

		if source_visual == null or target_visual == null:
			continue

		var vt := VisualTransition.new(source_visual, target_visual, group.visual_label, group.transitions)

		# Get label position from Sugiyama layout if available
		var label_pos: Vector2 = Vector2.ZERO
		var has_label_pos := false
		var label_type := "internal"

		if _label_positions.has(key):
			var label_info: Dictionary = _label_positions[key]
			var parent_visual: VisualState = label_info["parent"]
			# Convert local position to absolute by adding parent's position
			label_pos = label_info["position"] + parent_visual.rect.position
			has_label_pos = true
			label_type = label_info.get("type", "internal")

			if label_type == "cross_subtree":
				# Cross-subtree transition: route through ancestor boundaries
				var src_ancestor_rect: Rect2 = Rect2()
				var tgt_ancestor_rect: Rect2 = Rect2()

				if label_info.has("source_ancestor_rect"):
					var local_rect: Rect2 = label_info["source_ancestor_rect"]
					src_ancestor_rect = Rect2(
						local_rect.position + parent_visual.rect.position,
						local_rect.size
					)
				if label_info.has("target_ancestor_rect"):
					var local_rect: Rect2 = label_info["target_ancestor_rect"]
					tgt_ancestor_rect = Rect2(
						local_rect.position + parent_visual.rect.position,
						local_rect.size
					)

				vt.path = _calculate_cross_subtree_path(
					source_visual.rect,
					target_visual.rect,
					label_pos,
					src_ancestor_rect,
					tgt_ancestor_rect
				)
				vt.label_position = label_pos

			elif label_type == "self":
				# Self-transition: loopback arrow above the state
				var state_rect: Rect2 = label_info["state_rect"]
				# Convert local rect to absolute by adding parent's position
				var absolute_state_rect := Rect2(
					state_rect.position + parent_visual.rect.position,
					state_rect.size
				)
				vt.path = _calculate_self_transition_path(absolute_state_rect, label_pos)
				vt.label_position = label_pos

			else:
				# Internal transition: simple path through label
				vt.path = _calculate_arrow_path_through_point(
					source_visual.rect,
					target_visual.rect,
					label_pos
				)
				vt.label_position = label_pos
		else:
			vt.path = _calculate_direct_arrow_path(
				source_visual.rect,
				target_visual.rect
			)
			# Label position at path midpoint for unlabeled transitions
			if vt.path.size() >= 2:
				vt.label_position = (vt.path[0] + vt.path[1]) / 2.0

		result.append(vt)


## Calculates a direct arrow path from source to target rectangle (no waypoints).
func _calculate_direct_arrow_path(source_rect: Rect2, target_rect: Rect2) -> PackedVector2Array:
	var path := PackedVector2Array()

	var src_center := source_rect.get_center()
	var tgt_center := target_rect.get_center()

	var exit_point := _rect_edge_intersection(source_rect, src_center, tgt_center)
	var entry_point := _rect_edge_intersection(target_rect, tgt_center, src_center)

	path.append(exit_point)
	path.append(entry_point)

	return path


## Calculates an arrow path that goes through a waypoint (label position).
## Creates a 3-point path: source edge → waypoint → target edge.
func _calculate_arrow_path_through_point(
	source_rect: Rect2,
	target_rect: Rect2,
	waypoint: Vector2
) -> PackedVector2Array:
	var path := PackedVector2Array()

	var src_center := source_rect.get_center()
	var tgt_center := target_rect.get_center()

	# Exit from source toward waypoint
	var exit_point := _rect_edge_intersection(source_rect, src_center, waypoint)
	# Enter target from waypoint
	var entry_point := _rect_edge_intersection(target_rect, tgt_center, waypoint)

	path.append(exit_point)
	path.append(waypoint)
	path.append(entry_point)

	return path


## Calculates an arrow path for cross-subtree transitions.
## Routes: source → exit source_ancestor (if nested) → label → enter target_ancestor (if nested) → target.
## This handles transitions where source and target are in different child subtrees.
func _calculate_cross_subtree_path(
	source_rect: Rect2,
	target_rect: Rect2,
	label_pos: Vector2,
	source_ancestor_rect: Rect2,
	target_ancestor_rect: Rect2
) -> PackedVector2Array:
	var path := PackedVector2Array()

	var src_center := source_rect.get_center()
	var tgt_center := target_rect.get_center()

	# Check if source is nested inside an ancestor (source_rect is smaller and inside ancestor)
	var source_is_nested := (
		source_ancestor_rect.size.x > 0 and
		source_rect.size.x < source_ancestor_rect.size.x - 10
	)

	# Check if target is nested inside an ancestor
	var target_is_nested := (
		target_ancestor_rect.size.x > 0 and
		target_rect.size.x < target_ancestor_rect.size.x - 10
	)

	if source_is_nested:
		# Source is inside a compound - exit via the compound's boundary toward the label
		var exit_toward := label_pos
		var exit_from_ancestor := _rect_edge_intersection(
			source_ancestor_rect,
			source_ancestor_rect.get_center(),
			exit_toward
		)
		var exit_from_source := _rect_edge_intersection(source_rect, src_center, exit_from_ancestor)

		path.append(exit_from_source)
		path.append(exit_from_ancestor)
	else:
		# Source is a direct child - exit directly toward label
		var exit_from_source := _rect_edge_intersection(source_rect, src_center, label_pos)
		path.append(exit_from_source)

	# Add the label position
	path.append(label_pos)

	if target_is_nested:
		# Target is inside a compound - enter via the compound's boundary
		var enter_from := label_pos
		var enter_ancestor := _rect_edge_intersection(
			target_ancestor_rect,
			target_ancestor_rect.get_center(),
			enter_from
		)
		var enter_target := _rect_edge_intersection(target_rect, tgt_center, enter_ancestor)

		path.append(enter_ancestor)
		path.append(enter_target)
	else:
		# Target is a direct child - enter directly from label
		var enter_target := _rect_edge_intersection(target_rect, tgt_center, label_pos)
		path.append(enter_target)

	return path


## Calculates an arrow path for self-transitions.
## Routes: upper-left of node → label position above → upper-right of node.
## This creates a loopback arc above the state with the label at the apex.
func _calculate_self_transition_path(
	state_rect: Rect2,
	label_pos: Vector2
) -> PackedVector2Array:
	var path := PackedVector2Array()

	# Calculate horizontal offset from center for exit/entry points
	# Use 1/4 of the width so the arrows don't overlap at the corners
	var horizontal_offset := state_rect.size.x / 4.0

	# Exit point: upper-left area of the node's top edge
	var exit_x := state_rect.position.x + (state_rect.size.x / 2.0) - horizontal_offset
	var exit_y := state_rect.position.y
	var exit_point := Vector2(exit_x, exit_y)

	# Entry point: upper-right area of the node's top edge
	var entry_x := state_rect.position.x + (state_rect.size.x / 2.0) + horizontal_offset
	var entry_y := state_rect.position.y
	var entry_point := Vector2(entry_x, entry_y)

	path.append(exit_point)
	path.append(label_pos)
	path.append(entry_point)

	return path


## Finds the intersection point of a line with a rectangle's edge.
func _rect_edge_intersection(rect: Rect2, inside: Vector2, outside: Vector2) -> Vector2:
	var direction := (outside - inside).normalized()

	if direction.length_squared() < 0.0001:
		return rect.get_center()

	var center := rect.get_center()
	var half_size := rect.size / 2.0
	var min_t := INF

	# Right edge
	if direction.x > 0.0001:
		var t := (center.x + half_size.x - inside.x) / direction.x
		if t > 0 and t < min_t:
			var y := inside.y + t * direction.y
			if y >= rect.position.y and y <= rect.position.y + rect.size.y:
				min_t = t

	# Left edge
	if direction.x < -0.0001:
		var t := (center.x - half_size.x - inside.x) / direction.x
		if t > 0 and t < min_t:
			var y := inside.y + t * direction.y
			if y >= rect.position.y and y <= rect.position.y + rect.size.y:
				min_t = t

	# Bottom edge
	if direction.y > 0.0001:
		var t := (center.y + half_size.y - inside.y) / direction.y
		if t > 0 and t < min_t:
			var x := inside.x + t * direction.x
			if x >= rect.position.x and x <= rect.position.x + rect.size.x:
				min_t = t

	# Top edge
	if direction.y < -0.0001:
		var t := (center.y - half_size.y - inside.y) / direction.y
		if t > 0 and t < min_t:
			var x := inside.x + t * direction.x
			if x >= rect.position.x and x <= rect.position.x + rect.size.x:
				min_t = t

	if min_t == INF:
		return center

	return inside + direction * min_t


# ----- Utility Functions -----

## Checks if a node is a descendant of a potential ancestor.
func _is_descendant_of(node: Node, potential_ancestor: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current == potential_ancestor:
			return true
		current = current.get_parent()
	return false


## Finds the direct child of parent that contains node (or node itself if it's a direct child).
## Returns null if node is not inside parent's subtree.
func _find_child_ancestor(node: Node, parent: Node) -> Node:
	if node == null or parent == null:
		return null

	# If node's immediate parent is parent, node is a direct child
	if node.get_parent() == parent:
		return node

	# Walk up to find the direct child of parent that contains node
	var current := node.get_parent()
	while current != null:
		if current.get_parent() == parent:
			return current
		current = current.get_parent()

	return null  # node is not inside parent's subtree


## Determines the state type string for styling purposes.
func _get_state_type(state: StateChartState) -> String:
	if state is AtomicState:
		return "atomic"
	elif state is CompoundState:
		return "compound"
	elif state is ParallelState:
		return "parallel"
	elif state is HistoryState:
		return "history"
	return "atomic"


## Checks if a state is the initial state of its parent compound state.
func _is_initial_state(state: StateChartState) -> bool:
	var parent := state.get_parent()
	if parent is CompoundState:
		var compound := parent as CompoundState
		var initial := compound.get_node_or_null(compound.initial_state)
		return initial == state
	return false


## Estimates the width needed to display a state's name.
func _estimate_state_name_width(state: StateChartState) -> float:
	var name_length := state.name.length()
	return ICON_WIDTH + 4.0 + float(name_length) * PIXELS_PER_CHAR + STATE_NAME_PADDING


## Estimates the size needed for a transition group's label.
## Returns Vector2.ZERO if the group has no visible label.
func _estimate_label_size(group: TransitionGroup) -> Vector2:
	if group.visual_label.label_width == 0.0:
		return Vector2.ZERO

	# Estimate size based on label width (in characters)
	# Keep labels compact - just enough for the text
	var width := group.visual_label.label_width * PIXELS_PER_CHAR + 10.0  # Minimal padding
	var height := LABEL_LINE_HEIGHT  # No extra padding for height

	return Vector2(width, height)
