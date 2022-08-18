extends CenterContainer
class_name StackedProgressBar
tool


export var bar_count := 1 setget set_bar_count
export var min_value := 0.0 setget set_min_value
export var max_value := 100.0 setget set_max_value
export var step := 0.01 setget set_step

var progress_bars: Array
var progress_bar_values := [] setget set_progress_bar_values

var summed_value: float


func get_progress_bar_at_index(index: int):
	return progress_bars[index] if index < progress_bars.size() else null


func set_progress_bar_value_at_index(index: int, value: float):
	progress_bar_values[index] = value


func set_progress_bar_color_at_index(index: int, color: Color):
	# Get current stylebox of the progress, duplicate so it only affects this node
	# and only override the background color so it fits the rest of the theme
	var new_stylebox = progress_bars[index].get_stylebox("fg").duplicate()
	# For many themes, a texture could be used which does not have a color
	# in no styleboxflat is used, create one on our own
	if "bg_color" in new_stylebox:
		new_stylebox.bg_color = color
		progress_bars[index].add_stylebox_override("fg", new_stylebox)
	else: 
		new_stylebox = StyleBoxFlat.new()
		new_stylebox.bg_color = color
		progress_bars[index].add_stylebox_override("fg", new_stylebox)


func get_progress_bar_color_at_index(index: int):
	if "bg_color" in progress_bars[index].get_stylebox("fg"):
		return progress_bars[index].get_stylebox("fg").bg_color


func set_progress_bar_values(vals):
	progress_bar_values = vals
	# For quick access from outside
	summed_value = 0
	for val in vals: summed_value += val
	
	_update_progress_bars()


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
	# Negative bar count is senseless
	if count < 1:
		bar_count = 0
	else:
		bar_count = count
	
	# Add/remove bars until adequate
	while true:
		if count > progress_bars.size():
			var bar = ProgressBar.new()
			progress_bars.append(bar)
			if not progress_bars.size() == 1:
				bar.add_stylebox_override("bg", StyleBoxEmpty.new())
				bar.percent_visible = false
			progress_bar_values.append(0.0)
			add_child(bar)
		elif count < progress_bars.size():
			progress_bars.pop_back().queue_free()
			progress_bar_values.pop_back()
		else:
			break
	
	# Adjust size so it will fit the center container
	for child in get_children():
		child.rect_min_size = rect_size
	
	# If the bar count changes it must be displayed in the ui
	property_list_changed_notify()


# Define additional properties (i.e. export vars)
func _get_property_list():
	var properties = []
	for i in range(bar_count):
		# Super group defined via "range%d_"
		properties.append({
			name = "ProgressBar %d" % i, type = TYPE_NIL, hint_string = "range%d_" % i, 
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		})
		
		# Sub properties hinted by "range%d_"
		properties.append({
			name = "range%d_value" % i, type = TYPE_REAL
		})
		properties.append({
			name = "range%d_bar_color" % i, type = TYPE_COLOR
		})
	
	return properties


# Custom getters (i.e. setget) for custom properties
func _get(property):
	if property.begins_with("range"):
		if property.ends_with("_value"):
			var name_as_index: String = property.lstrip("range").rstrip("_value")
			var index_from_name = int(name_as_index)
			return progress_bar_values[index_from_name]
		
		if property.ends_with("_bar_color"):
			var name_as_index: String = property.lstrip("range").rstrip("_value")
			var index_from_name = int(name_as_index)
			if "bg_color" in progress_bars[index_from_name].get_stylebox("fg"):
				return progress_bars[index_from_name].get_stylebox("fg").bg_color


# Custom setters  (i.e. setget) for custom properties
func _set(property, value):
	# Find the according property by looping through all of the
	if property.begins_with("range"):
		if property.ends_with("_value"):
			# Get id from property string
			var name_as_index: String = property.lstrip("range").rstrip("_value")
			var index_from_name = int(name_as_index)
			progress_bar_values[index_from_name] = value
			# If any progress bar changes, potentially all will change
			_update_progress_bars()
			return true
		
		if property.ends_with("_bar_color"):
			# Get id from property string
			var name_as_index: String = property.lstrip("range").rstrip("_bar_color")
			var index_from_name = int(name_as_index)
			set_progress_bar_color_at_index(index_from_name, value)
			return true


func _update_progress_bars():
	for i in range(progress_bars.size()): 
		progress_bars[i].value = 0
		print(get_progress_bar_color_at_index(i))
		for j in range(progress_bars.size() - i):
			progress_bars[i].value += progress_bar_values[progress_bars.size() - 1 - j] 


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
