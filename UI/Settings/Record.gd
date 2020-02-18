extends HBoxContainer


onready var play = get_node("Play")
onready var pause = get_node("Pause")
onready var stop = get_node("Stop")


# change the toggle based on the UI signals
func _ready():
	play.connect("pressed", self, "play")
	pause.connect("pressed", self, "pause")
	stop.connect("pressed", self, "stop")


# if we start tracking emit the signal and hide the button
func play():
		GlobalSignal.emit_signal("tracking_start")
		play.set_visible(false)
		stop.set_visible(true)
		pause.set_visible(true)


# if we start tracking emit the signal and hide the button
func pause():
		GlobalSignal.emit_signal("tracking_pause")
		pause.set_visible(false)
		play.set_visible(true)
		stop.set_visible(true)



# if we stop tracking emit the signal and hide the button
func stop():
		GlobalSignal.emit_signal("tracking_stop")
		stop.set_visible(false)
		pause.set_visible(false)
		play.set_visible(true)
