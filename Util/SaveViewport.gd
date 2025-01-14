extends SubViewport

var saved = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not saved:
		get_texture().get_image().save_png("res://distance_plant_uv.png")
		#saved = true
