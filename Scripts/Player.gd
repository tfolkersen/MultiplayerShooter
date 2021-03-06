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

var jumpLimit = 10 #Frames before you can jump again
#TODO could also make consecutive slope jumps result in large cooldown
var jumpCooldown = 0

var airFrames = 0
var groundFrames = 0

enum guns {GOLDEN_GUN = 0, PISTOL, RIFLE}
onready var gunModels = [$Camera/GCWalk/GCTurn/GCAnim/GoldenGun, $Camera/GCWalk/GCTurn/GCAnim/pistol, $Camera/GCWalk/GCTurn/GCAnim/rifle]
onready var gunCModels = [preload("res://Scenes/Models/GoldenGun.tscn").instance(), preload("res://Scenes/Models/pistol.tscn").instance(), preload("res://Scenes/Models/rifle.tscn").instance()]
var gunCooldowns = [52, 22, 10]
var lastShot = 999999
var activeGun

onready var hitParticles = preload("res://Scenes/YellowParticleExplosion.tscn")

func groundCheck():
	if is_on_floor():
		return true
	if $GroundRay.is_colliding():
		return true
	if groundFrames >= 1 and test_move(self.transform, Vector3(0, -0.01, 0)):
		return true
	return false

func ignoreInputs():
	return not Global.allowControl

func _recursiveSetBit(obj, bit, enabled):
	if obj.has_method("set_layer_mask_bit"):
		obj.set_layer_mask_bit(bit, enabled)
	for c in obj.get_children():
		_recursiveSetBit(c, bit, enabled)
	
func _recursiveSetCastShadow(obj, enabled):
	if "cast_shadow" in obj:
		obj.cast_shadow = enabled
	for c in obj.get_children():
		_recursiveSetCastShadow(c, enabled)

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
		
		
	_recursiveSetCastShadow($Camera/GCWalk, false)
	for g in gunModels:
		_recursiveSetBit(g, 0, false)
	if not is_network_master():
		$Camera.current = false
		$Camera/ViewportContainer.visible = false
		$Camera/GCWalk.visible = false
		$playerModel.visible = true
	else:
		$Camera.current = true
		$playerModel.visible = true
		_recursiveSetBit($playerModel, 0, false)

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
		
		if $Camera/SelectRay.is_colliding():
	
			var dir = $Camera/SelectRay.cast_to.normalized()
			
			var col = $Camera/SelectRay.get_collider()
			
			var p2 = $Camera/SelectRay.get_collision_point()
			var p1 = $Camera/SelectRay.to_global($Camera/SelectRay.translation)
			dir = (p2 - p1).normalized()
			
			
			var particles = hitParticles.instance()
			#get_tree().add_child(particles)
			get_parent().add_child(particles)
			
			particles.global_translate($Camera/SelectRay.get_collision_point())
			particles.process_material.direction = -dir #This doesn't work -- probably an engine bug
			#particles.look_at(p2, Vector3(0, 1, 0))
			particles.emitting = true
			
			
			if col is RigidBody:
				
				col.apply_impulse($Camera/SelectRay.get_collision_point(), dir * 5.0)
				#col.apply_impulse(Vector3(0, 0, 0), dir * 30.0)
				
				
		
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
	if ignoreInputs():
		return
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


