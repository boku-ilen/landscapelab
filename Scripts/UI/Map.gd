extends TextureRect

var tex

var focus
var zoom_lv
export var zoom_step = [1, 1.5, 2, 3, 4, 6, 8, 12, 16, 24, 32]

var map_drag = false
var map_dragged = false

func _ready():
	tex = preload("res://Assets/basemap18_UTM.png")
	
	focus = tex.get_size() / 2
	zoom_lv = 0

func _process(delta):
	pass

func _input(event):
	event = make_input_local(event)
	if event is InputEventMouseMotion:
		#logger.info(event.relative)
		if map_drag:
			map_dragged = true
			focus -= event.relative * tex.get_size() / (rect_size * zoom_step[zoom_lv])
		else:
			pass
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			map_drag = event.pressed
			if not event.pressed and not map_dragged:
				var map_point = get_map_point()
				if not map_point == null:
					logger.info("Selected point %s on Map" % str(map_point))
			
			map_dragged = false
			pass
		elif event.button_index == BUTTON_WHEEL_UP:
			zoom_lv = min(zoom_step.size() - 1, zoom_lv + 1)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom_lv = max(0, zoom_lv - 1)
	
	
	# enforcing edge boundaries
	var p1 = get_texture_area_start()
	var p2 = p1 + get_texture_area()
	
	if p1.x < 0:
		focus = focus - Vector2(p1.x, 0)
	elif p2.x > tex.get_width():
		focus = focus - Vector2(p2.x - tex.get_width(), 0)
	
	if p1.y < 0:
		focus = focus - Vector2(0, p1.y)
	elif p2.y > tex.get_height():
		focus = focus - Vector2(0, p2.y - tex.get_height())
	
	# updating map
	update()

func _draw():
	draw_texture_rect_region(tex, Rect2(0,0,rect_size.x,rect_size.y), Rect2(get_texture_area_start(), get_texture_area()))

func get_map_point():
	var mouse = get_local_mouse_position()
	if rect_size.x > 0 && rect_size.y > 0:
		if mouse.x >= 0 && mouse.y >= 0 && mouse.x <= rect_size.x && mouse.y <= rect_size.y:
			var map_aim = Vector2(mouse.x / rect_size.x, mouse.y / rect_size.y)
			
			var p1 = get_texture_area_start()
			var p2 = p1 + get_texture_area()
			
			var map_point = Vector2(lerp(p1.x, p2.x, map_aim.x), lerp(p1.y, p2.y, map_aim.y))
			map_point = Vector2(map_point.x / tex.get_width(), map_point.y / tex.get_height())
			
			return map_point
	return null

func get_texture_area_start():
	return focus - get_texture_area() / 2

func get_texture_area():
	return tex.get_size() / zoom_step[zoom_lv]
