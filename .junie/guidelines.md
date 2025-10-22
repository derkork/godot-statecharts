
## Code guidelines
Always add GDScript type hints everywhere. When referring to nodes, always use scene unique names instead of paths. Always initialize node references in an `@onready` variable rather than littering the code with inline node references. Always use `is_instance_valid` for null checks. GDScripts should always end with an empty line. All `@onready` variables are private and need to start with an underscore. For emitting signals, always use the type-safe variant, e.g. `my_signal.emit()` rather than `emit_signal("my_signal")`. Use tabs for indentation.

## Writing tests
The test framework does not stop execution on failed assertions, so make sure the code after an assertion doesn't assume that the assertion was successful. 

## Running tests
To run tests, you can invoke the `run_tests.bat` file in the project root. You can specify the following arguments:

- run a list of comma separated tests with:
  ```
  run_tests.bat -gtest=res://path/to/test1.gd,res://path/to/test2.gd`. 
  ```
- run all tests in a folder with:
  ```
  run_tests.bat -gdir=res://some/folder`
  ```
- run a specific test method with:
  ```
  run_tests.bat -gtest=res://path/to/test1.gd -gunit_test_name=test_some_method          
  ```

All tests are located in the `tests` folder, so to run all tests you can run:

```
run_tests.bat -gdir=res://tests
```

