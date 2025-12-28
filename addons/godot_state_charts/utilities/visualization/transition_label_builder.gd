@tool
## Builds formatted labels for transitions in the state chart visualization.
##
## This class handles the logic of converting transition configurations
## into readable label text. It supports various transition types:
## - Event-driven transitions (displayed in bold italic)
## - Guard-based transitions (with nested guard expression formatting)
## - Delayed transitions (showing the delay duration)
## - Combinations of the above
## - Multiple transitions between the same states (shown as alternatives)
##
## Formatting rules:
## - Event names: bold italic
## - Helper words ("when", "or", "after"): italic
## - StateIsActiveGuard: "in <state name>" with italic "in" and bold state name
## - Delays ("<duration>s"): italic
## - ExpressionGuard: monospace
## - Compound guards: monospace operators with nested content
##
## Misconfigured transitions are handled by ignoring problematic parts.

const VisualLabel = preload("visual_label.gd")
const VisualLabelSegment = preload("visual_label_segment.gd")


## Builds a label for a single transition or a group of transitions
## between the same source and target states.
##
## When multiple transitions exist between the same states, they are
## combined with "or" between each transition's expression.
##
## Returns an array of VisualLabelSegment objects that can be rendered with
## appropriate styling. Returns an empty array if there's nothing to display
## (e.g., unconditional automatic transitions).
static func build_label(transitions: Array) -> VisualLabel:
	var result := VisualLabel.new()
	if transitions.is_empty():
		return result

	var all_segments: Array[VisualLabelSegment] = []
	var transition_expressions: Array = []

	# Build expression for each transition
	for transition in transitions:
		var segments := _build_single_transition_label(transition)
		if not segments.is_empty():
			transition_expressions.append(segments)

	# If no transitions have displayable content, return empty
	if transition_expressions.is_empty():
		return result

	# Multiple transitions: join with " or " (italic helper word)
	for i in range(transition_expressions.size()):
		if i > 0:
			all_segments.append(VisualLabelSegment.new(" or ", VisualLabelSegment.Style.ITALIC))
		all_segments.append_array(transition_expressions[i])

	# build label
	result.label_segments = all_segments
	result.label_width = _estimate_label_width(all_segments)
	return result


## Estimates the total character width of a label for layout purposes.
## This is a rough estimate that accounts for different font styles
## having slightly different widths.
static func _estimate_label_width(segments: Array[VisualLabelSegment]) -> float:
	var total_chars := 0.0
	for segment in segments:
		# Monospace fonts are typically wider, italics slightly narrower
		var width_factor := 1.0
		match segment.style:
			VisualLabelSegment.Style.MONO:
				width_factor = 1.1
			VisualLabelSegment.Style.ITALIC:
				width_factor = 0.95
			VisualLabelSegment.Style.BOLD:
				width_factor = 1.05
			VisualLabelSegment.Style.BOLD_ITALIC:
				width_factor = 1.0
		total_chars += segment.text.length() * width_factor
	return total_chars


