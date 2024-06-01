extends StateChartTestBase

func test_expression_properties():
	# set some initial expression properties
	set_initial_expression_properties({
		"foo": "bar",
		"baz": "qux"
	})

	# some dummy states, we don't need them
	var root := compound_state("root")
	atomic_state("a", root)

	await finish_setup()
	
	# the initial expression properties should be set
	assert_eq(get_expression_property("foo"), "bar")

	# if we set a new expression property
	set_expression_property("foo", "baz")

	# the new value should be returned
	assert_eq(get_expression_property("foo"), "baz")
