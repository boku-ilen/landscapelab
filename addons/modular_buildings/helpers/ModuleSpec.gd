extends RefCounted
class_name ModuleSpecs


static var __cache: Dictionary[Mesh, ModuleSpec] = {}


static func get_module_spec(mesh: Mesh):
	if mesh in __cache:
		return __cache[mesh]
	
	var module_spec = ModuleSpec.new(mesh)
	__cache[mesh] = module_spec
	return module_spec


class ModuleSpec:
	var mesh: Mesh
	var asset_extent: Vector2
	
	func _init(new_mesh: Mesh):
		mesh = new_mesh
		var aabb = mesh.get_aabb()
		var overhang_z_side =  (aabb.size - aabb.end).x
		var overhang_x_side = (-aabb.size - aabb.position).z
		asset_extent = Vector2(
			aabb.size.z - overhang_z_side, 
			aabb.size.x + overhang_x_side)
