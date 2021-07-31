extends Sprite3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	var tex = get_viewport().get_texture()
	material_override.set_shader_param("viewportData", texture)
	material_override.set_shader_param("color1", Vector3(0.0, 0.0, 1.0))
	material_override.set_shader_param("color2", Vector3(0.0, 1.0, 1.0))
