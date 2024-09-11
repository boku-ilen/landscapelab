extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: Check position of changed overlay and only update if overlaps
	LIDOverlay.updated.connect(update)
	set_notify_transform(true)


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update()


func update():
	$LIDViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
