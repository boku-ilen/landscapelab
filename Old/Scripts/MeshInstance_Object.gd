extends MeshInstance

export (Vector3) var trans = Vector3(0,9,0) setget set_translation

func _ready():
	var tr = get("translation")
	#print(tr)

func set_translation(value):
	trans = value
	set("translation", trans)
	#print(trans)