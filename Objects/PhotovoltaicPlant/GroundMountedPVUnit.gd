extends Node3D

var feature


func _ready():
	var cultivation = feature.get_attribute("cultivation")
	
	if cultivation == "0":
		$CultivationGood.visible = true
		$CultivationMid.visible = false
		$CultivationBad.visible = false
	elif cultivation == "1":
		$CultivationGood.visible = false
		$CultivationMid.visible = true
		$CultivationBad.visible = false
	elif cultivation == "2":
		$CultivationGood.visible = false
		$CultivationMid.visible = false
		$CultivationBad.visible = true
