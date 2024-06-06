extends StateChartTestBase

# This tests that property changes are immediately visible to all guards.
# see https://github.com/derkork/godot-statecharts/issues/82#issuecomment-1963417766
func test_property_changes_immediately_visible():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	var c := atomic_state("c", root)
	
	var d := atomic_state("d", root)
	var e := atomic_state("e", root)
	
	transition(a, b, "to_b")
	transition(b, c)
	transition(c, d, "", "0", expression_guard("x > 0"))
	transition(c, e, "", "0", expression_guard("x = 0"))
	

	a.state_entered.connect(func(): set_expression_property("x", 0))
	b.state_entered.connect(func(): set_expression_property("x", 1))
	await finish_setup()
	
	# root state is active
	assert_active(a)

	# when I transition to b
	send_event("to_b")
	
	# then b is entered, which sets x to 1
	# then c is entered and because x is 1, d is entered
	assert_active(d)
	assert_inactive(e)
	assert_inactive(a)
	assert_inactive(b)
	assert_inactive(c)
