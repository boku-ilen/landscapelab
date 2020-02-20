extends Spatial


func _ready():
	# Lego is enabled by default, we have to emit the signal on_ready
	# as nodes get built inside-out we need to do it on top of the scene-tree.
	GlobalSignal.emit_signal("sync_moving_assets")
