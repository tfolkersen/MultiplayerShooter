extends Node

var settingsShown = false

var playerName = "Unnamed"
var sensitivity = 0.5
var resolutionX = 1024
var resolutionY = 600
var fullscreen = false

var settingsMenuInstance = null
var mainMenuInstance = null

func _ready():
	OS.window_resizable = false
	OS.window_fullscreen = true
	loadSettings()
	showMainMenu()
	
func loadSettings():
	var file = File.new()
	if file.open("settings.json", file.READ) == OK:
		print("Opened settings file")
		var data = JSON.parse(file.get_as_text())
		print(data.result)
		playerName = data.result.playerName
		sensitivity = data.result.sensitivity
		resolutionX = data.result.resolutionX
		resolutionY = data.result.resolutionY
		fullscreen = data.result.fullscreen
		file.close()
	else:
		print("Failed to open settings file")
	
func saveSettings():
	#Overwrite settings
	var file = File.new()
	if file.open("settings.json", file.WRITE) == OK:
		print("Opened settings file for writing")
		var settings = {}
		settings.playerName = playerName
		settings.sensitivity = sensitivity
		settings.resolutionX = resolutionX
		settings.resolutionY = resolutionY
		settings.fullscreen = fullscreen
		file.store_string(JSON.print(settings))
		file.close()
	else:
		print("Failed to open settings file for writing")

func showSettingsMenu():
	if settingsMenuInstance == null:
		var settingsScene = preload("res://SettingsMenu.tscn")
		var menu = settingsScene.instance()
		get_node("/root/Game").add_child(menu)
		#settingsMenuInstance = menu
		
func showMainMenu():
	if mainMenuInstance:
		return
	var scene = preload("res://MainMenu.tscn")
	var m = scene.instance()
	mainMenuInstance = m
	get_node("/root/Game").add_child(m)
	
func closeMainMenu():
	if mainMenuInstance:
		mainMenuInstance.queue_free()
		mainMenuInstance = null
	
func closeSettingsMenu():
	if settingsMenuInstance != null:
		settingsMenuInstance.queue_free()
		#settingsMenuInstance = null

func _process(delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	if Input.is_action_just_pressed("screenshot"):
		var data = get_viewport().get_texture().get_data()
		data.flip_y()
		data.save_png("gameScreenshot.png")

func captureMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func releaseMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
