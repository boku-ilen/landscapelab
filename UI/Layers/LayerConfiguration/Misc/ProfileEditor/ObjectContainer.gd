extends VBoxContainer


var current_object setget set_current_object


func set_current_object(object):
	current_object = object


func _ready():
	$ScalingBox/Apply.connect("pressed", self, "_scale_object")


func _add_object(world):
	var f = File.new()
	if f.file_exists(get_node("ObjectChooser/FileName").text):
		var object = load(get_node("ObjectChooser/FileName").text).instance()
		world.add_child(object)
		current_object = object
		object.translation = Vector3.ZERO


func _scale_object():
	if current_object:
		current_object.set_scale(Vector3(get_node("ScalingBox/X").value, 
			get_node("ScalingBox/Y").value, get_node("ScalingBox/Z").value))


func _apply_reoccuring_object(path: Profile):
	if current_object:
		# store the translation and reset it to zero 
		# this will be h- and v-offset of the path-follow later on
		var translation = current_object.translation
		current_object.translation = Vector3.ZERO
		var object_as_scene = PackedScene.new()
		object_as_scene.pack(current_object)
		
		var reoccurring = path.ReoccurringObject.new(
			translation.x,
			translation.y,
			$DistanceBox/SpinBox.value,
			object_as_scene 
		)
		
		path.add_reoccuring_object(reoccurring)
		current_object.queue_free()
