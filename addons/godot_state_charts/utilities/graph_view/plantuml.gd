@tool

## Renders the given state chart as plant uml
static func as_plantuml(chart:StateChart, preamble:String = "") -> String:
	var root = Block.new("@startuml", "@enduml")
	root.nest("hide empty description")
	root.nest(preamble)
	
	for child in chart.get_children():
		if child is StateChartState:
			root.nest(state(child))
			break
			
	
	return root.render()
	
	
static func state(value:StateChartState) -> Block:
	if value is AtomicState:
		return atomic_state(value)
	if value is CompoundState:
		return compound_state(value)
	if value is ParallelState:
		return parallel_state(value) 
	if value is HistoryState:
		return history_state(value)	
		
	return Block.new()
	
static func atomic_state(value:AtomicState) -> Block:
	var result = Block.new()
	var state = state_wrapper(value)
	result.nest(state)
	
	transitions(value, result)
	return result
	
	
static func compound_state(value:CompoundState) -> Block:
	var result = Block.new()

	var state = state_wrapper(value)
	result.nest(state)
	
	var initial_state = value.get_node_or_null(value.initial_state)
	if initial_state != null:
		state.nest(implicit_transition("[*]", initial_state))

	for child in value.get_children():
		if child is StateChartState:
			state.nest(state(child))
			
	
	transitions(value, result)
	
	return result

			
static func parallel_state(value:ParallelState) -> Block:
	var result = Block.new()
	var state = state_wrapper(value)
	result.nest(state)
	
	var substates = []
	for child in value.get_children():
		if child is StateChartState:
			substates.append(state(child))
			
	# make sure we only add "--" when needed otherwise the rendering will look off
	for i in substates.size():
		state.nest(substates[i])
		if i + 1 < substates.size():
			state.nest("--")
	
	transitions(value, result)
	return result
	
		
static func history_state(value:HistoryState) -> Block:
	var result = Block.new()
	var default_state = value.get_node_or_null(value.default_state)
	if default_state != null:
		result.nest(implicit_transition("[H*]" if value.deep else "[H]", default_state, "[dotted]"))
	
	return result
		
		
	
static func state_wrapper(value:StateChartState) -> Block:
	var id = uniq(value.get_path())
	# wrapper block
	var result = Block.new("state %s as %s {" % [stringify(value.name), id] , "}")	
	
	# description. cannot be multiline so we need to split this.
	var lines = wrap_long(value.editor_description)
	for line in lines:
		result.nest("%s: %s" % [id, line])
	
	return result
	
static func transitions(value:StateChartState, block:Block):
	for child in value.get_children():
		if child is Transition:
			block.nest(transition(child, value))				
	
	
static func implicit_transition(source:String, target:StateChartState, style:String = "") -> String:
	return "%s -%s-> %s" % [source, style, target_path(target)]
	

static func transition(transition:Transition, source:StateChartState) -> Block:
	var destination = transition.resolve_target()
	if destination == null:
		return Block.new()
	
	var description = ""
	if not transition.event.is_empty():
		description += italics(transition.event)
		
	if transition.guard != null:
		if not description.is_empty():
			description += " "
		description += "[%s]" % guard(transition.guard, transition)	
	
	if transition.delay_in_seconds.is_valid_float() and float(transition.delay_in_seconds) > 0:
		if not description.is_empty():
			description += " "
		description += "after %ss" % transition.delay_in_seconds	
	
	elif not transition.delay_in_seconds.is_valid_float() and not transition.delay_in_seconds.is_empty():
		if not description.is_empty():
			description += " "
		description += "after (%s)s" % monospaced(transition.delay_in_seconds)	
		
	if not description.is_empty():
		description = ": " + description
		
	return Block.new("%s --> %s%s" % [uniq(source.get_path()), target_path(destination), description])
	
	
static func target_path(state:StateChartState) -> String:
	if not state is HistoryState:
		return uniq(state.get_path())
		
	var owner = state.get_parent()
	if not owner is StateChartState:
		return "??"
		
	return "%s%s" % [uniq(owner.get_path()), "[H*]" if state.deep else "[H]"] 
	
static func guard(guard:Guard, context:Transition) -> String:
	if guard is AllOfGuard:
		return combine_guards(guard.guards, " and ", context)
	if guard is AnyOfGuard:
		return combine_guards(guard.guards, " or ", context)
	if guard is NotGuard:
		return "%s%s" % [monospaced("not "), guard(guard.guard, context)]
	if guard is ExpressionGuard:
		return monospaced(guard.expression)
	if guard is StateIsActiveGuard:
		var state = context.get_node_or_null(guard.state)
		var name = "??" if state == null else state.name
		return 	"%s is active" % italics(name)
	return ""
		
static func combine_guards(guards:Array[Guard], op:String, context:Transition):
	var parts:Array[String] = []
	parts.resize(guards.size())
	
	for i in guards.size():
		parts[i] = guard(guards[i], context)
		
	return "(%s)" % op.join(parts)
		
	
static func uniq(path:NodePath):
	return str(path).md5_text()	

	
static func wrap_long(text:String, max_line:int = 40) -> Array[String]:
	var parts = text.replace("\n", " ").split(" ")
	var result:Array[String] = []
	var line  = ""
	for part in parts:
		if not line.is_empty() and (line.length() + part.length()) > max_line:
			result.append(line)
			line = ""
		if not line.is_empty():
			line += " "
		line += part
	
	if not line.is_empty():
		result.append(line)
		
	return result
		
static func monospaced(text:String):
	return "\"\"%s\"\"" % text 	
	
static func italics(text:String):
	return "//%s//" % text
	
static func stringify(text:String):
	return JSON.stringify(text)
	
class Block:
	var prefix:String
	var suffix:String
	var content:Array = []
	
	func _init(p:String = "", s:String = ""):
		prefix = p
		suffix = s
		
	func nest(value):
		content.append(value)
		
	func render() -> String:
		var result = prefix + "\n"
		for item in content:
			if item is Block:
				result += item.render()
			else: 
				result += str(item)
			result += "\n"
			
		result += suffix + "\n"
		return result



