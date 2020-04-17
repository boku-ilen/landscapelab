extends Node


func _update_meshes(current_mode):
	var show = GameModeLoader.get_vr_show_meshes(current_mode, "left")
	get_parent().set_show_meshes(1, show.controller, show.hand)
	get_parent().gui_finger_left = show.gui_finger
	
	show = GameModeLoader.get_vr_show_meshes(current_mode, "right")
	get_parent().set_show_meshes(2, show.controller, show.hand)
	get_parent().gui_finger_right = show.gui_finger


func _update_tools(current_mode):
	var parent = get_pos_for_side("Tip", "Left")
	for _tool in GameModeLoader.get_vr_tools(current_mode, "left"):
		parent.add_child(load(_tool).instance())
	
	parent = get_pos_for_side("Tip", "Right")
	for _tool in GameModeLoader.get_vr_tools(current_mode, "right"):
		parent.add_child(load(_tool).instance())


func get_pos_for_side(pos: String, side: String):
	return get_parent().get_node(side.plus_file(pos))


func _ready():
	update()


func update():
	var current_mode = get_tree().get_current_scene().name
	_update_meshes(current_mode)
	_update_tools(current_mode)
	get_parent().get_node("Left").update()
	get_parent().get_node("Right").update()
