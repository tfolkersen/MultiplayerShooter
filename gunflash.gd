extends Sprite3D

onready var timer = Timer.new()

func _ready():
	add_child(timer)
	timer.one_shot = true
	timer.connect("timeout", self, "timedOut")

func show():
	print("Showing flash")
	visible = true
	rotation_degrees = Vector3(randf() * 360.0, randf() * 360.0, randf() * 360.0)
	timer.stop()
	timer.start(0.1)
	
func timedOut():
	visible = false
