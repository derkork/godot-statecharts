@tool
@icon("expression_guard.svg")
class_name ExpressionGuard
extends Guard

var expression:String = ""


func is_satisfied(context_transition:Transition, context_state:StateChartState) -> bool:
	# walk up the tree to find the root state chart node
	var root = context_state

	while is_instance_valid(root) and not root is StateChart:
		root = root.get_parent()
	
	if not is_instance_valid(root):
		push_error("Could not find root state chart node, cannot evaluate expression")
		return false

	var the_expression := Expression.new()
	var input_names = root._expression_properties.keys()

	var parse_result = the_expression.parse(expression, input_names)

	if parse_result != OK:
		push_error("Expression parse error: " + the_expression.get_error_text() + " for expression " + expression)
		return false

	# input values need to be in the same order as the input names, so we build an array
	# of values
	var input_values = []
	for input_name in input_names:
		input_values.append(root._expression_properties[input_name])

	var result = the_expression.execute(input_values)
	if the_expression.has_execute_failed():
		push_error("Expression execute error: " + the_expression.get_error_text() + " for expression: " + expression)
		return false

	if typeof(result) != TYPE_BOOL:
		push_error("Expression result is not a boolean. Returning false.")
		return false

	return result


func _get_property_list():
	var properties = []
	properties.append({
		"name": "expression",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_EXPRESSION
	})

	return properties
