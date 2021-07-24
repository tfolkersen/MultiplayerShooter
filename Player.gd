extends KinematicBody

var velocity = Vector3(0, 0, 0)

onready var rotationVec = $Camera.rotation_degrees
onready var rotationMomentum = Vector3(0, 0, 0)
onready var turnBaseTransform = $Camera/GCWalk/GCTurn.transform

onready var revert = $MeshInstance2.global_transform
onready var revert2 = $MeshInstance3.global_transform

func _ready():
	if Network.networkID != 1:
		self.translation += Vector3(2, 0, 0)
		
	if not is_network_master():
		$Camera.current = false
		$Camera/ViewportContainer.visible = false
		$Camera/GCWalk.visible = false
	else:
		$Camera.current = true

remote func synchronize(transform, velocity, rotationVec):
	self.global_transform = transform
	self.velocity = velocity
	self.rotationVec = rotationVec

var shotBuffer = 0
onready var gunAnimator = $Camera/GCWalk/GCTurn/GCAnim/AnimationPlayer
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


var airFrames = 0
func _physics_process(delta):
	
	$Camera/GCWalk/GCTurn.transform = turnBaseTransform
	rotationMomentum.x = clamp(rotationMomentum.x, -10, 10)
	rotationMomentum.y = clamp(rotationMomentum.y, -10, 10)
	$Camera/GCWalk/GCTurn.rotation_degrees.y += rotationMomentum.y
	$Camera/GCWalk/GCTurn.rotation_degrees.x = rotationVec.x * 13.0 / 90.0
	$Camera/GCWalk/GCTurn.translation.z -= 0.035 * abs(rotationVec.x) / 90.0
	
	#Move gun container based on walk time
	
	if is_network_master():
		if Input.is_action_pressed("shoot"):
			shotBuffer = 5
		handleShot()
	
	var gravity = 0.015 * 10
	if not is_on_floor():
		airFrames += 1
	else:
		airFrames = 0
		velocity.y = 0
	if airFrames < 1:
		gravity = 0.05
	
	velocity.y = clamp(velocity.y - gravity, -0.5 * 10, 4 * 10)
		
	#if Input.is_action_pressed("jump") and $RayCast.is_colliding() and is_network_master():
	if Input.is_action_pressed("jump") and is_on_floor() and is_network_master():
		velocity.y = 0.4 * 10
	
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
	
		var walkAnimator = $Camera/GCWalk/AnimationPlayer
		walkAnimator.set_blend_time("Walk", "Idle", 0.3)
		walkAnimator.playback_speed = 1.0
		if moveDir != Vector3(0, 0, 0):	
			walkAnimator.play("Walk")
		else:
			walkAnimator.play("Idle")
		
		moveDir = moveDir.normalized().rotated(Vector3(0, 1, 0), deg2rad(rotationVec.y))
	
		velocity.z = moveDir.z * 0.4 * 10
		velocity.x = moveDir.x * 0.4 * 10
		
	var rotVel = Vector3(velocity.x, 0, velocity.z)
	var zRot = 0
	var xRot = 0
	if is_on_floor():
		var x = Vector3(1, 0, 0)
		var y = Vector3(0, 1, 0)
		var z = Vector3(0, 0, 1)
		var norm = get_floor_normal()
		#print(norm)
		
		zRot = Vector3(y.dot(x), y.dot(y), 0).angle_to(Vector3(norm.dot(x), norm.dot(y), 0))
		xRot = Vector3(0, y.dot(y), y.dot(z)).angle_to(Vector3(0, norm.dot(y), norm.dot(z)))
		rotVel = rotVel.rotated(z, zRot)
		rotVel = rotVel.rotated(x, xRot)
		
	rotationMomentum *= 0.94
	
	print(get_floor_normal())
	#print(velocity)
	if is_on_floor():
#		print("Slide1")
		var vec = rotVel + Vector3(0, velocity.y, 0)
		move_and_slide(vec, Vector3(0, 1, 0), true, 4, deg2rad(70))
		$MeshInstance2.global_transform = revert
		$MeshInstance3.global_transform = revert2
		$MeshInstance2.look_at_from_position(Vector3(0, 0, 0), Vector3(0, 1, 0).rotated(Vector3(0, 0, 1), zRot).rotated(Vector3(1, 0, 0), xRot), Vector3(0, 1, 0))
		$MeshInstance3.global_transform = revert2
		$MeshInstance3.look_at_from_position(Vector3(0, 0, 0), get_floor_normal(), Vector3(0, 1, 0))
		$MeshInstance2.global_translate(Vector3(0, 1, 0))
		$MeshInstance3.global_translate(Vector3(1, 1, 0))
	else:
		print("Slide2")
		var vec = velocity
		move_and_slide(velocity, Vector3(0, 1, 0), true, 4, deg2rad(70))
		$MeshInstance2.global_transform = revert
		$MeshInstance3.global_transform = revert2
		$MeshInstance2.look_at_from_position(Vector3(0, 0, 0), Vector3(0, 1, 0).rotated(Vector3(0, 0, 1), zRot).rotated(Vector3(1, 0, 0), xRot), Vector3(0, 1, 0))
		$MeshInstance3.global_transform = revert2
		$MeshInstance3.look_at_from_position(Vector3(0, 0, 0), get_floor_normal(), Vector3(0, 1, 0))
		$MeshInstance2.global_translate(Vector3(0, 1, 0))
		$MeshInstance3.global_translate(Vector3(1, 1, 0))
		
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
