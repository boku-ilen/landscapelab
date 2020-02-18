extends PanelContainer


export(int) var start_pos_diff
export(int) var hovered_pos_diff

onready var panel_toggled_pos = rect_position
onready var panel_hovered_pos = Vector2(rect_position.x - hovered_pos_diff, rect_position.y)
onready var panel_start_pos = Vector2(rect_position.x - start_pos_diff, rect_position.y)
onready var arrow = get_node("../Button")

var arrow_toggle: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("mouse_entered", self, "_on_mouse_entered")
	arrow.connect("toggled", self, "_on_arrow_toggle")
	UISignal.connect("ui_loaded", self, "_on_ui_loaded")
	set_position(panel_start_pos)


func _on_mouse_entered():
	if !arrow_toggle:
		arrow.set_rotation_degrees(180)
		set_position(panel_hovered_pos)


func _on_mouse_exited():
	if !arrow_toggle:
		arrow.set_rotation_degrees(-90)
		set_position(panel_start_pos)


func _on_arrow_toggle(toggled):
	arrow_toggle = toggled
	if toggled:
		set_position(panel_toggled_pos)
		arrow.set_rotation_degrees(90)
	else:
		set_position(panel_start_pos)
		arrow.set_rotation_degrees(-90)


func _on_ui_loaded():
	set_position(panel_start_pos)


# Tool specific tool for showing errors in the editor
func _get_configuration_warning():
	#for child in get_children():
		#var is_required_type = child is _required_button
		
		#if child.name != "Hoverable" and not is_required_type:
		#	return "One or more child(ren) do not extend the required ToolsButton"
	
	return ""
