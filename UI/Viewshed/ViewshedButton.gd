extends "res://UI/Tools/ToolsButton.gd"


var pc_player: AbstractPlayer


func _ready():
	connect("toggled", self, "_on_toggle")


func _on_toggle(toggled: bool):
	pc_player.action_handler.enable_viewshed(toggled)
