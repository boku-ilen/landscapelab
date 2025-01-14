@tool
extends Control
class_name ColorRampSymbology

@export var ticks_at: Array[float] : 
	set(new_ticks_at):
		var enlarged = new_ticks_at.size() > ticks_at.size()
		ticks_at = new_ticks_at
		ensure_same_size(ticks_at, ticks_val, enlarged)
		get_node("ColorRamp/Ticks").queue_redraw()

@export var ticks_val: Array[float] : 
	set(new_ticks_val):
		var enlarged = new_ticks_val.size() > ticks_val.size()
		ticks_val = new_ticks_val
		ensure_same_size(ticks_val, ticks_at, enlarged)
		get_node("ColorRamp/Ticks").queue_redraw()

@export var gradient: Gradient : 
	set(new_gradient):
		gradient = new_gradient
		get_node("ColorRamp/Gradient").texture.gradient = gradient
		get_node("ColorRamp/Ticks").queue_redraw()


func draw_tick(child: Control, rel_val: float, abs_val: float, color:=Color.ALICE_BLUE, line_width:=0.5):
	var gradient = get_node("ColorRamp/Gradient")
	var start = Vector2(5., gradient.position.y + gradient.size.y * rel_val)
	var end = Vector2(gradient.position.x - gradient.size.x, 
		gradient.position.y + gradient.size.y * rel_val)
	child.draw_line(start, end, color, line_width, true)
	var default_font = ThemeDB.fallback_font
	var default_font_size = ThemeDB.fallback_font_size
	child.draw_string(default_font, start + Vector2(0., 5.), var_to_str(abs_val), HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size)


func _ready():
	get_node("ColorRamp/Ticks").draw.connect(draw_on_child)


func draw_on_child():
	for i in ticks_at.size():
		draw_tick(get_node("ColorRamp/Ticks"), ticks_at[i], ticks_val[i])


func ensure_same_size(changed: Array, to_change: Array, is_enlarged: bool):
	print(is_enlarged)
	if is_enlarged:
		while changed.size() > to_change.size():
			to_change.append(0.)
	else:
		while changed.size() < to_change.size():
			to_change.pop_back()


func ticks_from_absolute_values(values: Array, min: float, max: float):
	var _ticks_at: Array[float] = []
	var _ticks_val: Array[float] = []
	for value in values:
		_ticks_at.append(inverse_lerp(min, max, value))
		_ticks_val.append(value)
	
	ticks_at = _ticks_at
	ticks_val = _ticks_val


func ticks_from_relative_values(values: Array, min: float, max: float):
	var _ticks_at: Array[float] = []
	var _ticks_val: Array[float] = []
	for value in values:
		_ticks_at.append(value)
		_ticks_val.append(lerp(min, max, value))
	
	ticks_at = _ticks_at
	ticks_val = _ticks_val
