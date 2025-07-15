extends Node3D
class_name HeightOverlay

# Utility Node to add to scenes which write into HeightOverlay.
# Automatically emits global signals for responding to updates.


# Static signal workaround from https://stackoverflow.com/questions/77026156/how-to-write-a-static-event-emitter-in-gdscript/77026952#77026952
static var added: Signal = (func():
	(HeightOverlay as Object).add_user_signal("added")
	return Signal(HeightOverlay, "added")).call()

static var removed: Signal = (func():
	(HeightOverlay as Object).add_user_signal("removed")
	return Signal(HeightOverlay, "removed")).call()

static var updated: Signal = (func():
	(HeightOverlay as Object).add_user_signal("updated")
	return Signal(HeightOverlay, "updated")).call()


# Called when the node enters the scene tree for the first time.
func _ready():
	set_notify_transform(true)
	visibility_changed.connect(func(): updated.emit())


func _enter_tree():
	added.emit()
	updated.emit()


func _exit_tree():
	removed.emit()
	updated.emit()


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		updated.emit()
