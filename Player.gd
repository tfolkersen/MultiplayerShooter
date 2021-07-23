extends KinematicBody

var velocity = Vector3(0, 0, 0)

onready var rotationVec = $Camera.rotation_degrees

func _ready():
	if Network.networkID != 1:
		self.translation += Vector3(2, 0, 0)
		
	if not is_network_master():
		$Camera.current = false
		$Camera/ViewportContainer.visible = false
		$Camera/ViewModel.visible = false
	else:
		$Camera.current = true

remote func synchronize(transform, velocity, rotationVec):
	self.global_transform = transform
	self.velocity = velocity
	self.rotationVec = rotationVec

func _process(delta):
	velocity.y = clamp(velocity.y - 0.015, -0.5, 4)
	
	if is_on_floor():
		velocity.y = 0
		
	if Input.is_action_pressed("jump") and $RayCast.is_colliding() and is_network_master():
		velocity.y = 0.4
	
	if is_network_master():
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
	$MeshInstance.rotation_degrees.y = rotationVec.y
	$Camera/ViewportContainer/Viewport/GunCamera.global_transform = $Camera.global_transform
	if is_network_master():
		rpc_unreliable("synchronize", global_transform, velocity, rotationVec)

func _input(event):
	if not is_network_master():
		return
		
	if event is InputEventMouseMotion:
		var vec = event.relative
		rotationVec.y -= vec.x * Global.sensitivity * 0.1
		rotationVec.x -= vec.y * Global.sensitivity * 0.1
		rotationVec.x = clamp(rotationVec.x, -90, 90)
		
		$Camera.rotation_degrees = rotationVec
