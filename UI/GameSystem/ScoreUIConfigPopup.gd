extends TextureButton


func _ready():
	connect("toggled",Callable(self,"try_popup"))
	$PopupPanel.connect("popup_hide",Callable(self,"set_pressed").bind(false))


func try_popup(toggled: bool):
	if toggled:
		$PopupPanel.popup(Rect2(get_global_rect().position, size))
	else:
		$PopupPanel.hide()
