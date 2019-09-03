extends AnimationPlayer

#
# Handles fade-out and fade-in of the 3DSprite while the rendering process.
# The opacity of the mesh gets changed depending on the fps the engine currently gives.
# Below a certain threshold fade in the meshInstance, above fade it out.
#

export var below_threshold : int
export var above_threshold : int

var is_visible : bool = false


func _process(delta):
	if Engine.get_frames_per_second() > above_threshold and is_visible:
		_fade_out()
		is_visible = false
	elif Engine.get_frames_per_second() < below_threshold and not is_visible:
		_fade_in()
		is_visible = true


func _fade_in():
	play("FadeIn")


func _fade_out():
	play("FadeOut")