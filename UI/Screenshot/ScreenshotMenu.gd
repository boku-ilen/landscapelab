extends BoxContainer


var pos_manager: PositionManager
var time_manager: TimeManager

#FIXME: use a calendar for timeseries

func _ready():
	$Inputs/ScreenshotButton.connect("pressed", self, "_on_screenshot")
	$Inputs/CheckBoxTimeSeries.connect("toggled", self, "_toggle_time_series")
#	$Inputs/TimeSeriesContainer/FromButton.connect(
#		"pressed", $Inputs/TimeSeriesContainer/FromButton/popupFrom, "popup")
#	$Inputs/TimeSeriesContainer/ToButton.connect(
#		"pressed", $Inputs/TimeSeriesContainer/ToButton/popupTo, "popup")


func _toggle_time_series(toggled: bool):
	$Inputs/TimeSeriesContainer.visible = toggled
	$Labels/TimeSeriesLabels.visible = toggled


func _on_screenshot():
	if not $Inputs/CheckBoxTimeSeries.pressed:
		Screencapture.screenshot(
			$Inputs/ScreenShotName.text,
			$Inputs/UpscaleViewport.value,
			$Inputs/PlantExtent.value
		)
	else:
		var prev_datetime = time_manager.date_time
		var current_datetime = $Inputs/TimeSeriesContainer/From.value
		var to = $Inputs/TimeSeriesContainer/To.value
		var interval_idx = 0
		var interval = $Inputs/TimeSeriesContainer/Interval/Hours.value
		interval +=  $Inputs/TimeSeriesContainer/Interval/Minutes.value / 60
		
		while to > current_datetime:
			time_manager.set_time(current_datetime)
			yield(get_tree(), "idle_frame")
			Screencapture.screenshot(
				$Inputs/ScreenShotName.text,
				$Inputs/UpscaleViewport.value,
				$Inputs/PlantExtent.value,
				"-%d" % interval_idx
			)
			
			current_datetime += interval
			interval_idx += 1
		
		time_manager.set_datetime_by_class(prev_datetime)
