extends "res://UI/Tools/ToolsButton.gd"

var pc_player: AbstractPlayer setget set_player

onready var play = get_node("WindowDialog/Record/Play")
onready var pause = get_node("WindowDialog/Record/Pause")
onready var stop = get_node("WindowDialog/Record/Stop")

signal tracking_start
signal tracking_pause
signal tracking_stop


# change the toggle based on the UI signals
func _ready():
	play.connect("pressed", self, "play")
	pause.connect("pressed", self, "pause")
	stop.connect("pressed", self, "stop")


# Connect the signals of the UI buttons from here with the parent tracker
# which MUST be a child node of the player
func set_player(player: AbstractPlayer):
	pc_player = player
	var parent_tracker = player.get_node("ParentTracker") 
	connect("tracking_start", parent_tracker, "start_tracking", [], CONNECT_DEFERRED)
	connect("tracking_pause", parent_tracker, "toggle_pause_tracking", [], CONNECT_DEFERRED)
	connect("tracking_stop", parent_tracker, "stop_tracking", [], CONNECT_DEFERRED)


# if we start tracking emit the signal and hide the button
func play():
		emit_signal("tracking_start")
		play.set_visible(false)
		stop.set_visible(true)
		pause.set_visible(true)


# if we start tracking emit the signal and hide the button
func pause():
		emit_signal("tracking_pause")
		pause.set_visible(false)
		play.set_visible(true)
		stop.set_visible(true)



# if we stop tracking emit the signal and hide the button
func stop():
		emit_signal("tracking_stop")
		stop.set_visible(false)
		pause.set_visible(false)
		play.set_visible(true)
