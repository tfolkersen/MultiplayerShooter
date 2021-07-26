extends Sprite3D

onready var timer = Timer.new()

func _ready():
	add_child(timer)
	timer.one_shot = true
	timer.connect("timeout", self, "timedOut")

#TODO rotate randomly somehow
func show():
	visible = true
	timer.stop()
	timer.start(0.1)
	
func timedOut():
	visible = false
