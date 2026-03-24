@tool

extends ConfirmationDialog

const StateChartUtil = preload("../state_chart_util.gd")

@onready var _event_list:ItemList = %EventList
@onready var _event_name_edit:LineEdit = %EventNameEdit
@onready var _warning_label:Label = %WarningLabel

var _chart:StateChart
var _undo_redo:EditorUndoRedoManager

func open(chart:StateChart, undo_redo:EditorUndoRedoManager, pre_select_event:StringName) -> void:
	title = "Events of " + chart.name
	_chart = chart
	_undo_redo = undo_redo
	_refresh_events()
	_select_event(pre_select_event)
	_update_buttons()
	popup_centered()


func _refresh_events() -> void:
	_event_list.clear()
	for item in StateChartUtil.events_of(_chart):
		_event_list.add_item(item)


## Selects the given event. If it does not exist, selects the 
## first event in the list. If the list is empty, selects nothing.
func _select_event(event_name:StringName) -> void:
	for i in _event_list.item_count:
		if _event_list.get_item_text(i) == event_name:
			_event_list.select(i)
			_event_name_edit.text = event_name
			return

	if _event_list.item_count > 0:
		_event_list.select(0)
		_event_name_edit.text = _event_list.get_item_text(0)
		return
		
	_event_name_edit.text = ""


func _show_warning(text:String) -> void:
	if text == "":
		_warning_label.visible = false
		return
	_warning_label.text = text
	_warning_label.visible = true


## Returns the name of the currently selected event.
func _get_selected_event_name() -> StringName:
	var items := _event_list.get_selected_items()
	if items.size() != 1:
		return ""
		
	return _event_list.get_item_text(items[0]) 


func _update_buttons() -> void:
	_show_warning("")
	get_ok_button().disabled = false

	if not _event_list.is_anything_selected():
		get_ok_button().disabled = true		
		_show_warning("Please select an event in the list to rename it.")
		return
	
	# disable rename button if the event name is the same as the 
	# currently selected event. The if above ensures we have an event 
	# selected.
	if _event_name_edit.text == _get_selected_event_name():
		get_ok_button().disabled = true		
		# but show no warning for it, as this is pretty much
		# self-evident and the user shouldn't be immediately
		# greeted by a warning


func _close() -> void:
	hide()
	queue_free()


func _on_event_list_item_selected(index:int) -> void:
	_event_name_edit.text = _event_list.get_item_text(index)
	_update_buttons()

	
func _on_event_name_edit_text_changed(new_text) -> void:
	_update_buttons()
		

func _on_confirmed() -> void:
	var old_event_name := _get_selected_event_name()
	var new_event_name := _event_name_edit.text
	var transitions = StateChartUtil.transitions_of(_chart)
	_undo_redo.create_action("Rename state chart event")
	for transition in transitions:
		if transition.event == old_event_name:
			_undo_redo.add_do_property(transition, "event", new_event_name)
			_undo_redo.add_undo_property(transition, "event", old_event_name)
	_undo_redo.commit_action()
	_close()
