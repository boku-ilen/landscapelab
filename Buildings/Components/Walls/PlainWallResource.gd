extends Resource
class_name PlainWallResource


@export var basement_texture: WallTextureBundle
@export var ground_texture: WallTextureBundle
@export var middle_texture: WallTextureBundle
@export var top_texture: WallTextureBundle

@export var random_colors: Array[Color]
@export_flags("basement", "ground", "middle", "top") var apply_colors
# Wether to draw the vertices in clock- or counterclock-wise fashion
@export_flags("basement", "ground", "middle", "top") var wind_counterclockwise
