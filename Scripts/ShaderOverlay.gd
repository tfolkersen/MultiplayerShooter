extends ColorRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	fillScreen()
	
	
var playing = false
var frame = 0
var lastFrame = 280
var black = false

func _process(delta):
	if playing:
		get_material().set_shader_param("frame", frame)
		get_material().set_shader_param("lastFrame", lastFrame)
		visible = true
	else:
		visible = false
	
	if Global.allowControl:
		if Input.is_key_pressed(KEY_KP_0):
			startAnimation()
		if Input.is_key_pressed(KEY_KP_1):
			playing = false
		
	frame += 1
	
	
func startAnimation():
	playing = true
	frame = 0
	
func fillScreen():
	var size = get_viewport().size
	rect_size = size
	get_material().set_shader_param("dims", size)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
