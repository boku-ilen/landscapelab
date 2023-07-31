extends FileDialog


func save(file_path: String, path: Path3D):
	# Duplicate the path for storing purposes
	var store_path = path.duplicate(15)
	# Explicitly mark ownership checked the parent node, else the children don't get
	# stored in a packed scene
	var i = 0
	for child in store_path.get_children():
		# The attached profile has editor functionality (drag polygon, etc.)
		# - thus a primitive duplicate is created
		if child.has_method("duplicate_as_primitive_material"):
			var duplicate: CSGPolygon3D = child.duplicate_as_primitive_material()
			store_path.add_child(duplicate)
			duplicate.set_owner(store_path)
			
			# Additionally store the material of each profile
			var resource_path = "%s%d%s" % [file_path.substr(0, file_path.rfind(".")), i, ".tres"]
			ResourceSaver.save(child.material, resource_path)
			var mat = StandardMaterial3D.new()
			mat.resource_path = resource_path
			duplicate.material = mat
			i += 1
		else:
			set_recursive_owner(child, store_path)
	
	# Store in a packed scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(store_path)
	ResourceSaver.save(packed_scene, file_path)
	# Remove the duplicated path, as it should be persisted
	store_path.queue_free()


func set_recursive_owner(child: Node, ownr: Node):
	child.set_owner(ownr)
	for sub_child in child.get_children():
		set_recursive_owner(sub_child, ownr)
