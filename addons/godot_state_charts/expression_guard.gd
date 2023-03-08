@tool
class_name ExpressionGuard
extends Guard

var expression:String = ""


func is_satisfied() -> bool:
	var the_expression := Expression.new()
	var parse_result = the_expression.parse(expression)
	if parse_result != OK:
		push_error("Expression parse error: " + the_expression.get_error_text())
		return false

	var result = the_expression.execute()
	if the_expression.has_execute_failed():
		push_error("Expression execute error: " + the_expression.get_error_text())
		return false

	if result.get_type() != TYPE_BOOL:
		push_error("Expression result is not a boolean")
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