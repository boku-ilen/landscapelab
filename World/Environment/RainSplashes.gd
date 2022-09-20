extends Spatial


export var splash_area = 50
export var splashes_per_second = 300
export var splash_pool_size = 200
var splash_obj = preload("res://World/Environment/RainSplash.tscn")
var splashes = []
 
var time_since_splash = 0
var splash_rate = 1.0 / splashes_per_second
var cur_splash_ind = 0
 
var center_node: Spatial setget set_center_node

func set_center_node(node: Spatial):
	if center_node:
		center_node.get_node("RainRemoteTransform2").queue_free()
	center_node = node
	var rt = RemoteTransform.new()
	rt.name = "RainRemoteTransform2"
	rt.remote_path = get_path()
	rt.update_rotation = false
	rt.update_scale = false
	rt.update_position = true
	node.add_child(rt)

func _ready():
	for i in range(splash_pool_size):
		var s = splash_obj.instance()
		add_child(s)
		splashes.append(s)
		#s.hide()
 

func _process(delta):
	time_since_splash += delta
	while time_since_splash >= splash_rate:
		make_splash()
		cur_splash_ind += 1
		cur_splash_ind %= splashes.size()
		time_since_splash -= splash_rate
 

func make_splash():
	var x_pos = rand_range(-splash_area, splash_area)
	var z_pos = rand_range(-splash_area, splash_area)
	var start_pos = global_transform.origin + Vector3(x_pos, 5000, z_pos)
 
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(start_pos, Vector3(0, -5000, 0))
	if result.size() > 0:
		splashes[cur_splash_ind].global_transform.origin = result.position + Vector3(0, 0.2, 0)
		splashes[cur_splash_ind].emitting = true
