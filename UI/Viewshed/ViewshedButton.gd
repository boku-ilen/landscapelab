@tool
extends "res://UI/Tools/ToolsButton.gd"


var pc_player: AbstractPlayer


func _ready():
	connect("toggled",Callable(self,"_on_toggle"))


func _on_toggle(toggled: bool):
	pc_player.get_node("Head/Camera3D/MousePoint/MouseCollisionIndicator/TransformReset/Particle/OmniLight3D").visible = toggled
