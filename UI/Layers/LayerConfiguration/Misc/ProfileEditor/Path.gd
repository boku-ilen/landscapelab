extends Path
class_name Profile


class ReoccurringObject:
	var h_offset: float
	var v_offset: float
	var distance_to_next: float
	var object_scene: PackedScene
	
	func _init(h_offset, v_offset, distance, scene):
		self.h_offset = h_offset
		self.v_offset = v_offset
		self.distance_to_next = distance
		self.object_scene = scene


func _ready():
	for child in get_children():
		if child is PathFollow:
			var first = child.duplicate()
			first.offset -= child.offset
			add_child(first)
			
			var dupl = child.duplicate()
			var u_offset_before = child.unit_offset
			while u_offset_before <= 1:
				dupl = dupl.duplicate()
				dupl.offset += child.offset
				add_child(dupl)
				u_offset_before += child.unit_offset


func add_reoccuring_object(object):
	if object is ReoccurringObject:
		var path_follow = PathFollow.new()
		var object_instance = object.object_scene.instance()
		
		path_follow.h_offset = object.h_offset
		path_follow.v_offset = object.v_offset
		path_follow.offset = object.distance_to_next
		
		add_child(path_follow)
		path_follow.add_child(object_instance)
	else:
		logger.error("Trying to attach an object other than a ReoccurringObject", "PROFILEEDITOR")
