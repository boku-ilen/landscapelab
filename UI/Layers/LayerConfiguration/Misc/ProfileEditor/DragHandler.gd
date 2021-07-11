extends Node

#
# Node that handles the (rather complex) dragging logic in the profile-editor,
# and selected draggable logic. Also includes snapping logic.
#
# This node must not be used without it's parent (the profile editor).
#

const SNAPPING_OFFSET = 0.1

# Store all possible dragables in the editor
var dragables = {}

class Dragable:
	#
	# As there are many different dragable objects (objects such as windmills,
	# profiles, profile points and probably more to come, this class intends
	# to abstract the different position logic of the individual nodes/GDObjects
	#
	var is_active: bool
	var position: Vector3
	var object_reference
	
	func _init(object):
		object_reference = object
	
	
	func set_active(active: bool, profile_editor: Control):
		is_active = active
	
	
	func set_position(new_pos):
		position = Vector3(new_pos.x, new_pos.y, 0)


class DragablePoint extends Dragable:
	#
	# Dragable point of a profile (PolygonPoint)
	#
	var profile_reference
	
	func _init(object, profile).(object):
		profile_reference = profile
	
	
	func set_position(new_pos: Vector2):
		.set_position(new_pos)
		object_reference.set_position(new_pos)
		profile_reference.drag()
	
	
	func set_active(active: bool, profile_editor: Control):
		.set_active(active, profile_editor)
		if active:
			profile_editor.emit_signal("current_point_changed", object_reference)
			profile_editor.emit_signal("current_profile_changed", profile_reference)
			object_reference.color = Color.green
			profile_reference.color = Color.green
		else:
			if object_reference:
				object_reference.color = Color.red
			if profile_reference:
				profile_reference.color = Color.red


class DragableObject extends Dragable:
	#
	# Dragable spatial (anything)
	#
	func _init(object).(object): pass
	
	
	func set_position(new_pos: Vector2):
		.set_position(new_pos)
		object_reference.set_translation(Vector3(new_pos.x, new_pos.y, 0))
	
	
	func set_active(active: bool, profile_editor: Control):
		.set_active(active, profile_editor)
		if is_active: profile_editor.emit_signal("current_object_changed", object_reference)


var current_dragable: Dragable setget set_current_dragable


func set_current_dragable(dragable):
	if dragable: if dragable.name in dragables.keys():
			dragable = dragables[dragable.name]
	else: 
		return
	
	if current_dragable:
		current_dragable.set_active(false, get_parent())
	current_dragable = dragable
	
	if current_dragable:
		current_dragable.set_active(true, get_parent())


func add_dragable(dragable):
	var new_dragable: Dragable
	if dragable is PolygonPoint:
		new_dragable = DragablePoint.new(dragable, dragable.get_parent())
	elif dragable is Spatial:
		new_dragable = DragableObject.new(dragable)
	
	dragables[dragable.name] = new_dragable


func drag(projected_mouse):
	if current_dragable:
		current_dragable.set_position(projected_mouse)


func snap_objects(mouse2d: Vector2, profiles: Array):
	# maximum possible int, apparently there is no constant for this
	var min_dist: int = 9223372036854775807
	var current_snap: Vector2 = mouse2d
	
	for profile in profiles:
		for point in profile.profile_polygon:
			var current_dist = mouse2d.distance_to(point.position)
			
			# The point itself
			if current_dragable.object_reference == point: continue
			
			if current_dist < SNAPPING_OFFSET and current_dist < min_dist: 
				min_dist = current_dist
				current_snap = point.position
			
	return current_snap


func snap_grid(mouse2d: Vector2):
	var rounded_mouse = Vector2(stepify(mouse2d.x, 1), stepify(mouse2d.y, 1))
	if rounded_mouse.distance_to(mouse2d) < SNAPPING_OFFSET:
		return rounded_mouse
	elif Vector2(rounded_mouse.x, mouse2d.y).distance_to(mouse2d) < SNAPPING_OFFSET:
		return Vector2(rounded_mouse.x, mouse2d.y)
	elif Vector2(mouse2d.x, rounded_mouse.y).distance_to(mouse2d) < SNAPPING_OFFSET:
		return Vector2(mouse2d.x, rounded_mouse.y)
	return mouse2d
