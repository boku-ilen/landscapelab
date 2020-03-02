extends MeshInstance
tool


func _ready():

  yield(get_tree(), "idle_frame")
  yield(get_tree(), "idle_frame")

  var gui_img = get_node("GUI").get_texture()

  var material = SpatialMaterial.new()
  material.flags_transparent = true
  material.flags_unshaded = true
  material.albedo_texture = gui_img
  set_surface_material(0, material)