## Builds the label segments for a single transition.
##
## The format follows this pattern:
## - Case A: Event only -> "event" (bold italic)
## - Case B: No event, no guard, no delay -> empty (unconditional)
## - Case C: Guard only -> guard expression
## - Case D: Delay only -> "after Xs" (italic)
## - Case E: Combination -> "event when guard after Xs"
##
## Event names are bold italic, helper words are italic.
static func _build_single_transition_label(transition: Transition) -> Array[VisualLabelSegment]:
	var segments: Array[VisualLabelSegment] = []
	if not is_instance_valid(transition):
		return segments

	# Safely extract transition properties
	var event_name := transition.event
	var guard: Guard = transition.guard
	var delay := _get_delay_expression(transition)

	var has_event := not event_name.is_empty()
	var has_guard := guard != null
	var has_delay := _has_meaningful_delay(delay)

	# Case B: No event, no guard, no delay -> unconditional, show nothing
	if not has_event and not has_guard and not has_delay:
		return []

	# Add event name (bold italic for emphasis)
	if has_event:
		segments.append(VisualLabelSegment.new(event_name, VisualLabelSegment.Style.BOLD_ITALIC))

	# Add guard expression
	if has_guard:
		var guard_segments := _build_guard_expression(guard, transition)
		if not guard_segments.is_empty():
			# Add "when" connector if we already have event (italic helper)
			if not segments.is_empty():
				segments.append(VisualLabelSegment.new(" when ", VisualLabelSegment.Style.ITALIC))
			segments.append_array(guard_segments)

	# Add delay
	if has_delay:
		# Add "after" prefix (italic helper)
		if not segments.is_empty():
			segments.append(VisualLabelSegment.new(" ", VisualLabelSegment.Style.NORMAL))
		segments.append(VisualLabelSegment.new("after ", VisualLabelSegment.Style.ITALIC))
		# if the delay is a valid float display it inline
		if delay.is_valid_float():
			segments.append(VisualLabelSegment.new(delay + "s", VisualLabelSegment.Style.ITALIC))
		else:
			# it's an expression, so we show that monospaced
			segments.append(VisualLabelSegment.new(delay, VisualLabelSegment.Style.MONO))
			segments.append(VisualLabelSegment.new("s", VisualLabelSegment.Style.ITALIC))
	return segments


## Safely gets the delay expression from a transition.
## Returns the expression string (could be "0.0" or an expression).
static func _get_delay_expression(transition: Transition) -> String:
	if transition == null:
		return "0.0"
	return transition.delay_in_seconds


## Checks if a delay expression represents a meaningful delay (not zero).
static func _has_meaningful_delay(delay_expr: String) -> bool:
	if delay_expr.is_empty():
		return false

	# Check if it's a simple zero value
	var stripped := delay_expr.strip_edges()
	if stripped == "0" or stripped == "0.0" or stripped == "0.00":
		return false

	# If it's a valid float, check if it's zero
	if stripped.is_valid_float():
		return float(stripped) > 0.0

	# It's an expression - assume it's meaningful
	return true


## Builds label segments for a guard expression.
##
## Guard types are rendered as follows:
## - StateIsActiveGuard: "in <state name>" (italic "in", bold state name)
## - ExpressionGuard: expression in monospace
## - NotGuard: !(<inner>)
## - AllOfGuard: (<inner> & <inner> & ...)
## - AnyOfGuard: (<inner> | <inner> | ...)
static func _build_guard_expression(guard: Guard, transition: Transition) -> Array[VisualLabelSegment]:
	if guard == null:
		return []

	# StateIsActiveGuard: render as "in <state name>"
	if guard is StateIsActiveGuard:
		return _build_state_is_active_guard(guard as StateIsActiveGuard, transition)

	# ExpressionGuard: render expression in monospace
	if guard is ExpressionGuard:
		return _build_expression_guard(guard as ExpressionGuard)

	# NotGuard: render as !(<inner>)
	if guard is NotGuard:
		return _build_not_guard(guard as NotGuard, transition)

	# AllOfGuard: render as (<inner> & <inner> & ...)
	if guard is AllOfGuard:
		return _build_all_of_guard(guard as AllOfGuard, transition)

	# AnyOfGuard: render as (<inner> | <inner> | ...)
	if guard is AnyOfGuard:
		return _build_any_of_guard(guard as AnyOfGuard, transition)

	# Unknown guard type - return empty (graceful degradation)
	return []


## Builds segments for a StateIsActiveGuard.
## Displays as "in <state name>" with italic "in" and bold state name.
static func _build_state_is_active_guard(guard: StateIsActiveGuard, transition: Transition) -> Array[VisualLabelSegment]:
	if guard.state == null or guard.state.is_empty():
		return []

	# Try to resolve the state name from the node path
	var state_name := _extract_state_name_from_path(guard.state, transition)
	if state_name.is_empty():
		return []

	var result: Array[VisualLabelSegment] = []
	result.append(VisualLabelSegment.new("in ", VisualLabelSegment.Style.ITALIC))
	result.append(VisualLabelSegment.new(state_name, VisualLabelSegment.Style.BOLD))
	return result


