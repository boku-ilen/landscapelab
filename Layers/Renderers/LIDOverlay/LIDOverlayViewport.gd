extends Node3D

signal update_done

var has_updated_this_frame = false


# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: Check position of changed overlay and only update if overlaps
	LIDOverlay.updated.connect(update)
	set_notify_transform(true)


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update()


func _process(delta: float) -> void:
	has_updated_this_frame = false
	#if name == "HeightOverlayViewport" and get_parent().name == "DetailMesh":
		#$LIDViewport.get_texture().get_image().save_png("res://vp.png")


func update():
	if not has_updated_this_frame:
		$LIDViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		has_updated_this_frame = true
		await get_tree().process_frame
		update_done.emit()
