extends Spatial


# Icon displayed in the minimap
# it's parent object should not be able to rotate around the x- or z-axis


export(Texture) var icon
export(Color) var color_modulate
export(bool) var rotate = false
export(float) var size = 0.25
onready var icon_sprite = get_node("IconSprite")


func _ready():
	if not rotate: 
		# 1 equals BILLBOARD_ENABLED
		icon_sprite.material_override.params_billboard_mode = 1
	else:
		# 0 equals DISABLED
		# TODO: in godot 3.2 billboard rotation will be added so the icon will only rotate around z-axis
		icon_sprite.material_override.params_billboard_mode = 0
		
	update_icon(icon)


# updates the icon with a new texture
func update_icon(var texture):
	# to properly scale the icons a little tricking is needed, a new export variable size will do the trick
	var texture_width = texture.get_width()
	icon_sprite.pixel_size = size / texture_width
	
	icon_sprite.texture = texture
	
	icon_sprite.modulate = color_modulate
