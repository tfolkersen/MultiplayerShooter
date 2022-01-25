extends Particles


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.start(0.4)
	timer.connect("timeout", self, "_onTimeout")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _onTimeout():
	queue_free()

func _on_Particles_tree_exiting():
	print("PARTICLES GONE")
