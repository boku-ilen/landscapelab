extends RefCounted
class_name Edge

var p0: Vector2
var p1: Vector2
var dir: Vector2
var length: float
var normal: Vector2

func _init(a: Vector2, b: Vector2):
	p0 = a
	p1 = b
	var v := b - a
	length = v.length()
	dir = (v / max(length, 1e-6))
	normal = Vector2(dir.y, -dir.x) # left-hand normal (outward)
