@abstract
extends HBoxContainer
class_name GraphNodeElement

var slot_type: String

enum GraphNodeElementType {
	TextIn, TextOut, TextConstant,
	ScalarIn, ScalarOut, ScalarConstant
}
static func element_type_to_class(e: String) -> GraphNodeElement:
	return {
		"text_input": TextInElement.new() as GraphNodeElement,
		"text_output": TextOutElement.new() as GraphNodeElement,
		"scalar_input": ScalarInElement.new() as GraphNodeElement,
		"vector_input": VectorInElement.new() as GraphNodeElement,
		"array_input": ArrayInElement.new() as GraphNodeElement,
		"boolean_input": BooleanInElement.new() as GraphNodeElement,
		"array_output": ArrayOutElement.new() as GraphNodeElement,
		"scalar_output": ScalarOutElement.new() as GraphNodeElement,
		"vector_output": VectorOutElement.new() as GraphNodeElement,
		"boolean_output": BooleanOutElement.new() as GraphNodeElement,
		"scalar_constant": ScalarConstantElement.new() as GraphNodeElement,
		"vector_constant": VectorConstantElement.new() as GraphNodeElement,
		"text_constant": TextConstantElement.new() as GraphNodeElement,
		"dropdown": DropdownElement.new() as GraphNodeElement,
		"dynamic_populate": DynamicPopulateElement.new() as GraphNodeElement
	}[e]

signal input_connection_updated(new_source, source_slot)

@abstract 
func get_input_type() -> String

@abstract
func get_output_type() -> String

@abstract
func create_ui(label: String) -> void

func get_additional_serialization_data()->Dictionary:
	return {}
	
