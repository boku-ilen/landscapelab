extends HBoxContainer

export var viewport_path: NodePath
onready var viewport = get_node(viewport_path)

export var position_manager_path: NodePath
onready var position_manager = get_node(position_manager_path)

var selected_collection


func _ready():
	if not GameSystem.current_game_mode:
		visible = false
		return
	
	if GameSystem.current_game_mode is TurnBasedGameMode:
		add_child(preload("res://UI/GameSystem/TurnBasedMenu.tscn").instance())
	
	for collection in GameSystem.current_game_mode.game_object_collections.values():
		$GameObjects/GameObjectCollections.add_item(collection.name)
	
	$GameObjects/GameObjectCollections.connect("item_selected", self, "_on_game_object_collection_selected")
	
	for score in GameSystem.current_game_mode.game_scores.values():
		var score_ui = preload("res://UI/GameSystem/ScoreUI.tscn").instance()
		score_ui.score = score
		$Scores.add_child(score_ui)


func _on_game_object_collection_selected(item_id):
	var item_name = $GameObjects/GameObjectCollections.get_item_text(item_id)
	selected_collection = GameSystem.current_game_mode.game_object_collections[item_name]


func _input(event):
	if selected_collection and event.is_action_pressed("layer_add_feature"):
		var mousepos = viewport.get_mouse_position()
		var origin = viewport.get_camera().project_ray_origin(mousepos)
		var normal = origin + viewport.get_camera().project_ray_normal(mousepos) * 10000
		
		var space_state = viewport.get_node("World").get_world().direct_space_state
		var result = space_state.intersect_ray(origin, normal)
		
		if result:
			var global_center = position_manager.get_center()
			var global_position = result.position \
					+ Vector3(global_center[0], 0, -global_center[1])
			
			var new_game_object = GameSystem.create_new_game_object(
					selected_collection, global_position
			)
			
			# TODO: Check whether new_game_object is null, give feedback that creation was not allowed here
