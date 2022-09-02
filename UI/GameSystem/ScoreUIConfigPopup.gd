extends TextureButton


func _ready():
	connect("toggled", self, "try_popup")
	$PopupPanel.connect("popup_hide", self, "set_pressed", [false])


func try_popup(toggled: bool):
	if toggled:
		$PopupPanel.popup(Rect2(get_global_rect().position, rect_size))
	else:
		$PopupPanel.hide()
