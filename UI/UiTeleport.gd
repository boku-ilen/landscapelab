@tool
extends "res://UI/Tools/ToolsButton.gd"


var pc_player: AbstractPlayer :
	get:
		return pc_player 
	set(player):
		pc_player = player
		teleport_action = TeleportAction.new(pc_player.action_handler.cursor, pc_player, false)


var pos_manager
var teleport_action

class TeleportAction extends ActionHandler.Action:
	var cursor
	
	func _init(c,p,b):
		super._init(p, b)
		
		cursor = c
	
	func apply(event):
		if event.is_action_pressed("teleport_player"):
			player.teleport(cursor.get_collision_point() + Vector3.UP * 3)


func _ready():
	connect("toggled",Callable(self,"_on_toggle"))
	
	if has_node("Window/PoI/VBoxContainer/ItemList"):
		$Window/PoI/VBoxContainer/ItemList.connect("item_activated",Callable(self,"_on_poi_activated"))


func _on_toggle(toggled: bool):
	button_pressed = toggled
	if toggled:
		pc_player.action_handler.set_current_action(teleport_action)
	else:
		pc_player.action_handler.stop_current_action()
		$Window.hide()


# We saved the location coordinates in the metadata of the list items,
# if one is clicked handle the teleport manually here
func _on_poi_activated(index):
	var engine_cords = pos_manager.to_engine_coordinates($Window/PoI/VBoxContainer/ItemList.get_item_metadata(index))
	pc_player.teleport(Vector3(engine_cords.x, pc_player.transform.origin.y, engine_cords.y))
	_on_toggle(false)
