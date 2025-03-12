class_name LayerCompositionConnection
extends Node

# References to the source and target layer compositions
var source_composition: LayerComposition
var target_composition: LayerComposition


func _init(source: LayerComposition, target: LayerComposition):
	source_composition = source
	target_composition = target

	# Observe the source layer composition’s application of data
	source_composition.render_info.render_scene.applied.connect(_on_fully_applied)


func _on_fully_applied(new_features, removed_features):
	var extracted_data = extract_relevant_data(source_composition, new_features, removed_features)
	apply_to_target(target_composition, extracted_data)


func extract_relevant_data(source: LayerComposition, 
							new_features: Array, 
							removed_features: Array) -> Variant:
	return null  # Placeholder, subclasses implement this


func apply_to_target(target: LayerComposition, data: Variant):
	pass  # Placeholder, subclasses implement this
