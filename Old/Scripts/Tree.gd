extends "EnvironmentalObject.gd"


func _ready():
	pass

#func _process(delta):
#	pass

func set_model(modelType):
	var mi = MeshInstance.new()
	add_child(mi)
	mi.set_mesh(modelType)
	pass