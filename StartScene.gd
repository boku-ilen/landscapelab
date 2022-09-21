extends TextureButton

var _timer = null

# TODO: this button is currently replacing a proper vanishing
# TODO: of the welcome screen after a proper loading 
func _ready():
	_timer = Timer.new()
	add_child(_timer)

	_timer.connect("timeout",Callable(self,"_on_Timer_timeout"))
	_timer.set_wait_time(2.5)
	_timer.set_one_shot(true) # Make sure it loops
	_timer.start()


func _on_Timer_timeout():
	self.get_parent().visible = false
