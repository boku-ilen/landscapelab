extends Spatial


# Icon displayed in the minimap
# it's parent object should not be able to rotate around the x- or z-axis


export(Texture) var icon
export(Color) var color_modulate
export(bool) var rotate = false
export(float) var size = 0.25
onready var icon_sprite = get_node("IconSprite")


func _ready():
	update_icon(icon)


# Because Godot's Vector2.angle_to(Vector2) always returns the __minimum__ angle, we
#  implement our own function to get the __clockwise__ angle (meaning an angle to the
#  left yields a different result than the same angle to the right)
func _get_clockwise_angle(vector1: Vector2, vector2: Vector2):
	var dot = vector1.dot(vector2)
	var det = vector1.x * vector2.y - vector1.y * vector2.x
	
	return atan2(det, dot)


func _process(delta):
	# If the rotate flag is set, supply the shader with the latest rotation.
	if rotate:
		# The rotation is the angle between the local forward vector and the global forward vector.
		# The y axis can be ignored since we only care about rotation viewed from the top (yaw).
		var local_forward = global_transform.basis.z
		var angle = _get_clockwise_angle(Vector2(local_forward.x, local_forward.z), Vector2(0, 1))
		
		icon_sprite.material_override.set_shader_param("rotation_rads", angle)


# updates the icon with a new texture
func update_icon(var texture):
	# to properly scale the icons a little tricking is needed, a new export variable size will do the trick
	var texture_width = texture.get_width()
	icon_sprite.pixel_size = size / texture_width
	
	icon_sprite.texture = texture
	
	icon_sprite.modulate = color_modulate
