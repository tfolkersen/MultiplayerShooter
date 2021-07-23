extends KinematicBody

var velocity = Vector3(0, 0, 0)

onready var rotationVec = $Camera.rotation_degrees

func _ready():
	if not is_network_master():
		$Camera.current = false
	else:
		$Camera.current = true

func _process(delta):
	velocity.y = clamp(velocity.y - 0.015, -0.5, 4)
	
	if is_on_floor():
		velocity.y = 0
		
	if Input.is_action_pressed("jump") and $RayCast.is_colliding():
		velocity.y = 0.4
	
	var moveDir = Vector3(0, 0, 0)
	
	if Input.is_action_pressed("forward"):
		moveDir += Vector3(0, 0, -1)
	if Input.is_action_pressed("back"):
		moveDir += Vector3(0, 0, 1)
	if Input.is_action_pressed("left"):
		moveDir += Vector3(-1, 0, 0)
	if Input.is_action_pressed("right"):
		moveDir += Vector3(1, 0, 0)
	
	moveDir = moveDir.normalized().rotated(Vector3(0, 1, 0), deg2rad(rotationVec.y))
	
	velocity.z = moveDir.z * 0.4
	velocity.x = moveDir.x * 0.4
	
	move_and_slide(velocity * 10, Vector3(0, 1, 0))

func _input(event):
	if event is InputEventMouseMotion:
		var vec = event.relative
		rotationVec.y -= vec.x * Global.sensitivity * 0.1
		rotationVec.x -= vec.y * Global.sensitivity * 0.1
		rotationVec.x = clamp(rotationVec.x, -90, 90)
		
		$Camera.rotation_degrees = rotationVec
		$MeshInstance.rotation_degrees.y = rotationVec.y
