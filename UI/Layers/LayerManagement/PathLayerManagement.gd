extends AbstractLayerManagement


var edit_cursor = preload("res://Resources/Icons/ModernLandscapeLab/paintbrush.svg")
var edit_action: ActionHandler.Action


func _ready():
	$Edit.connect("toggled",Callable(self,"_on_edit"))


func set_player(player):
	super.set_player(player)
	edit_action = EditAction.new(layer, pc_player.action_handler.cursor, pc_player, false)


class EditAction extends ActionHandler.Action:
	var cursor: RayCast3D
	var layer: Layer
	var path: Path3D
	
	func _init(l,c,p,blocking):
		super._init(p,blocking)
		
		cursor = c
		layer = l
		path = layer.render_info.line_visualization.instantiate()#load("res://Street.tscn").instantiate()
		player.get_parent().add_child(path)
#		var vis = CSGPolygon3D.new()
#		vis.material = Material.new()
#		path.visualizer = vis
	
	func new_path():
		path = layer.render_info.line_visualization.instantiate()
		player.get_parent().get_node("Terrain").add_child(path)
	
	func apply(event: InputEvent):
		if event.is_action_pressed("layer_add_feature"):
			var new_feature = layer.create_feature()
			new_feature.set_vector3(cursor.get_collision_point())
		if event.is_action_pressed("layer_end_feature"):
			# FIXME: Finishing logic ...
			path = null


func _on_edit(toggled):
	if toggled:
		pc_player.action_handler.set_current_action(edit_action, edit_cursor)
	else:
		pc_player.action_handler.stop_current_action()
