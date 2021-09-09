extends VBoxContainer


func _ready():
	$ConfirmButton.connect("pressed", self, "_on_confirm_pressed")


func _on_confirm_pressed():
	DateTime.set_datetime(
		$TimeSetting/TimeSlider.value,
		$SeasonSetting/DaySlider.value,
		$YearSetting/YearSlider.value
	)
