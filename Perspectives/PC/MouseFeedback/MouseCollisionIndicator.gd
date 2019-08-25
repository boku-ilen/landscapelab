extends Spatial

#
# Attach this scene to the MousePoint scene. It will give an indicator on where the
# mouse cursor in the world is currently placed. 
#

onready var cursor = get_node("RayCast")
onready var player = get_tree().get_root().get_node("Main/Perspectives/FirstPersonPC")

var RAY_LENGTH = Settings.get_setting("item-spawner", "camera-ray-length") # Distance that will be checked for collision with the ground

var particle = preload("res://Perspectives/PC/MouseFeedback/Particle.tscn")

var teleport_mode : bool = false
var timer

func _ready():
	cursor.cast_to = Vector3(0, 0, -RAY_LENGTH)
	
	GlobalSignal.connect("teleport", self, "_set_teleport_mode")
	GlobalSignal.connect("poi_teleport", self, "_poi_teleport")
	particle = particle.instance()
	get_tree().get_root().add_child(particle)
	
	# Add a delay after clicking teleport mode so the input does not affect the actual
	# activation click. (Teleport button click goes through and teleports instantly) issue #89
	timer = Timer.new()
	timer.one_shot = true
	timer.connect("timeout",self,"_on_timer_timeout") 
	#timeout is what says in docs, in signals
	#self is who respond to the callback
	#_on_timer_timeout is the callback, can have any name
	add_child(timer) #to process


func _process(delta):
	if cursor.is_colliding():
		particle.translation = WorldPosition.get_position_on_ground(cursor.get_collision_point())


# This callback is called whenever any input is registered
func _unhandled_input(event):
	if teleport_mode:
		if event.is_action_pressed("teleport_player"):
			_teleport_player()
			GlobalSignal.emit_signal("teleported")
			teleport_mode = false


func _set_teleport_mode():
	timer.start(0.5)


# gets called after timer.start()-event is over
func _on_timer_timeout():
	teleport_mode = true


func _teleport_player():
	PlayerInfo.update_player_pos(WorldPosition.get_position_on_ground(cursor.get_collision_point()))


func _poi_teleport(coordinates):
	PlayerInfo.update_player_pos(WorldPosition.get_position_on_ground(Vector3(coordinates.x, 0, coordinates.y)))
	GlobalSignal.emit_signal("teleported")
	teleport_mode = false