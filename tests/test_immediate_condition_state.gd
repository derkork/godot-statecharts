extends StateChartTestBase

# This tests a condition state where the target states are immediate children of the source state
# but the source state holds all the transitions.
func test_immediate_condition_state():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	var c := atomic_state("c", root)
	
	
	transition(root, a, "", "0", expression_guard("state == 'a'"))
	transition(root, b, "", "0", expression_guard("state == 'b'"))
	transition(root, c, "", "0", expression_guard("state == 'c'"))
	
	set_initial_expression_properties({"state": "a"})

	await finish_setup()
	
	# root state is active
	assert_active(a)
	assert_inactive(b)
	assert_inactive(c)
	
	# WHEN: i change the property to enter state b
	set_expression_property("state", "b")
	
	# THEN: state b is active
	assert_active(b)
	assert_inactive(a)
	assert_inactive(c)
	
	# WHEN: i change the property to enter state c
	set_expression_property("state", "c")
	
	# THEN: state c is active
	assert_active(c)
	assert_inactive(a)
	assert_inactive(b)
	
	# WHEN: i change the property to enter state a
	set_expression_property("state", "a")
	
	# THEN: state a is active
	assert_active(a)
	assert_inactive(b)
	assert_inactive(c)
