@tool
extends Node3D


var radius = 10000.0
@export var check_aabb_collision: bool = false
@export var max_features = 50
@export var distance_between_objects := Vector2(10, 10)
@export var apply: bool = false : 
	set(_a):
		$Objects.get_children().map(func(c): c.queue_free())
		full_load()
		
# Stores if the object-layer has been processed previously
var processed = false

var object_instances = []

enum DIRECTION {
	UP,
	RIGHT,
	DOWN,
	LEFT
}


func spiral(start_position: Vector2, min_pos: Vector2, max_pos: Vector2, max_features: float, callback: Callable):
	var x := start_position.x
	var y := start_position.y
	var dx := distance_between_objects.x
	var dy := distance_between_objects.y
	
	var stop_flags = 0b0000
	
	var direction = DIRECTION.UP
	var i = 0
	var step_size = 0
	DIRECTION.size()
	var instance_count = 0
	while instance_count < max_features:
		var multiplier = i + (1 * int(direction % 2 == 0))
		for step in range(step_size):
			stop_flags |= int(x < min_pos.x) * 0b1
			stop_flags |= int(y < min_pos.y) * 0b10
			stop_flags |= int(x > max_pos.x) * 0b100
			stop_flags |= int(y > max_pos.y) * 0b1000
			
			if stop_flags == 0b1111:
				return

			if callback.call(x, y, instance_count):
				instance_count += 1
			
			if instance_count > max_features:
				break
			
			match direction:
				DIRECTION.UP:
					y += dy
				DIRECTION.DOWN:
					y -= dy
				DIRECTION.RIGHT:
					x += dx
				DIRECTION.LEFT:
					x -= dx
		
		i += 1
		if direction % 2 == 0:
			step_size += 1
		direction = i % DIRECTION.size()


func full_load():
	var engine_polygon = $Path3D.curve.get_baked_points()
	engine_polygon = Array(engine_polygon).map(func(v): return Vector2(v.x, v.z))
	# Find left-most and bottom-most and right-most, top-most point in polygon
	var min_pos = Vector3(INF, 0, INF)
	var max_pos = Vector3(-INF, 0, -INF)
	for vertex in engine_polygon:
		min_pos.x = min(min_pos.x, vertex.x)
		min_pos.z = min(min_pos.z, vertex.y)
		max_pos.x = max(max_pos.x, vertex.x)
		max_pos.z = max(max_pos.z, vertex.y)
	
	var object_scene = load("res://test3.tscn")
	var object: Node3D = object_scene.instantiate()
	# Obtain aabb over all visual instances
	var aabb
	var bounds
	if check_aabb_collision:
		aabb = util.get_summed_aabb(object)
		bounds = [
			Vector2(aabb.position.x, aabb.position.z), 
			Vector2(aabb.position.x, aabb.end.z),
			Vector2(aabb.end.x, aabb.end.z),
			Vector2(aabb.end.x, aabb.position.z)
		]
	
	var set_object = func(x: float, y: float, instance_count: int):
		# Add relative position to absolute object position
		var current_pos_2d := Vector2(x, y)
		
		var fully_inside: bool
		if check_aabb_collision:
			fully_inside = bounds.reduce(func(still_inside, b): 
				return Geometry2D.is_point_in_polygon(b + current_pos_2d, engine_polygon) and still_inside, true)
		else:
			fully_inside = Geometry2D.is_point_in_polygon(current_pos_2d, engine_polygon)
		
		if fully_inside:
			var object_y_pos = 0.
			var object_pos = Vector3(x, object_y_pos, y)
			
			var new_object = object_scene.instantiate()
			#new_object.rotation.y = deg_to_rad(layer_composition.render_info.individual_rotation)
			new_object.position = object_pos
			$Objects.add_child(new_object)
		
		return fully_inside
	
	var engine_pos = $Marker3D.position
	
	spiral(
		Vector2(engine_pos.x, engine_pos.z), 
		Vector2(min_pos.x, min_pos.z), 
		Vector2(max_pos.x, max_pos.z), 
		max_features, 
		set_object
	)
