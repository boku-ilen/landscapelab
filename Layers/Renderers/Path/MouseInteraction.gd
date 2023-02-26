extends Node3D

const MAX_RAYCAST_DISTANCE = 5000.0


func _ready():
	get_parent().remove_child(self)
	get_viewport().add_child(self)



func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		var space_state = get_world_3d().direct_space_state
	
		var viewport = get_viewport()
		var camera: Camera3D = viewport.get_camera_3d()
		var mouse_position = viewport.get_mouse_position()
		
		var ray_start = camera.project_position(mouse_position, 0)
		var ray_end = camera.project_position(mouse_position, MAX_RAYCAST_DISTANCE)
		
		var ray = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		var result = space_state.intersect_ray(ray)
		
		if result.is_empty():
			return
		
		$CSGSphere3D.position = result["position"]
		
		var collision_node: Node = result["collider"]
		var collsition_node_parent: Node = collision_node.get_parent()
		
		if not collsition_node_parent is RoadLane:
			return
		
		var road_lane: RoadLane = collsition_node_parent
		$RoadInfo.set_data(road_lane.road_instance)
		if not $RoadInfo.visible:
			$RoadInfo.position = mouse_position + Vector2(100, 100)
		$RoadInfo.show()
