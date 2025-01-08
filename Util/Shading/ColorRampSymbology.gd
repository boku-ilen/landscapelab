@tool
extends Control

@export var ticks_at: Array[float] : 
	set(new_ticks_at):
		ticks_at = new_ticks_at

@export var ticks_val: Array[float] : 
	set(new_ticks_val):
		ticks_val = new_ticks_val

@export var apply: bool :
	set(apply):
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
