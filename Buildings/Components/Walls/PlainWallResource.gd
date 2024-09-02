extends Resource
class_name PlainWallResource


@export var basement_texture: TextureBundleRME
@export var ground_texture: TextureBundleRME
@export var middle_texture: TextureBundleRME
@export var top_texture: TextureBundleRME

@export var ground_window_id := -1
@export var middle_window_id := -1
@export var top_window_id := -1

@export var random_colors: Array[Color]
@export var random_color_weights: Array[float]
@export_flags("basement", "ground", "middle", "top") var apply_colors
# Wether to draw the vertices in clock- or counterclock-wise fashion
@export_flags("basement", "ground", "middle", "top") var wind_counterclockwise

@export var prefer_pointed_roof := true


func _init():
	call_deferred("ready")


func ready():
	# These two things have to be true in order for the random color picking to work
	assert(random_colors.size() == random_color_weights.size())
	assert(is_equal_approx(
		random_color_weights.reduce(func(x, y): return x + y, 0.), 1.0))
