extends Node3D

@export var string_size_divisor := 0.5

var feature: GeoFeature : 
	set(new_geo_feature):
		feature = new_geo_feature
		var font: Font = $Begin.font
		var town_name := feature.get_attribute("context")
		var string_size = font.get_string_size(town_name)
		var super_text := town_name
		var sub_text := ""
		
		if town_name.contains(" ") and string_size.x > 120.:
			super_text = town_name.get_slice(" ", 0)
			sub_text = town_name.erase(0, super_text.length())
		
		set_text([$Begin, $End], super_text)
		if sub_text != "":
			set_text([$Begin/Sub, $End/Sub], sub_text)
			$Begin.position.y += 0.1
			$End.position.y += 0.1


func set_text(labels_3D: Array[Label3D], text: String):
	for label_3D in labels_3D:
		label_3D.font_size = size_for_width(label_3D.font, text, 840.)
		label_3D.text = text


func size_for_width(font: Font, text: String, target_w: float,
		probe_size := 16, slack := 1.5) -> int:
	var probe_width := font.get_string_size(text, probe_size).x
	if probe_width == 0:
		return probe_size                    # empty string safety
	var fitted := int(((target_w - slack) * probe_size) / probe_width)
	return max(fitted, 1)
