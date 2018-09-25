extends MeshInstance

export var lod_steps = [4,1,0]
export var lod_distances = [100,50,10]

signal update_tree_pos

var player
var origin
var outer_borders
var lod_lv

var dhmName
var height_scale
var splits
var part
var waiting = false

var thread

func _ready():
	player = get_tree().get_root().get_node("main/ViewportContainer/DesktopViewport/Camera")
	lod_lv = 0
	pass

func set_data(orig, ob, dhm, h_scale, spl, p):
	origin = orig
	outer_borders = ob
	
	dhmName = dhm
	height_scale = h_scale
	splits = spl
	part = p


func _process(delta):
	if not waiting:
		var change = false
		
		while (lod_lv < lod_steps.size() and lod_lv < lod_distances.size()
		and origin.distance_to(player.global_transform.origin) < lod_distances[lod_lv] + outer_borders):
			change = true
			lod_lv += 1
		
		if change:
			if thread == null:
				thread = Thread.new()
			if thread.is_active():
				thread.wait_to_finish()
			waiting = true
			thread.start(self, "update_mesh", null, 1)


func update_mesh(userdata):
	logger.info("Updating %s to lod_lv %d" % [name, lod_lv])
	var jsonTerrainData = ServerConnection.getJson("http://127.0.0.1","/dhm/?filename=%s&splits=%d&skip=%d&part=%d" % [dhmName, splits, lod_steps[lod_lv - 1], part],8000)
	
	var jsonMeshData = get_parent().jsonTerrain(jsonTerrainData)
	var img_res = get_parent().jsonTerrainDimensions(jsonTerrainData)[0]
	var pixel_scale = get_parent().jsonTerrainPixel(jsonTerrainData)[0]
	
	var newMesh = get_parent().create_mesh(jsonMeshData, origin, img_res,  height_scale, pixel_scale, splits, part)[0]
	set_mesh(newMesh)
	remove_child(get_node("%s_col" % name))
	create_trimesh_collision()
	
	for i in range(get_child_count()):
		if get_child(i).has_method("update_position"):
			get_child(i).call_deferred("update_position")
	#maybe use signals instead
	
	logger.info("Successfully updated %s to lod_lv %d" % [name, lod_lv])
	waiting = false
	