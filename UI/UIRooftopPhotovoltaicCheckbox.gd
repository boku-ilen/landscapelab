extends CheckBox

#
# The workshop requires the option to take rooftop PV. This checkbox will spawn or
# remove a ghost asset, which will increase the energy level of the PV.
#

# save the id of the created asset so we can remove it
var asset_id = 7
var assetpos_id
# wait for the enqueued task to be done, initalize as true so the checkbox won't be disabled
var task_done : bool =  true


func _process(delta):
	# disable the option to check while the task is not done
	disabled = !task_done 


func _on_toggled(button_pressed):
	if button_pressed:
		task_done = false
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_create_rooftop_pv", []), 90)
	else:
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_remove_rooftop_pv", []), 90)


func _create_rooftop_pv(data):
	var pos = PlayerInfo.get_true_player_position()
	pos[0] = -pos[0]  # TODO: Generalize
	
	# No caching
	# FIXME: this is specific game logic
	var response = ServerConnection.get_json("/assetpos/create/%d/%d/%d.0/%d.0" % [Session.scenario_id, asset_id, pos[0], pos[2]], false)
	assetpos_id = response["assetpos_id"]
	task_done = true


func _remove_rooftop_pv(data):
	if assetpos_id:
	    # FIXME: this is specific game logic
		ServerConnection.get_json("/assetpos/remove/%d" % assetpos_id)
