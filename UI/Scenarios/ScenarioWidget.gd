extends VBoxContainer


var scenario: Scenario :
	get:
		return scenario
	set(new_scenario):
		scenario = new_scenario
		$HBoxContainer/Label.text = scenario.name

var selected := false


func _ready():
	connect("gui_input",Callable(self,"_on_clicked"))


func _on_clicked(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			scenario.activate()


func draw():
	if selected:
		var focussed = theme.get_stylebox("FocusedBox", "BoxContainer")
		draw_style_box(focussed, Rect2(Vector2(0,0), size))


func _draw():
	if has_focus():
		emit_signal("focus_entered")
	draw()

