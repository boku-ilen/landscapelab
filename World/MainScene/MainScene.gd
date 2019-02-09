extends Spatial

func _ready():
	var scenario = Session.get_scenario()
	
	# Instance TileSpawner with the appropriate variables