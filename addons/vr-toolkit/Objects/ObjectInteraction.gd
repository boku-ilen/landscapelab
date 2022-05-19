extends "res://addons/vr-toolkit/Controller/ControllerTool.gd"

export(int) var velocity_samples = 20

onready var area = get_node("Area")

# The picked up object
var current_object = null
var picked_up: bool = false
# The initial transform of the object when picking up
var original_object_transform: Transform = Transform.IDENTITY
# The initial node the object was child of
var original_parent: Spatial = null
# The initial state of showing controller/hand mesh
var original_meshes: Dictionary
var last_position = Vector3(0.0, 0.0, 0.0)
var velocities = Array()


func _ready():
	$Inputs/PickUpInput.connect("pressed", self, "on_pickup", [true])
	$Inputs/PickUpInput.connect("released", self, "on_pickup", [false])
	$Inputs/InteractInput.connect("pressed", self, "on_interact", [true])
	$Inputs/InteractInput.connect("released", self, "on_interact", [false])


func _physics_process(delta):
	velocities.push_back((global_transform.origin - last_position) / delta)
	if velocities.size() > velocity_samples:
		velocities.pop_front()
	last_position = global_transform.origin


func on_interact(pressed):
	if not current_object == null:
		if pressed:
			current_object.interact()
		else:
			current_object.interact_end()
	#else:
	#	var compi: Spatial = load("res://VR/DistanceMeasurement/DistanceMeasurer.tscn").instance()
	#	get_parent().get_parent().get_parent().get_parent().add_child(compi)
	#	compi.global_transform.origin = global_transform.origin


func on_pickup(pressed: bool):
	# If the object we try to pick up is in the group of interactable, we will 
	# set our current_object to this object
	if pressed:
		current_object = _try_pick_up_closest_interactable()
		if not current_object == null:
			# If not static object
			if current_object.get_class() == "VRInteractable":
				if pick_up():
					picked_up = true
			elif current_object.get_class() == "VRStaticInteractable":
				current_object.pick(controller_id, self)
				picked_up = true
	else:
	# If we are no longer holding the object we will call for its dropped method 
	# and set the current_object to null
		if picked_up and current_object:
			if current_object.get_class() == "VRInteractable":
				drop()
				
				# Show the initial meshes again
				origin.set_show_meshes(controller_id, original_meshes.hand, original_meshes.controller)
			elif current_object.get_class() == "VRStaticInteractable":
				current_object.omitted()
			
			picked_up = false
			
			current_object = null


func pick_up():
	var original_object_basis = current_object.global_transform.basis
	
	if not current_object.is_picked_up:
		current_object.original_parent.remove_child(current_object)
		current_object.mode = RigidBody.MODE_KINEMATIC
		add_child(current_object)
		current_object.picked_up(controller_id, self)
	# If it is picked up but not an interactable with a fixed position we want to be able
	# to remove it from the other controller and take it into the other to be able to
	# rotate the object
	elif not current_object.fixed_position:

		current_object.object_interaction.remove_child(current_object)
		current_object.object_interaction.current_object = null
		current_object.mode = RigidBody.MODE_KINEMATIC
		add_child(current_object)
		current_object.picked_up(controller_id, self)
	else:
		return false
	
	# If hide meshes is checked, hide hand and controller mesh, save original state for showing them again
	original_meshes = origin.get_show_meshes(controller_id)
	origin.set_show_meshes(controller_id, current_object.show_controller_hand_meshes, current_object.show_controller_hand_meshes)
	
	current_object.global_transform.origin = global_transform.origin
	
	if not current_object.fixed_position:
		# As the object should not have a fixed position, reassign the transform from before 
		current_object.global_transform.basis = original_object_basis
	else:
		# If it has a fixed position reset the transform, so it does have the same position
		global_transform.basis = get_parent().global_transform.basis
		current_object.transform = transform * current_object.position_in_hand
	
	return true


func drop():
	var glob_transform = current_object.global_transform
	remove_child(current_object)
	current_object.original_parent.add_child(current_object)
	current_object.global_transform = glob_transform
	current_object.mode = RigidBody.MODE_RIGID
	
	current_object.dropped(_get_velocity())


func _try_pick_up_closest_interactable():
	var closest_distance = INF
	var closest_body
	
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Interactable"):
			var distance = global_transform.origin.distance_to(body.global_transform.origin)
			if distance < closest_distance:
				closest_distance = distance
				closest_body = body

	return closest_body


func _get_velocity():
	var velocity = Vector3(0.0, 0.0, 0.0)
	var count = velocities.size()
	
	if count > 0:
		for v in velocities:
			velocity = velocity + v
		
		velocity = velocity / count
	
	return velocity
