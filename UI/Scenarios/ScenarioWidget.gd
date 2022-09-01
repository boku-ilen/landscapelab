extends VBoxContainer


var scenario: Scenario setget set_scenario
var selected := false


func _ready():
	connect("gui_input", self, "_on_clicked")


func _on_clicked(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			scenario.activate()


func set_scenario(new_scenario):
	scenario = new_scenario
	$HBoxContainer/Label.text = scenario.name


func draw():
	if selected:
		var focussed = theme.get_stylebox("FocusedBox", "BoxContainer")
		draw_style_box(focussed, Rect2(Vector2(0,0), rect_size))


func _draw():
	if has_focus():
		emit_signal("focus_entered")
	draw()

