tool
extends Spatial

onready var world = get_node("World")

func update_preview_size():
	var new_size = OS.window_size
	$ViewportContainer/DesktopViewport.size = new_size

func _ready():
	logger.info("main initialize")
	# init our viewport size and register resize 
	update_preview_size()
	get_tree().get_root().connect("size_changed", self, "update_preview_size")
		
	logger.set_filename("log.txt")
	logger.set_level(0)

	# load json with XZ coordinates for single tree
	# settings: 
		# filename - name of shp
		# multiplier - 1 (all data) or less than 1 (part of all data)
		#recalc - true if trees placed also on the boarder of shp
	# example of json fragment: 
		# "{"model": "eiche1", "coord": [597599.9999999994, 5385567.762951786]}"
	# example for showing json in browser: 
		# http://127.0.0.1:8000/assetpos?filename=forest_areas&tree_multiplier=0.00001&recalc=true
	var jsonForestTrees = ServerConnection.getJson("http://127.0.0.1","/assetpos?filename=forest_areas&tree_multiplier=0.001&recalc=true",8000)
	
	# call function to create 'world'
	# settings: 
		# name of DHM with ending (.tif)
		# split parameter for surface - 5 means 25 parts
		# lod parameter - 9 means every 9th pixel is loaded
		# json with trees coordinates
	world.createWorld("DTM_10x10_UTM_30km.tif", 5, 9, jsonForestTrees)
	
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
