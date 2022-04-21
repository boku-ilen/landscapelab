extends "res://UI/Tools/ToolsButton.gd"
tool


var pc_player: AbstractPlayer


func _ready():
	connect("toggled", self, "_on_toggle")


func _on_toggle(toggled: bool):
	pc_player.get_node("Head/Camera/MousePoint/MouseCollisionIndicator/TransformReset/Particle/OmniLight").visible = toggled
