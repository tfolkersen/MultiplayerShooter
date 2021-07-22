extends Node

var settingsShown = false

var playerName = "Unnamed"
var sensitivity = 0.5
var resolutionX = 1024
var resolutionY = 600
var fullscreen = false

var settingsMenuInstance = null

func _ready():
	loadSettings()
	
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
	
func closeSettingsMenu():
	if settingsMenuInstance != null:
		settingsMenuInstance.queue_free()
		#settingsMenuInstance = null

func _process(delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