func _physics_process(delta):
	#print("GROUNDED: " + str(groundFrames))
	
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
		if Input.is_action_pressed("shoot") and not ignoreInputs():
			shotBuffer = 5
		handleShot()
	
	var gravity = 0.015 * 10
	if not (groundCheck()):
		airFrames += 1
		groundFrames = 0
	else:
		groundFrames += 1
		airFrames = 0
		velocity.y = 0
	if airFrames < 1:
		gravity = 0.05
	
	velocity.y = clamp(velocity.y - gravity, -0.5 * 25, 4 * 25)

	#if Input.is_action_pressed("jump") and is_on_floor() and is_network_master() and jumpCooldown == 0:
	if Input.is_action_pressed("jump") and is_network_master() and jumpCooldown == 0 and not ignoreInputs() and (groundCheck()):
		jumpCooldown = jumpLimit
		velocity.y = 0.4 * 10
		groundFrames = 0
	
	var modelSpeed = 8.0
	legAnimator.set_blend_time("Walk", "Stand", 0.2 * modelSpeed)
	legAnimator.playback_speed = modelSpeed
	armAnimator.playback_speed = 2.0
	
	if is_network_master():
		var moveDir = Vector3(0, 0, 0)
		
		if not ignoreInputs():
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
		
		
		
		#velocity.z = moveDir.z * 0.4 * 10
		#velocity.x = moveDir.x * 0.4 * 10

		quakeMove(moveDir)
		
		
	var rotVel = Vector3(velocity.x, 0, velocity.z)
	var zRot = 0
	var xRot = 0
	if groundCheck():
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
	
	if groundCheck():
		var vec = rotVel + Vector3(0, velocity.y, 0)
		move_and_slide(vec, Vector3(0, 1, 0), true, 4, deg2rad(70), false)
	else:
		var vec = velocity
		move_and_slide(velocity, Vector3(0, 1, 0), true, 4, deg2rad(70), false)
	
	
	var slideCount = get_slide_count()
	
	var collidedObjects = []
	for i in range(slideCount):
		var col = get_slide_collision(i)
		var obj = col.collider
		if obj in collidedObjects:
			continue
		if obj is RigidBody:
			obj.apply_impulse(Vector3(0, 0, 0), velocity)
		
		
	var pushNormals = []
	
	for i in range(slideCount):
		var cNorm = -get_slide_collision(i).normal
		if cNorm in pushNormals:
				continue
		pushNormals.append(cNorm)
		if Vector3(0, -1, 0).dot(cNorm) < 0.1:
			var pushFactor = 0.4
			if Vector3(0,1,0).dot(cNorm) > 0.95:
				pushFactor = 1.0
			var vNorm = velocity.normalized()
			var dot = Vector3()
			dot.x = clamp(vNorm.x * cNorm.x, 0, 1)
			dot.y = clamp(vNorm.y * cNorm.y, 0, 1)
			dot.z = clamp(vNorm.z * cNorm.z, 0, 1)
			velocity.x -= dot.x * sign(cNorm.x) * pushFactor
			velocity.y -= dot.y * sign(cNorm.y) * pushFactor
			velocity.z -= dot.z * sign(cNorm.z) * pushFactor
		
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
	if not is_network_master() or ignoreInputs():
		return
		
	if event is InputEventMouseMotion:
		var vec = event.relative
		rotationMomentum -= Vector3(vec.y, vec.x, 0) * 0.005
		rotationVec.y -= vec.x * Global.settings.sensitivity * 0.1
		rotationVec.x -= vec.y * Global.settings.sensitivity * 0.1
		rotationVec.x = clamp(rotationVec.x, -90, 90)
		$Camera.rotation_degrees = rotationVec


func airAccelerate(wishdir):
	var wishspd = 6
	var accel = 2.0
	
	wishspd = 6
	accel = 0.7
	accel = 0.5
	if wishspd > 30:
		wishspd = 30
	var currentspeed = velocity.dot(wishdir)
	var addspeed = wishspd - currentspeed
	if addspeed <= 0:
		return
	var accelspeed = accel * wishspd * (1 / 60.0)
	if accelspeed > addspeed:
		accelspeed = addspeed
		
		
	velocity.x += accelspeed * wishdir.x
	velocity.z += accelspeed * wishdir.z

func groundAccelerate(wishdir):
	var wishspd = 6
	var accel = 10.0
	
	if wishspd > 30:
		wishspd = 30
	var currentspeed = velocity.dot(wishdir)
	var addspeed = wishspd - currentspeed
	if addspeed <= 0:
		return
	var accelspeed = accel * wishspd * (1 / 60.0)
	if accelspeed > addspeed:
		accelspeed = addspeed
	
	velocity.x += accelspeed * wishdir.x
	velocity.z += accelspeed * wishdir.z

func groundFriction():
	var speed = velocity.length()
	if speed < 1.0:
		velocity.x = 0
		velocity.z = 0
		return
	
	var friction = 8
	
	var stopspeed = 1
	
	var control = stopspeed if speed < stopspeed else speed
	var drop = control * friction * (1 / 60.0)
	
	var newspeed = speed - drop
	if newspeed < 0:
		newspeed = 0
	newspeed /= speed
	
	velocity.x *= newspeed
	velocity.z *= newspeed
	
	

func quakeMove(wishdir):
	if groundFrames < 2:
		airAccelerate(wishdir)
	else:
		groundFriction()
		groundAccelerate(wishdir)
		
	#print(Vector2(velocity.x, velocity.z).length())

