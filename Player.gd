extends KinematicBody

var velocity = Vector3(0, 0, 0)

onready var rotationVec = $Camera.rotation_degrees
onready var rotationMomentum = Vector3(0, 0, 0)
onready var turnBaseTransform = $Camera/GCWalk/GCTurn.transform

var notWalking = 4000

onready var armAnimator = $playerModel/ArmAnimator
onready var legAnimator = $playerModel/LegAnimator
var baseWaistTransform

var cameraBone = "Chest"

var jumpLimit = 20 #Frames before you can jump again
#TODO could also make consecutive slope jumps result in large cooldown
var jumpCooldown = 0

enum guns {GOLDEN_GUN = 0, PISTOL, RIFLE}
onready var gunModels = [$Camera/GCWalk/GCTurn/GCAnim/GoldenGun, $Camera/GCWalk/GCTurn/GCAnim/pistol, $Camera/GCWalk/GCTurn/GCAnim/rifle]
onready var gunCModels = [preload("res://GoldenGun.tscn").instance(), preload("res://pistol.tscn").instance(), preload("res://rifle.tscn").instance()]
var gunCooldowns = [52, 22, 10]
var lastShot = 999999
var activeGun

func _ready():
	print(global_transform.origin)
	
	$Camera/GCWalk/GCTurn/GCAnim/AnimationPlayer.connect("animation_finished", self, "_onGCAnimDone")
	armAnimator.set_blend_time("ArmsDown", "ArmUp", 0.6)
	swapToGun(guns.GOLDEN_GUN)
	
	var skel = $playerModel/Armature/Skeleton
	var waist = skel.find_bone(cameraBone)
	baseWaistTransform = skel.get_bone_pose(waist)
	
	#attach stuff to bones
	var att = BoneAttachment.new()
	att.name = "HandR"
	att.bone_name = "Hand.R"
	var hand = skel.find_bone("Hand.R")
	skel.add_child(att)
	var cmflash = $playerModel/CModelFlash
	$playerModel.remove_child(cmflash)
	att.add_child(cmflash)
	cmflash.set_owner(att)
	for model in gunCModels:
		model.visible = false
		model.rotation_degrees = Vector3(90, 30, 90)
		model.setLayerMaskBit(0, true)
		model.setLayerMaskBit(1, false)
		att.add_child(model)
	
	if Network.networkID != 1:
		pass
		#self.translation += Vector3(0, 2, 0)
		
	if not is_network_master():
		$Camera.current = false
		$Camera/ViewportContainer.visible = false
		$Camera/GCWalk.visible = false
		$playerModel.visible = true
	else:
		$Camera.current = true
		$playerModel.visible = false

remote func synchronize(transform, velocity, rotationVec):
	self.global_transform = transform
	self.velocity = velocity
	self.rotationVec = rotationVec

var shotBuffer = 0
onready var gunAnimator = $Camera/GCWalk/GCTurn/GCAnim/AnimationPlayer
onready var gunSoundPlayer = $SoundPlayer

remote func cModelShotAnim():
	var hand = get_node("playerModel/Armature/Skeleton/HandR")
	hand.get_node("CModelFlash").show()
	var gun = gunCModels[activeGun]
	var flash = hand.get_node("CModelFlash")
	flash.global_transform = gun.get_node("BarrelTip").global_transform
	gunSoundPlayer.stop()
	gunSoundPlayer.play()


func handleShot():
	shotBuffer -= 1
	shotBuffer = 0 if shotBuffer < 0 else shotBuffer
	
	if shotBuffer > 0 and lastShot >= gunCooldowns[activeGun] and not (gunAnimator.is_playing() and gunAnimator.current_animation in ["SwapIn", "SwapOut", "Reload"]):
		lastShot = 0
		gunAnimator.playback_speed = 1.0
		gunAnimator.stop()
		gunAnimator.play("Shoot")
		gunSoundPlayer.stop()
		gunSoundPlayer.play()
		
		var flash = $Camera/GCWalk/GCTurn/GCAnim/flash
		var gun = gunModels[activeGun]
		var barrel = gun.get_node("BarrelTip")
		flash.global_transform = barrel.global_transform
		flash.show()
		
		rpc("cModelShotAnim")
		
		#Shot multiplayer anim

