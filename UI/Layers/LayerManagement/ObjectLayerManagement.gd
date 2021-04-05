extends AbstractLayerManagement


var edit_cursor = preload("res://Resources/Icons/ModernLandscapeLab/paintbrush.svg")
var edit_action: ActionHandler.Action


func _ready():
	$EditPoints.connect("toggled", self, "_on_edit")


func set_player(player):
	.set_player(player)
	edit_action = EditAction.new(layer, pc_player.action_handler.cursor, pos_manager, pc_player, false)


class EditAction extends ActionHandler.Action:
	var cursor: RayCast
	var layer: Layer
	var pos_manager: PositionManager
	
	func _init(l, c, p_m, p, blocking).(p, blocking):
		cursor = c
		layer = l
		pos_manager = p_m
	
	func apply(event: InputEvent):
		if event.is_action_pressed("layer_add_feature"):
			var new_feature = layer.create_feature()
			
			var global_center = pos_manager.get_center()
			new_feature.set_offset_vector3(cursor.get_collision_point(), 
					global_center[0], 0, global_center[1])


func _on_edit(toggled):
	if toggled:
		pc_player.action_handler.set_current_action(edit_action, edit_cursor)
	else:
		pc_player.action_handler.stop_current_action()
