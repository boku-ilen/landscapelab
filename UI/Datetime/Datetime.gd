extends VBoxContainer


var time_manager: TimeManager


func _ready():
	$ConfirmButton.connect("pressed",Callable(self,"_on_confirm_pressed"))


func _on_confirm_pressed():
	time_manager.set_datetime(
		$SlideAndSpinTime.value,
		$SlideAndSpinDay.value,
		$SlideAndSpinYear.value
	)
