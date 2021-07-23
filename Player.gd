extends KinematicBody

var velocity = Vector3(0, 0, 0)

onready var rotationVec = $Camera.rotation_degrees
onready var rotationMomentum = Vector3(0, 0, 0)
onready var gunBaseTransform = $Camera/GunContainer.transform


func _ready():
	if Network.networkID != 1:
		self.translation += Vector3(2, 0, 0)
		
	if not is_network_master():
		$Camera.current = false
		$Camera/ViewportContainer.visible = false
		$Camera/GunContainer.visible = false
	else:
		$Camera.current = true

remote func synchronize(transform, velocity, rotationVec):
	self.global_transform = transform
	self.velocity = velocity
	self.rotationVec = rotationVec

var shotBuffer = 0
onready var gunAnimator = $Camera/GunContainer/GunContainerAnim/AnimationPlayer
onready var gunSoundPlayer = $SoundPlayer
func handleShot():
	shotBuffer -= 1
	shotBuffer = 0 if shotBuffer < 0 else shotBuffer
	
	if shotBuffer > 0 and not gunAnimator.is_playing():
		gunAnimator.playback_speed = 1.0
		gunAnimator.stop()
		gunAnimator.play("Shoot")
		gunSoundPlayer.stop()
		gunSoundPlayer.play()

func _process(delta):
	$Camera/GunContainer.transform = gunBaseTransform
	rotationMomentum.x = clamp(rotationMomentum.x, -10, 10)
	rotationMomentum.y = clamp(rotationMomentum.y, -10, 10)
	$Camera/GunContainer.rotation_degrees.y += rotationMomentum.y
	$Camera/GunContainer.rotation_degrees.x = rotationVec.x * 13.0 / 90.0
	$Camera/GunContainer.translation.z -= 0.035 * abs(rotationVec.x) / 90.0
	
	if is_network_master():
		if Input.is_action_pressed("shoot"):
			shotBuffer = 5
		handleShot()
	
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
	rotationMomentum *= 0.94
	
	move_and_slide(velocity * 10, Vector3(0, 1, 0), true)
	$MeshInstance.rotation_degrees.y = rotationVec.y
	$Camera/ViewportContainer/Viewport/GunCamera.global_transform = $Camera.global_transform
	if is_network_master():
		rpc_unreliable("synchronize", global_transform, velocity, rotationVec)

func _input(event):
	if not is_network_master():
		return
		
	if event is InputEventMouseMotion:
		var vec = event.relative
		rotationMomentum -= Vector3(vec.y, vec.x, 0) * 0.005
		rotationVec.y -= vec.x * Global.sensitivity * 0.1
		rotationVec.x -= vec.y * Global.sensitivity * 0.1
		rotationVec.x = clamp(rotationVec.x, -90, 90)
		$Camera.rotation_degrees = rotationVec
