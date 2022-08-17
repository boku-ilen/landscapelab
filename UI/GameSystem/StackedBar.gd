extends CenterContainer
tool


export var bar_count := 1 setget set_bar_count
export var min_value := 0.0 setget set_min_value
export var max_value := 100.0 setget set_max_value
export var step := 0.01 setget set_step

var progress_bars: Array
var summed_value := 0


func set_step(st: float):
	step = st
	for bar in get_children():
		bar.step = step


func set_min_value(val: float): 
	min_value = val
	for bar in progress_bars:
		bar.min_value = min_value


func set_max_value(val: float): 
	max_value = val
	for bar in progress_bars:
		bar.max_value = max_value


func set_bar_count(count: int):
	if bar_count < 1:
		count = 1
	
	bar_count = count
	while true:
		if count > progress_bars.size():
			var bar = ProgressBar.new()
			if not count == 1:
				bar.add_stylebox_override("bg", StyleBoxEmpty.new())
				bar.percent_visible = false
			add_child(bar)
			progress_bars.append(bar)
		elif count < get_child_count():
			progress_bars.pop_back().queue_free()
		else:
			break
	print(progress_bars.size())
	
	for child in get_children():
		child.rect_min_size = rect_size
	
	property_list_changed_notify()


func _get(property):
	for i in range(bar_count):
		summed_value = 0
		if property == "range%d_value" % i:
			var temp_value = summed_value
			summed_value += progress_bars[i].value
			return progress_bars[i].value - temp_value
		if property == "range%d_color" % i:
			return progress_bars[i].get_stylebox("fg").bg_color
	

func _set(property, value):
	for i in range(bar_count):
		summed_value = 0
		if property == "range%d_value" % i:
			property = value
			summed_value += value
			progress_bars[i].value = summed_value
			return true
		if property == "range%d_color" % i:
			property = value
			# Get current stylebox of the progress, duplicate so it only affects this node
			# and only override the background color so it fits the rest of the theme
			var new_stylebox = progress_bars[i].get_stylebox("fg").duplicate()
			# For many themes, a texture could be used which does not have a color
			# in no styleboxflat is used, create one on our own
			if "bg_color" in new_stylebox:
				new_stylebox.bg_color = value
				progress_bars[i].add_stylebox_override("fg", new_stylebox)
			else: 
				new_stylebox = StyleBoxFlat.new()
				new_stylebox.bg_color = value
				progress_bars[i].add_stylebox_override("fg", new_stylebox)
			return true


func _get_property_list():
	var properties = []
	for i in range(bar_count):
		properties.append({
			name = "ProgressBar %d" % i, type = TYPE_NIL, hint_string = "range%d_" % i, 
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		})
		
		properties.append({
			name = "range%d_value" % i, type = TYPE_REAL
		})
		properties.append({
			name = "range%d_bar_color" % i, type = TYPE_COLOR
		})

	return properties


func _ready():
	connect("child_entered_tree", self, "child_entered_tree")
	_update()


func _update():
	set_bar_count(bar_count)
	set_min_value(min_value)
	set_max_value(max_value)
	set_step(step)


func child_entered_tree(node: Node):
	if not node is ProgressBar:
		node.queue_free()
