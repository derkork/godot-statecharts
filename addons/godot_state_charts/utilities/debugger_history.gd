const RingBuffer = preload("ring_buffer.gd")

var _buffer:RingBuffer = null

var _dirty:bool = false

## Whether the history has changed since the full
## history string was last requested.
var dirty:bool:
	get: return _dirty

func _init(maximum_lines:int = 500):
	_buffer = RingBuffer.new(maximum_lines)
	_dirty = false


## Adds an item to the history list.
func add_history_entry(text:String):
	_buffer.append("[%s]: %s \n" % [Engine.get_process_frames(), text])
	_dirty = true


## Adds a transition to the history list.
func add_transition(name:String, from:String, to:String):
	add_history_entry("Transition: %s from %s to %s" % [name, from, to])


## Adds an event to the history list.
func add_event(event:StringName):
	add_history_entry("Event received: %s" % event)


## Adds a state entered event to the history list.
func add_state_entered(name:StringName):
	add_history_entry("Enter: %s" % name)


## Adds a state exited event to the history list.
func add_state_exited(name:StringName):
	add_history_entry("exiT: %s" % name)


## Clears the history.
func clear():
	_buffer.clear()
	_dirty = true


## Returns the full history as a string.
func get_history_text():
	_dirty = false
	return _buffer.join()
