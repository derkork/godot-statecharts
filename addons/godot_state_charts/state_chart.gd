@icon("state_chart.svg")
@tool
## This is statechart. It contains a root state (commonly a compound or parallel state) and is the entry point for 
## the state machine.
class_name StateChart 
extends Node

## The the remote debugger
const DebuggerRemote = preload("utilities/editor_debugger/editor_debugger_remote.gd")

## Emitted when the state chart receives an event. This will be 
## emitted no matter which state is currently active and can be 
## useful to trigger additional logic elsewhere in the game 
## without having to create a custom event bus. It is also used
## by the state chart debugger. Note that this will emit the 
## events in the order in which they are processed, which may 
## be different from the order in which they were received. This is
## because the state chart will always finish processing one event
## fully before processing the next. If an event is received
## while another is still processing, it will be enqueued.
signal event_received(event:StringName)

## Flag indicating if this state chart should be tracked by the 
## state chart debugger in the editor.
@export var track_in_editor:bool = false

## The root state of the state chart.
var _state:State = null

## This dictonary contains known properties used in expression guards. Use the 
## [method set_expression_property] to add properties to this dictionary.
var _expression_properties:Dictionary = {
}

## A list of events which are still pending resolution.
var _queued_events:Array[StringName] = []

## Flag indicating if the state chart is currently processing an 
## event. Until an event is fully processed, new events will be queued
## and then processed later.
var _event_processing_active:bool = false


var _queued_transitions:Array[Dictionary] = []
var _transitions_processing_active:bool = false


var _debugger_remote:DebuggerRemote = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return 

	# check if we have exactly one child that is a state
	if get_child_count() != 1:
		push_error("StateChart must have exactly one child")
		return

	# check if the child is a state
	var child = get_child(0)
	if not child is State:
		push_error("StateMachine's child must be a State")
		return

	# initialize the state machine
	_state = child as State
	_state._state_init()

	# enter the state
	_state._state_enter.call_deferred()

	# if we are in an editor build and this chart should be tracked 
	# by the debugger, create a debugger remote
	if track_in_editor and OS.has_feature("editor"):
		_debugger_remote = DebuggerRemote.new(self)


## Sends an event to this state chart. The event will be passed to the innermost active state first and
## is then moving up in the tree until it is consumed. Events will trigger transitions and actions via emitted
## signals. There is no guarantee when the event will be processed. The state chart
## will process the event as soon as possible but there is no guarantee that the 
## event will be fully processed when this method returns.
func send_event(event:StringName) -> void:
	if not is_instance_valid(_state):
		push_error("StateMachine is not initialized")
		return
		
	if _event_processing_active:
		# the state chart is currently processing an event
		# therefore queue the event and process it later.
		_queued_events.append(event)
		return	

	# enable the reentrance lock for event processing
	_event_processing_active = true
	
	# first process this event.
	event_received.emit(event)
	_state._state_event(event)
	
	# if other events have accumulated while the event was processing
	# process them in order now
	while _queued_events.size() > 0:
		var next_event = _queued_events.pop_front()
		event_received.emit(next_event)
		_state._state_event(next_event)
		
	_event_processing_active = false

## Allows states to queue a transition for running. This will eventually run the transition
## once all currently running transitions have finished. States should call this method
## when they want to transition away from themselves. 
func _run_transition(transition:Transition, source:State):
	# if we are currently inside of a transition, queue it up
	if _transitions_processing_active:
		_queued_transitions.append({transition : source})
		return

	# we can only transition away from a currently active state
	# if for some reason the state no longer is active, ignore the transition	
	_do_run_transition(transition, source)
	
	# if we still have transitions
	while _queued_transitions.size() > 0:
		var next_transition_entry = _queued_transitions.pop_front()
		var next_transition = next_transition_entry.keys()[0]
		var next_transition_source = next_transition_entry[next_transition]
		_do_run_transition(next_transition, next_transition_source)


## Runs the transition. Used internally by the state chart, do not call this directly.	
func _do_run_transition(transition:Transition, source:State):
	if source.active:
		# Notify interested parties that the transition is about to be taken
		transition.taken.emit()
		source._handle_transition(transition, source)
	else:
		_warn_not_active(transition, source)	


func _warn_not_active(transition:Transition, source:State):
	push_warning("Ignoring request for transitioning from ", source.name, " to ", transition.to, " as the source state is no longer active. Check whether your trigger multiple state changes within a single frame.")

## Sets a property that can be used in expression guards. The property will be available as a global variable
## with the same name. E.g. if you set the property "foo" to 42, you can use the expression "foo == 42" in
## an expression guard.
func set_expression_property(name:StringName, value) -> void:
	_expression_properties[name] = value


## Calls the `step` function in all active states. Used for situations where `state_processing` and 
## `state_physics_processing` don't make sense (e.g. turn-based games, or games with a fixed timestep).
func step():
	_state._state_step()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if get_child_count() != 1:
		warnings.append("StateChart must have exactly one child")
	else:
		var child = get_child(0)
		if not child is State:
			warnings.append("StateChart's child must be a State")
	return warnings
