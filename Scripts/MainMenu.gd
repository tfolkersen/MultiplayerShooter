"""
		Main menu
"""

extends Control

func _ready():
	updateLayout()
	updateButtonVisibility()

#Close the menu
func closeSelf():
	queue_free()

func hide():
	visible = false
	if Global.isLobbyVisible():
		Network.lobbyInstance.grabFocus()

func show():
	visible = true
	updateButtonVisibility()
	
func isVisible():
	return visible

func updateButtonVisibility():
	var pos = $SettingsButton.rect_position
	pos.y += 40
	
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
		pos.y += 40
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
		pos.y += 40
		$DisconnectButton.rect_position = pos
		

#Set the layout based on the screen size
func updateLayout():
	var dims = get_viewport().size
	var pos = Vector2(0, 0)
	
	$Panel.rect_position = Vector2(0, 0)
	$Panel.rect_size = dims
	
	pos.x = dims.x / 2 - $Title.rect_size.x / 2
	pos.y = dims.y / 10
	$Title.rect_position = pos
	
	pos.x = dims.x / 20
	pos.y = dims.y / 10 + 60
	$HostButton.rect_position = pos
	
	pos.y += 40
	$JoinButton.rect_position = pos
	$ResumeButton.rect_position = pos
	
	pos.y += 40
	$SettingsButton.rect_position = pos
	
	#pos.y += 40
	#$QuitButton.rect_position = pos
	#$DisconnectButton.rect_position = pos
	
	$IPLabel.rect_position = $HostButton.rect_position + Vector2($HostButton.rect_size.x + 100, 0)
	$IPEdit.rect_position = $IPLabel.rect_position + Vector2(0, $IPLabel.rect_size.y + 10)
	
	var offset = max($IPLabel.rect_size.x, $IPEdit.rect_size.x)
	$PortLabel.rect_position = $IPLabel.rect_position + Vector2(offset, 0) 
	$PortEdit.rect_position = $PortLabel.rect_position + Vector2(0, $PortLabel.rect_size.y + 10)

#Host game button pressed
func _hostButtonPressed():
	var ip = $IPEdit.text
	var port = int($PortEdit.text)
	Global.settings.defaultIP = ip
	Global.settings.defaultPort = port
	Global.saveSettings()
	Network.hostLobby(port)

#Join button pressed
func _joinButtonPressed():
	var ip = $IPEdit.text
	var port = int($PortEdit.text)
	Global.settings.defaultIP = ip
	Global.settings.defaultPort = port
	Global.saveSettings()
	Network.joinLobby(ip, port)

#Settings button pressed
func _settingsButtonPressed():
	Global.showSettingsMenu()

func _quitConfirmed():
	Network.stopGame()
	Network.leaveLobby()
	Global.closeMainMenu()
	get_tree().quit()

func _disconnectConfirmed():
	Network.stopGame()
	Network.leaveLobby()

#Quit button pressed
func _quitButtonPressed():
	var message = "Close game?"
	var title = "Quitting"
	if Network.networkID == 1:
		message = "Close game? This will disconnect all players from the server."
	var dialog = Global.showConfirmationDialog(message, title)
	dialog.connect("accept", self, "_quitConfirmed")	
	
func _disconnectButtonPressed():
	var message = "Disconnect from session?"
	var title = "Disconnect"
	if Network.networkID == 1:
		message = "Disconnect from session? This will disconnect all players from the server."
	var dialog = Global.showConfirmationDialog(message, title)
	dialog.connect("accept", self, "_disconnectConfirmed")

func _resumeButtonPressed():
	Global.hideMainMenu()
