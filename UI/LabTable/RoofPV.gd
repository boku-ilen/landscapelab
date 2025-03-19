extends Sprite2D

# FIXME: REMOVE THIS HARCODED JUNK!

var toggled := false
const active_tex := preload("res://Resources/Icons/ModernLandscapeLab/roof_pv_active.svg")
const inactive_tex := preload("res://Resources/Icons/ModernLandscapeLab/roof_pv.svg")


func _ready():
	GameSystem.game_mode_changed.connect(func(): visible = !visible)


func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		if get_rect().has_point(to_local(event.position)):
			if event.button_index == MOUSE_BUTTON_LEFT:
				toggled = !toggled
				_toggle_texture(toggled)
				_toggle_roof_pv(toggled)
			
			get_viewport().set_input_as_handled()


func _toggle_texture(is_toggled: bool):
	if toggled:
		texture = active_tex
	else:
		texture = inactive_tex


func _toggle_roof_pv(toggled: bool):
	if toggled:
		var game_collection = GameObjectCollection.new("Roof PV")
		GameSystem.current_game_mode.add_game_object_collection(game_collection)
		
		var attrib = StaticAttribute.new("Roof PV", 20000.)
		game_collection.add_attribute_mapping(attrib)
		
		game_collection.game_objects[0] = GameObject.new(0, game_collection)
		
		#GameSystem.current_game_mode.game_scores["Energieziel 2030"].add_contributor(game_collection, "Roof PV", 0.2)
		GameSystem.current_game_mode.game_scores["Energieziel 2050"].add_contributor(game_collection, "Roof PV", 0.5)
	else:
		GameSystem.current_game_mode.game_object_collections["Roof PV"].game_objects.erase(0)
		#GameSystem.current_game_mode.game_scores["Energieziel 2030"].recalculate_score()
		GameSystem.current_game_mode.game_scores["Energieziel 2050"].recalculate_score()
