"""
		Main menu
"""

extends Control


#Scales for translations of UI elements
var xScale = 1.0
var yScale = 1.0

#_draw() needs to pass these to setLayout()
var _size = Vector2(1024, 600)
var _position = Vector2(0, 0)

var previewWorld = null

########################################################################################
func show():
	updateContext()
	visible = true
	
	
func hide():
	visible = false
	
func isVisible():
	return visible
	
func requestClose():
	queue_free()
	return true
	
func updateContext():
	_updateButtonVisibility()
	
func setLayout(size, position = Vector2(0, 0)):
	_size = size
	_position = position
	
	xScale = size.x / 1024.0
	yScale = size.y / 600.0
	
	var fontScale = min(xScale, yScale)
	theme.get_font("font", "Button").size = 24 * fontScale
	
	$Panel.rect_size = size
	$Title.rect_size = Vector2(300 * fontScale, 66 * fontScale)
	$HostButton.rect_size = Vector2(0, 0)
	$JoinButton.rect_size = Vector2(0, 0)
	$ResumeButton.rect_size = Vector2(0, 0)
	$SettingsButton.rect_size = Vector2(0, 0)
	$IPLabel.rect_size = Vector2(0, 0)
	$IPEdit.rect_size = Vector2(150, 44) * fontScale
	$PortLabel.rect_size = Vector2(0, 0)
	$PortEdit.rect_size = Vector2(150, 44) * fontScale
	$QuitButton.rect_size = Vector2(0, 0)
	$DisconnectButton.rect_size = Vector2(0, 0)
	
	var _buttons = [$HostButton, $JoinButton, $ResumeButton, $SettingsButton, $QuitButton, $DisconnectButton]
	var widths = []
	for b in _buttons:
		widths.append(b.rect_size.x)
	var maxWidth = widths.max()
	for b in _buttons:
		b.rect_size.x = maxWidth
	
	rect_position = position
	
	$Panel.rect_position = Vector2(0, 0)
	
	var pos = Vector2(0, 0)
	pos.x = size.x / 2.0 - $Title.rect_size.x / 2.0
	pos.y = size.y / 10.0
	$Title.rect_position = pos
	
	pos.x = size.x / 20.0
	pos.y = size.y / 10.0 + 90 * yScale
	$HostButton.rect_position = pos
	
	pos.y += 60 * yScale
	$JoinButton.rect_position = pos
	$ResumeButton.rect_position = pos
	
	pos.y += 60 * yScale
	$SettingsButton.rect_position = pos
	
	$IPLabel.rect_position = $HostButton.rect_position + Vector2($HostButton.rect_size.x + 100 * xScale, 0)
	$IPEdit.rect_position = $IPLabel.rect_position + Vector2(0, $IPLabel.rect_size.y + 15 * yScale)
	
	var offset = max($IPLabel.rect_size.x, $IPEdit.rect_size.x) + 90 * xScale
	$PortLabel.rect_position = $IPLabel.rect_position + Vector2(offset, 0) 
	$PortEdit.rect_position = $PortLabel.rect_position + Vector2(0, $PortLabel.rect_size.y + 15 * yScale)
	_updateButtonVisibility()
	
func onResolutionChanged():
	setLayout(get_viewport().size)
	
func enterKeyEvent():
	return false
	
func escapeKeyEvent():
	if isVisible():
		hide()
	else:
		show()
	return true

func _draw():
	setLayout(_size, _position)

########################################################################################

func playHoverSound():
	Global.playSound(preload("res://Audio/mainMenuHover2-2Pitch.mp3"))

func onButtonHover():
	playHoverSound()
	
func playAcceptSound():
	Global.playSound(preload("res://Audio/mainMenuAccept3-2.mp3"))

func _ready():
	get_viewport().connect("size_changed", self, "onResolutionChanged")
	setLayout(get_viewport().size)
	for c in get_children():
		if c is Button:
			c.connect("mouse_entered", self, "onButtonHover")
	
	setPreviewWorld()
	

func setPreviewWorld():
	#Initialize world preview
	var worlds = [preload("res://Maps/Temple/TempleMap.tscn")]
	var previewWorld = worlds[randi() % worlds.size()].instance()
	add_child(previewWorld)
	var cameras = previewWorld.get_node("MenuViews").get_children()
	var camera = cameras[randi() % cameras.size()]
	camera.current = true
	

func _updateButtonVisibility():
	var pos = $SettingsButton.rect_position
	pos.y += 60 * yScale
	
	if Global.isGameVisible() or Global.isLobbyVisible():
		$HostButton.visible = false
		$JoinButton.visible = false
		$ResumeButton.visible = true
		$IPLabel.visible = false
		$IPEdit.visible = false
		$PortLabel.visible = false
		$PortEdit.visible = false
		$DisconnectButton.visible = true
		$DisconnectButton.rect_position = pos
		pos.y += 60 * yScale
		$QuitButton.rect_position = pos
	else:
		$HostButton.visible = true
		$JoinButton.visible = true
		$ResumeButton.visible = false
		$IPLabel.visible = true
		$IPEdit.visible = true
		$PortLabel.visible = true
		$PortEdit.visible = true
		$DisconnectButton.visible = false
		$QuitButton.rect_position = pos
		pos.y += 60 * yScale
		$DisconnectButton.rect_position = pos
		
#Host game button pressed
func onHostButtonPressed():
	playAcceptSound()
	var ip = $IPEdit.text
	var port = int($PortEdit.text)
	Global.settings.defaultIP = ip
	Global.settings.defaultPort = port
	Global.saveSettings()
	Network.hostLobby(port)

#Join button pressed
func onJoinButtonPressed():
	playAcceptSound()
	var ip = $IPEdit.text
	var port = int($PortEdit.text)
	Global.settings.defaultIP = ip
	Global.settings.defaultPort = port
	Global.saveSettings()
	Network.joinLobby(ip, port)

func onResumeButtonPressed():
	playAcceptSound()
	hide()

#Settings button pressed
func onSettingsButtonPressed():
	playAcceptSound()
	Menus.showSettingsMenu()

#Quit button pressed
func onQuitButtonPressed():
	playAcceptSound()
	var message = "Close game?"
	var title = "Quitting"
	if Network.networkID == 1:
		message = "Close game? This will disconnect all players from the server."
	var dialog = Global.showConfirmationDialog(message, title)
	dialog.connect("accept", self, "_quitConfirmed")	
	
func _quitConfirmed():
	Network.stopGame()
	Network.leaveLobby()
	queue_free()
	get_tree().quit()

func onDisconnectButtonPressed():
	playAcceptSound()
	var message = "Disconnect from session?"
	var title = "Disconnect"
	if Network.networkID == 1:
		message = "Disconnect from session? This will disconnect all players from the server."
	var dialog = Global.showConfirmationDialog(message, title)
	dialog.connect("accept", self, "_disconnectConfirmed")

func _disconnectConfirmed():
	Network.stopGame()
	Network.leaveLobby()
