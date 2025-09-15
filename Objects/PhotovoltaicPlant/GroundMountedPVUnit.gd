extends Node3D

var feature


func _ready():
	var cultivation = feature.get_attribute("cultivation")
	
	# "CultivationGood" is the default, which is in the saved scene to speed up loading of this default.
	# If the cultivation according to the data differs, we delete this node and add the correct one.
	
	if cultivation == "1":
		get_node("CultivationGood").queue_free()
		add_child(preload("res://Objects/PhotovoltaicPlant/CultivationMid.tscn").instantiate())
	elif cultivation == "0":
		get_node("CultivationGood").queue_free()
		add_child(preload("res://Objects/PhotovoltaicPlant/CultivationBad.tscn").instantiate())
	# cultivation == "2" corresponds to the default, CultivationGood, which is already in the scene
