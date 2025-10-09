extends RoofBase


#
# A simple flat roof, created by triangulating the footprint.
#

const type := TYPES.FLAT

@export var height = 0.05
var color

var has_domes = false


func _ready():
	$MeshInstance3D.material_override = preload("res://Buildings/Components/Roofs/FlatRoofPantelleria.tres")


func build(footprint: PackedVector2Array):
	# Convert the footprint to a polygon
	var polygon_indices = Geometry2D.triangulate_polygon(footprint)
	
	if polygon_indices.is_empty():
		# The triangualtion was unsuccessful
		return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	
	# Create dome-ish look by adding the heigher vertices offset inwards
	var downscaled_footprint = footprint * Transform2D(0, Vector2.ONE * 0.99, 0, Vector2.ZERO) 
	
	# Create flat roof
	var polygon_indices_rev = Geometry2D.triangulate_polygon(downscaled_footprint)
	polygon_indices_rev.reverse()
	for index in polygon_indices_rev:
		var current_vertex_2d = downscaled_footprint[index]
		st.set_color(Color.BEIGE)
		st.set_uv(current_vertex_2d * 0.1)
		st.add_vertex(Vector3(current_vertex_2d.x, height, current_vertex_2d.y))
	
	# Create a little bit of height for the roof
	for index in polygon_indices:
		var lower_current_vertex_2d = footprint[index]
		var higher_current_vertex_2d = downscaled_footprint[index]
		var lower_next_vertex_2d = footprint[(index + 1) % footprint.size()]
		var higher_next_vertex_2d = downscaled_footprint[(index + 1) % footprint.size()]
		st.set_color(Color.BEIGE)
		
		var distance_to_next = lower_current_vertex_2d.distance_to(lower_next_vertex_2d)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(Vector3(lower_current_vertex_2d.x, 0, lower_current_vertex_2d.y))
		st.set_uv(Vector2(0, height))
		st.add_vertex(Vector3(higher_current_vertex_2d.x, height, higher_current_vertex_2d.y))
		st.set_uv(Vector2(distance_to_next, 0))
		st.add_vertex(Vector3(lower_next_vertex_2d.x, 0, lower_next_vertex_2d.y))
		
		st.set_uv(Vector2(distance_to_next, height))
		st.add_vertex(Vector3(higher_next_vertex_2d.x, height, higher_next_vertex_2d.y))
		st.set_uv(Vector2(distance_to_next, 0))
		st.add_vertex(Vector3(lower_next_vertex_2d.x, 0, lower_next_vertex_2d.y))
		st.set_uv(Vector2(0, height))
		st.add_vertex(Vector3(higher_current_vertex_2d.x, height, higher_current_vertex_2d.y))
	
	st.generate_normals()
	st.generate_tangents()
	
	# Apply
	var mesh = st.commit()
	mesh.custom_aabb = st.get_aabb()
	get_node("MeshInstance3D").mesh = mesh


func can_refine():
	return not has_domes


func refine():
	add_domes()


func add_domes():
	var addons = {}
	for addon_key in addon_layers.keys():
			addons[addon_key] = addon_layers[addon_key].get_features_by_attribute_filter(
				"build_id = %s" % [fid])
	
	for addon_key in addons.keys():
		var addon_features = addons[addon_key]
		for addon_feature in addon_features:
			var offset_x = building_metadata.geo_offset[0]
			var offset_z = building_metadata.geo_offset[1]
			
			var pos: Vector3 = addon_feature.get_offset_vector3(offset_x, 0, offset_z)
			pos.x -= building_metadata.engine_center.x
			pos.z -= building_metadata.engine_center .z
			pos.z += height
			
			var rot = float(addon_feature.get_attribute("LL_rot"))
			var sca = float(addon_feature.get_attribute("LL_scale"))
			
			# Instance addon_object and apply transforms
			var instance: Node3D = addon_objects[addon_key].instantiate() 
			add_child.call_deferred(instance)
			instance.translate(pos)
			instance.rotation.y = deg_to_rad(rot)
			if sca != 0.: instance.scale = Vector3.ONE * sca
	
	has_domes = true
