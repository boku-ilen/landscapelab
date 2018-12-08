extends Spatial

var server = global.server
var port = global.port

var areas

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
	
	
	areas = ServerConnection.getJson(server, "/location/areas/", port)
	if areas.has("Error"):
		ErrorPrompt.show("can not load areas", areas["Error"])
	else:
		areas = areas["Areas"]
		create_choose_area_list()
	pass

func _process(delta):
	pass


func create_choose_area_list():
	#creating startup list
	var startupUI = preload("res://Scenes/UI/StartupUI.tscn").instance()
	get_node("ViewportContainer/DesktopViewport").add_child(startupUI)
	var list = get_node("ViewportContainer/DesktopViewport/StartupUI/CenterContainer/ItemList")
	for i in areas:
		list.add_item(i)



func init_world(index):
	logger.info("loading area %s" % areas[index])
	var settings = ServerConnection.getJson(server,"/location/areas/?filename=%s" % areas[index], port)
	if settings.has("Error"):
		ErrorPrompt.show("could not load %s" % areas[index], settings["Error"])
	else:
		
		# call function to create 'world'
		# settings: 
			# name of DHM with ending (.tif)
			# split parameter for surface - 5 means 25 parts
			# lod parameter - 9 means every 9th pixel is loaded
			# json with trees coordinates
		world.createWorld(server, port, settings)
		
		var UI = preload("res://Scenes/UI/UI.tscn").instance()
		get_node("ViewportContainer/DesktopViewport").add_child(UI)



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
