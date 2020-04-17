extends Spatial


export(int, "any", "left", "right") var controller_side setget set_controller_side

onready var anim = get_node("HandDefault/AnimationPlayer")
onready var hand = get_node("HandDefault")

enum FINGER_POSITION{
	pressed,
	touched,
	released
}

enum FINGERS{
	thumb,
	index,
	middleRingPinky
}


func _ready():
	$Inputs/PointingTouchInput.connect("pressed", self, "apply_gesture", [FINGERS.index, FINGER_POSITION.touched])
	$Inputs/PointingTouchInput.connect("released", self, "apply_gesture", [FINGERS.index, FINGER_POSITION.released])
	$Inputs/PointingPressInput.connect("pressed", self, "apply_gesture", [FINGERS.index, FINGER_POSITION.pressed])
	$Inputs/PointingPressInput.connect("released", self, "apply_gesture", [FINGERS.index, FINGER_POSITION.touched])
	$Inputs/GrabbingTouchInput.connect("pressed", self, "apply_gesture", [FINGERS.middleRingPinky, FINGER_POSITION.touched])
	$Inputs/GrabbingTouchInput.connect("released", self, "apply_gesture", [FINGERS.middleRingPinky, FINGER_POSITION.released])
	$Inputs/GrabbingPressInput.connect("pressed", self, "apply_gesture", [FINGERS.middleRingPinky, FINGER_POSITION.pressed])
	$Inputs/GrabbingPressInput.connect("released", self, "apply_gesture", [FINGERS.middleRingPinky, FINGER_POSITION.touched])
	$Inputs/ThumbTouchInput.connect("pressed", self, "apply_gesture", [FINGERS.thumb, FINGER_POSITION.touched])
	$Inputs/ThumbTouchInput.connect("released", self, "apply_gesture", [FINGERS.thumb, FINGER_POSITION.released])
	$Inputs/ThumbPressInput.connect("pressed", self, "apply_gesture", [FINGERS.thumb, FINGER_POSITION.pressed])
	$Inputs/ThumbPressInput.connect("released", self, "apply_gesture", [FINGERS.thumb, FINGER_POSITION.touched])


func apply_gesture(finger_id: int, finger_position: int):
	if finger_position == FINGER_POSITION.pressed:
		anim.set_current_animation(String(finger_id))
		anim.seek(0.8333, true)
		anim.stop(false)
	elif finger_position == FINGER_POSITION.touched:
		anim.set_current_animation(String(finger_id))
		anim.seek(0.5, true)
		anim.stop(false)
	else:
		anim.set_current_animation(String(finger_id))
		anim.seek(0.0, true)
		anim.stop(false)


# If left, mirror scene
func set_controller_side(id):
	yield(self, "ready")
	if id == 1:
		hand.scale.y = -1
		translation.x *= -1
