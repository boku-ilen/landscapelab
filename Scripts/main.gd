tool
extends Spatial

onready var world = get_node("World")

#TODO: load objects from server (jpg/png/tres)

func update_preview_size():
	var new_size = OS.window_size
	$ViewportContainer/DesktopViewport.size = new_size

func _ready():
	# init our viewport size and register resize 
	update_preview_size()
	get_tree().get_root().connect("size_changed", self, "update_preview_size")
		
	logger.set_filename("log.txt")
	logger.set_level(0)
	#logger.info(str(ServerConnection.getJson("http://127.0.0.1","/dhm/300.tif/10/0",8000).result))
	#logger.info(str(ServerConnection.getJson("http://127.0.0.1","/dhm/bisamberg_klein.png",8000).result))
	
	#TODO: if picture split, load all parts and set properly parameters: size, resolution, scale
	
	var jsonForestTrees = ServerConnection.getJson("http://127.0.0.1","/assetpos?filename=forest_areas&tree_multiplier=0.01&recalc=true",8000)
	
	world.createWorld("DTM_10x10_UTM_30km.tif", 5, jsonForestTrees) #300px -> 301x301 height-points json-data
	
	pass

func _process(delta):
	pass


func _on_VRToggled(turned_on):
	if turned_on:
		logger.info("turning VR on")
		
		#instantiate VRPlayer
		var VRPlayer = preload("res://Scenes/VRPlayer.tscn").instance()
		add_child(VRPlayer)
		
		#set vr camera mimicing on
		get_node("ViewportContainer/DesktopViewport/Camera").set_vrmode(true)
	else:
		logger.info("turning VR off")
		
		#set vr camera mimicing off
		var VRPlayer = get_node("VRViewport")
		if VRPlayer:
			VRPlayer.queue_free()
		
		get_node("ViewportContainer/DesktopViewport/Camera").set_vrmode(false)
	
	pass # replace with function body
