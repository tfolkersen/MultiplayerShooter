extends ColorRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	fillScreen()
	
func _process(delta):
	get_material().set_shader_param("time", OS.get_ticks_msec())

func fillScreen():
	var size = get_viewport().size
	rect_size = size
	get_material().set_shader_param("dims", size)

