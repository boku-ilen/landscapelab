extends "res://UI/Tools/ToolsButton.gd"

var pc_player: AbstractPlayer :
	get:
		return pc_player
	set(player):
		pc_player = player
		var parent_tracker = player.get_node("ParentTracker") 
		connect("tracking_start",Callable(parent_tracker,"start_tracking").bind(),CONNECT_DEFERRED)
		connect("tracking_pause",Callable(parent_tracker,"toggle_pause_tracking").bind(),CONNECT_DEFERRED)
		connect("tracking_stop",Callable(parent_tracker,"stop_tracking").bind(),CONNECT_DEFERRED)

@onready var play_button = get_node("Record/Play")
@onready var pause_button = get_node("Record/Pause")
@onready var stop_button = get_node("Record/Stop")

signal tracking_start
signal tracking_pause
signal tracking_stop


# change the toggle based checked the UI signals
func _ready():
	play_button.connect("pressed",Callable(self,"play"))
	pause_button.connect("pressed",Callable(self,"pause"))
	stop_button.connect("pressed",Callable(self,"stop"))


# if we start tracking emit the signal and hide the button
func play():
		emit_signal("tracking_start")
		play_button.set_visible(false)
		stop_button.set_visible(true)
		pause_button.set_visible(true)


# if we start tracking emit the signal and hide the button
func pause():
		emit_signal("tracking_pause")
		pause_button.set_visible(false)
		play_button.set_visible(true)
		stop_button.set_visible(true)



# if we stop tracking emit the signal and hide the button
func stop():
		emit_signal("tracking_stop")
		stop_button.set_visible(false)
		pause_button.set_visible(false)
		play_button.set_visible(true)
