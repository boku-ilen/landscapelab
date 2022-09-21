extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	$Record.connect("pressed",Callable(self,"_on_record"))
	$Stop.connect("pressed",Callable(self,"_on_stop"))
	$Pause.connect("pressed",Callable(self,"_on_pause"))
	$Play.connect("pressed",Callable(self,"_on_play"))


func _on_record():
	$Record.visible = false
	$Stop.visible = true
	$Pause.visible = true


func _on_stop():
	$Record.visible = true
	$Stop.visible = false
	$Pause.visible = false
	$Play.visible = false


func _on_pause():
	$Pause.visible = false
	$Play.visible = true


func _on_play():
	$Pause.visible = true
	$Play.visible = false
