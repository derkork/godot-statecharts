class_name SignalSensor
extends Sensor

@export var event_to_send: String

func receive_signal0():
	send_event(event_to_send)

func receive_signal1():
	send_event(event_to_send)

func receive_signal2():
	send_event(event_to_send)

func receive_signal3():
	send_event(event_to_send)

func receive_signal4():
	send_event(event_to_send)

func receive_signal5():
	send_event(event_to_send)

func receive_signal6():
	send_event(event_to_send)