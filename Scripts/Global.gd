"""
		Global singleton
		
	Execution entry point of the game.
	Initializes things and provides various utility functions to be used by nodes.
"""

extends Node

#Various scene files
const mainMenuScene = preload("res://Scenes/MainMenu.tscn")
const settingsMenuScene = preload("res://Scenes/SettingsMenu.tscn")
const dialogMessageScene = preload("res://Scenes/DialogMessage.tscn")

#Various constants
const settingsFileName = "settings.json"

#Instances of menus
var mainMenuInstance = null
var settingsMenuInstance = null

#Data
var settings = {}

#Entry point of the game
func _ready():
	OS.window_resizable = false
	loadDefaultSettings()
	loadSettings()
	applySettings()
	showMainMenu()

func _process(delta):	
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	if Input.is_action_just_pressed("screenshot"):
		var data = get_viewport().get_texture().get_data()
		data.flip_y()
		data.save_png("gameScreenshot.png")

func applySettings():
	OS.window_fullscreen = settings.fullscreen
	OS.window_size = Vector2(settings.resolutionX, settings.resolutionY)

#Initialize settings with their default values
func loadDefaultSettings():
	settings.playerName = "Unnamed"
	settings.sensitivity = 0.5
	settings.resolutionX = 1024
	settings.resolutionY = 600
	settings.fullscreen = false

#Loads settings file if one exists
func loadSettings():
	var file = File.new()
	if file.open(settingsFileName, file.READ) == OK:
		print("Opened settings file")
		var data = JSON.parse(file.get_as_text())
		print(data.result)
		settings.playerName = data.result.playerName
		settings.sensitivity = data.result.sensitivity
		settings.resolutionX = data.result.resolutionX
		settings.resolutionY = data.result.resolutionY
		settings.fullscreen = data.result.fullscreen
		file.close()
	else:
		print("Failed to open settings file")

#Writes a new settings file to disk, overwriting old one
func saveSettings():
	var file = File.new()
	if file.open(settingsFileName, file.WRITE) == OK:
		print("Opened settings file for writing")
		file.store_string(JSON.print(settings))
		file.close()
	else:
		print("Failed to open settings file for writing")

#Show main menu if it's not already shown
func showMainMenu():
	if not is_instance_valid(mainMenuInstance):
		mainMenuInstance = mainMenuScene.instance()
		get_node("/root/Game").add_child(mainMenuInstance)

#Close main menu if it's open
func closeMainMenu():
	if is_instance_valid(mainMenuInstance):
		mainMenuInstance.closeSelf()

#Show the settings menu if it's not shown
func showSettingsMenu():
	if not is_instance_valid(settingsMenuInstance):
		settingsMenuInstance = settingsMenuScene.instance()
		get_node("/root/Game").add_child(settingsMenuInstance)

#Close settings menu if it's open
func closeSettingsMenu():
	if is_instance_valid(settingsMenuInstance):
		settingsMenuInstance.closeSelf()

#Show a dialog message (i.e. if disconnected from server)
func showDialogMessage(message, title = null):
	var dialog = dialogMessageScene.instance()
	dialog.setMessage(message)
	if title != null:
		dialog.setTitle(title)
	get_node("/root/Game").add_child(dialog)

#Capture the cursor
func captureMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#Allow the cursor to move again
func releaseMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
