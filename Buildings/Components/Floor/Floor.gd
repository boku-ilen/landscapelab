extends MeshInstance3D


@export var color: Color
@export var resize_by: float
@export var height := 2.5


func build(footprint: Array[Vector3]):
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate flat normals - shaded as if round otherwise
	st.set_smooth_group(-1)
	st.set_color(color)
	
	var expanded_f = FootprintOperations.resize(footprint, resize_by)
	
	