## Extracts a readable state name from a NodePath.
## Tries to resolve the actual node first, falls back to path parsing.
static func _extract_state_name_from_path(path: NodePath, transition: Transition) -> String:
	assert(is_instance_valid(transition))
	if path.is_empty():
		return ""

	# Try to resolve the actual node to get its name
	var node := transition.get_node_or_null(path)
	if node != null:
		return node.name

	# Fallback: extract the last component of the path
	var name_count := path.get_name_count()
	if name_count > 0:
		return path.get_name(name_count - 1)
	
	return ""


## Builds segments for an ExpressionGuard.
## Displays the expression in monospace font.
static func _build_expression_guard(guard: ExpressionGuard) -> Array[VisualLabelSegment]:
	assert(is_instance_valid(guard))
	var expr: String = guard.expression
	if expr.is_empty():
		return []

	return [VisualLabelSegment.new(expr, VisualLabelSegment.Style.MONO)]


## Builds segments for a NotGuard.
## Displays as !(<inner guard expression>).
static func _build_not_guard(guard: NotGuard, transition: Transition) -> Array[VisualLabelSegment]:
	assert(is_instance_valid(guard))
	assert(is_instance_valid(transition))
	var inner_guard: Guard = guard.guard
	if inner_guard == null:
		# No inner guard configured - skip this guard entirely
		return []

	var inner_segments := _build_guard_expression(inner_guard, transition)
	if inner_segments.is_empty():
		return []

	var result: Array[VisualLabelSegment] = []
	result.append(VisualLabelSegment.new("!(", VisualLabelSegment.Style.MONO))
	result.append_array(inner_segments)
	result.append(VisualLabelSegment.new(")", VisualLabelSegment.Style.MONO))
	return result


## Builds segments for an AllOfGuard.
## Displays as (<inner> & <inner> & ...).
## Even with a single guard, parentheses are kept for consistency.
static func _build_all_of_guard(guard: AllOfGuard, transition: Transition) -> Array[VisualLabelSegment]:
	assert(is_instance_valid(guard))
	assert(is_instance_valid(transition))
	var guards: Array[Guard] = guard.guards
	if guards.is_empty():
		return []

	# Collect all valid inner guard expressions
	var inner_expressions: Array = []
	for inner_guard in guards:
		if inner_guard == null:
			continue
		var segments := _build_guard_expression(inner_guard, transition)
		if not segments.is_empty():
			inner_expressions.append(segments)

	if inner_expressions.is_empty():
		return []

	var result: Array[VisualLabelSegment] = []
	result.append(VisualLabelSegment.new("(", VisualLabelSegment.Style.MONO))

	for i in range(inner_expressions.size()):
		if i > 0:
			result.append(VisualLabelSegment.new(" & ", VisualLabelSegment.Style.MONO))
		result.append_array(inner_expressions[i])

	result.append(VisualLabelSegment.new(")", VisualLabelSegment.Style.MONO))
	return result


## Builds segments for an AnyOfGuard.
## Displays as (<inner> | <inner> | ...).
## Even with a single guard, parentheses are kept for consistency.
static func _build_any_of_guard(guard: AnyOfGuard, transition: Transition) -> Array[VisualLabelSegment]:
	assert(is_instance_valid(guard))
	assert(is_instance_valid(transition))
	
	var guards: Array[Guard] = guard.guards
	if guards.is_empty():
		return []

	# Collect all valid inner guard expressions
	var inner_expressions: Array = []
	for inner_guard in guards:
		if inner_guard == null:
			continue
		var segments := _build_guard_expression(inner_guard, transition)
		if not segments.is_empty():
			inner_expressions.append(segments)

	if inner_expressions.is_empty():
		return []

	var result: Array[VisualLabelSegment] = []
	result.append(VisualLabelSegment.new("(", VisualLabelSegment.Style.MONO))

	for i in range(inner_expressions.size()):
		if i > 0:
			result.append(VisualLabelSegment.new(" | ", VisualLabelSegment.Style.MONO))
		result.append_array(inner_expressions[i])

	result.append(VisualLabelSegment.new(")", VisualLabelSegment.Style.MONO))
	return result


