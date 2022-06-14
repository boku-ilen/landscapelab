extends VBoxContainer


var time_manager: TimeManager


func _ready():
	$ConfirmButton.connect("pressed", self, "_on_confirm_pressed")
	
	$TimeSetting/TimeSlider.connect("value_changed", self, "_update_spinbox", 
		[$TimeSetting/SpinBox])
	$SeasonSetting/DaySlider.connect("value_changed", self, "_update_spinbox", 
		[$SeasonSetting/SpinBox])
	$YearSetting/YearSlider.connect("value_changed", self, "_update_spinbox", 
		[$YearSetting/SpinBox])
	
	$TimeSetting/SpinBox.connect("value_changed", self, "_update_slider", 
		[$TimeSetting/TimeSlider])
	$SeasonSetting/SpinBox.connect("value_changed", self, "_update_slider", 
		[$SeasonSetting/DaySlider])
	$YearSetting/SpinBox.connect("value_changed", self, "_update_slider", 
		[$YearSetting/YearSlider])


func _on_confirm_pressed():
	time_manager.set_datetime(
		$TimeSetting/TimeSlider.value,
		$SeasonSetting/DaySlider.value,
		$YearSetting/YearSlider.value
	)


func _update_spinbox(value, spinbox: SpinBox):
	spinbox.value = value


func _update_slider(value, slider: HSlider):
	slider.value = value
