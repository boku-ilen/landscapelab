@tool
extends BaseButton
class_name AutoIconButton


#
# Instead of using a separate texture for each state (default, pressed, ...),
# only colors have to be defined for this AutoTextureButton. The texture is
# then automatically colored accordingly.
# Also provides additional functionality for styling buttons such as rotating.
#

@export var icon_folder = "ModernLandscapeLab"

@export var texture_name: String :
	get:
		return texture_name
	set(new_name):
		texture_name = new_name
		_update_texture()


func _input(event):
	if not is_visible_in_tree(): return
	
	if event is InputEventMouseButton and event.pressed:
		if get_global_rect().has_point(event.position):
				pressed.emit()
				get_viewport().set_input_as_handled()



func _enter_tree() -> void:
	_update_texture()


# Update the button's base texture
func _update_texture():
	if not texture_name.is_empty():
		var full_path
		full_path = "res://Resources/Icons".path_join(icon_folder).path_join(texture_name) + ".svg"
		
		assert(FileAccess.file_exists(full_path)) #,"%s: No icon with name '%s' found in icon folder '%s'!" % [name, texture_name, icon_folder])
		
		if "texture_normal" in self:
			self.texture_normal = load(full_path)
		elif "icon" in self:
			self.expand_icon = true
			self.icon = load(full_path)
