extends StaticBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _physics_process(delta):
	#rotation_degrees.x += 0.2
	rotate(Vector3(1, 0, 0), deg2rad(0.2))
