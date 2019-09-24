extends CheckBox

#
# The workshop requires the option to take rooftop PV. This checkbox will spawn or
# remove a ghost asset, which will increase the energy level of the PV.
#

# save the id of the created asset so we can remove it
var id
# wait for the enqueued task to be done, initalize as true so the checkbox won't be disabled
var task_done : bool =  true


func _process(delta):
	# disable the option to check while the task is not done
	disabled = !task_done 


func _on_toggled(button_pressed):
	if button_pressed:
		task_done = false
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_manage_rooftop_pv", []), 16)
	else:
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_remove_rooftop_pv", []), 15)


func _create_rooftop_pv():
	#var response = ServerConnection.get_json("/assetpos/create/%d/7/0/0" % [Session.scenario_id])
	#id = response["assetpos_id"]
	task_done = true
	pass


func _remove_rooftop_pv():
	#ServerConnection.get_json("/assetpos/remove/%d" % id)
	pass