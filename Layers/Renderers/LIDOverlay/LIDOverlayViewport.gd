extends Node3D

signal update_done


# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: Check position of changed overlay and only update if overlaps
	LIDOverlay.updated.connect(update)
	set_notify_transform(true)


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update()


func _process(delta: float) -> void:
	update()


func update():
	$LIDViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	update_done.emit()
