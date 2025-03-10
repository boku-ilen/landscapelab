@tool
extends MeshInstance3D
class_name LIDOverlay


# Static signal workaround from https://stackoverflow.com/questions/77026156/how-to-write-a-static-event-emitter-in-gdscript/77026952#77026952
static var added: Signal = (func():
	(LIDOverlay as Object).add_user_signal("added")
	return Signal(LIDOverlay, "added")).call()

static var removed: Signal = (func():
	(LIDOverlay as Object).add_user_signal("removed")
	return Signal(LIDOverlay, "removed")).call()

static var updated: Signal = (func():
	(LIDOverlay as Object).add_user_signal("updated")
	return Signal(LIDOverlay, "updated")).call()


@export var lid := 0 :
	set(new_lid):
		lid = new_lid
		update_mesh_color()

@export var size := Vector2(5.0, 5.0) :
	set(new_size):
		size = new_size
		update_size()


# Called when the node enters the scene tree for the first time.
func _ready():
	update_size()
	update_mesh_color()
	set_notify_transform(true)
	visibility_changed.connect(func(): updated.emit())


func _enter_tree():
	added.emit(lid)
	updated.emit()


func _exit_tree():
	removed.emit(lid)
	updated.emit()


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		updated.emit()


func update_mesh_color():
	material_override.set_shader_parameter("color", Color8(
		lid % 255,
		floor(lid / 255),
		0
	))


func update_size():
	mesh.size = size
