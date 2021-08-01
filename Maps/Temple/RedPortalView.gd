extends Sprite3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	



func _process(delta):
	var frac = (sin(time / 2.0) + 1.0) / 2.0
	$OmniLight9.light_color = Color(1.0, 0.0, 0.0, 1.0).linear_interpolate(Color(1.0, 1.0, 0.0, 1.0), frac)
	time += delta;
	
	material_override.set_shader_param("viewportData", texture)
	material_override.set_shader_param("color1", Vector3(1.0, 0.0, 0.0))
	material_override.set_shader_param("color2", Vector3(1.0, 1.0, 0.0))