func swapOut():
	if is_network_master():
		armAnimator.rpc("playRemote", "ArmsDown")
	$Camera/GCWalk/GCTurn/GCAnim/AnimationPlayer.play("SwapOut")

func swapIn(gun):
	if is_network_master():
		armAnimator.rpc("playRemote", "ArmUp")
	activeGun = gun
	for model in gunModels:
		model.visible = false
	gunModels[activeGun].visible = true
	
	if not is_network_master() or true:
		for model in gunCModels:
			model.visible = false
		gunCModels[activeGun].visible = true
	$Camera/GCWalk/GCTurn/GCAnim/AnimationPlayer.play("SwapIn")
	

func _onGCAnimDone(animName):
	if animName == "SwapOut":
		swapIn(nextGun)

var nextGun
remotesync func swapToGun(gun):
	if gun != activeGun:
		nextGun = gun
		#rset("nextGun", gun)
		swapOut()
	
func handleItemSwap():
	if is_network_master():
		if Input.is_action_just_pressed("item1"):
			print("Swapping to golden gun")
			rpc("swapToGun", guns.GOLDEN_GUN)
			#swapToGun(guns.GOLDEN_GUN)
		if Input.is_action_just_pressed("item2"):
			print("Swapping to pistol")
			rpc("swapToGun", guns.PISTOL)
			#swapToGun(guns.PISTOL)
		if Input.is_action_just_pressed("item3"):
			print("Swapping to rifle")
			rpc("swapToGun", guns.RIFLE)
			#swapToGun(guns.RIFLE)

var airFrames = 0
func _physics_process(delta):
	lastShot += delta * 60.0
	handleItemSwap()
	
	jumpCooldown = clamp(jumpCooldown - delta * 60.0, 0, jumpLimit)
	
	$Camera/GCWalk/GCTurn.transform = turnBaseTransform
	rotationMomentum.x = clamp(rotationMomentum.x, -15, 12)
	rotationMomentum.y = clamp(rotationMomentum.y, -15, 12)
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
	if Input.is_action_pressed("jump") and is_on_floor() and is_network_master() and jumpCooldown == 0:
		jumpCooldown = jumpLimit
		velocity.y = 0.4 * 10
	
	var modelSpeed = 8.0
	legAnimator.set_blend_time("Walk", "Stand", 0.2 * modelSpeed)
	legAnimator.playback_speed = modelSpeed
	armAnimator.playback_speed = 2.0
	
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
			notWalking = 0
		else:
			notWalking += 1
		
		if notWalking >= 10:
			walkAnimator.play("Idle")
			if is_network_master():
				pass
				#$playerModel/AnimationPlayer.rpc("playRemote", "Stand")
		else:
			walkAnimator.play("Walk")
			if is_network_master():
				legAnimator.rpc("playRemote", "Walk")
		
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
		
		
		var normXY = Vector3(norm.dot(x), norm.dot(y), 0)
		var normYZ = Vector3(0, norm.dot(y), norm.dot(z))
		zRot = Vector3(y.dot(x), y.dot(y), 0).angle_to(normXY)
		xRot = Vector3(0, y.dot(y), y.dot(z)).angle_to(normYZ)
		
		if x.angle_to(normXY) <= deg2rad(90):
			zRot = -zRot
		if (-z).angle_to(normYZ) <= deg2rad(90):
			xRot = -xRot
		
		rotVel = rotVel.rotated(z, zRot)
		rotVel = rotVel.rotated(x, xRot)
		
		
	rotationMomentum *= 0.94
	
	if is_on_floor():
		var vec = rotVel + Vector3(0, velocity.y, 0)
		move_and_slide(vec, Vector3(0, 1, 0), true, 4, deg2rad(70))
	else:
		var vec = velocity
		move_and_slide(velocity, Vector3(0, 1, 0), true, 4, deg2rad(70))
		
	$MeshInstance.rotation_degrees.y = rotationVec.y
	$playerModel.rotation_degrees.y = rotationVec.y - 180
	#Bones
	var skel = $playerModel/Armature/Skeleton
	var waist = skel.find_bone(cameraBone)
	var waistTransform = baseWaistTransform
	skel.set_bone_pose(waist, waistTransform.rotated(Vector3(1, 0, 0), deg2rad(-rotationVec.x)))
	
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


