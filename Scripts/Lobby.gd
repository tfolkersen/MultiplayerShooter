"""
		Multiplayer game lobby with chat
"""

extends Control

const messageScene = preload("res://Scenes/LobbyMessage.tscn")

func _ready():
	print("Lobby Joined tree")
	$MessageEdit.grab_focus()
	$MessageEdit.text = "/start"
	updateLayout()

func releaseFocus():
	$MessageEdit.release_focus()

#Player disconnected
func peerConnected(id):
	addUserToList(id)
	if is_network_master():
		var peer = Network.peers[id]
		rpc("systemMessage", peer.name + " has joined")

#Player disconnected
func peerDisconnected(id):
	removeUserFromList(id)
	if is_network_master():
		var peer = Network.peers[id]
		rpc("systemMessage", peer.name + " has left")

#Adjust sizes and positions of everything to match current dimensions
func updateLayout():
	var dims = get_viewport().size
	rect_size = dims
	
	var prev = null
	var curr = null
	
	curr = $ChatWindow
	curr.rect_size = Vector2(dims.x * 0.65, dims.y * 0.9)
	curr.rect_position = Vector2(dims.x - curr.rect_size.x, 0)
	
	prev = curr
	curr = $MessageEdit
	curr.rect_size = Vector2(prev.rect_size.x, dims.y - prev.rect_size.y)
	curr.rect_position = Vector2(prev.rect_position.x, prev.rect_size.y)
	
	prev = curr
	curr = $PlayerList
	curr.rect_position = Vector2(0, 0)
	curr.rect_size = Vector2(dims.x - $ChatWindow.rect_size.x, dims.y / 2.0)

#Mark player as ready
remotesync func setReady():
	var id = get_tree().get_rpc_sender_id()
	var node = get_node("PlayerList/VBoxContainer/" + str(id))
	node.setText("ready")
	node.setSenderColor(Color(0.0, 1.0, 0.0))

#Mark player as not ready
remotesync func setNotReady():
	var id = get_tree().get_rpc_sender_id()
	var node = get_node("PlayerList/VBoxContainer/" + str(id))
	node.setText("not ready")
	node.setSenderColor(Color(1.0, 0.0, 0.0))

#Add player to player list
func addUserToList(id):
	var peer = Network.peers[id]
	var message = messageScene.instance()
	message.setContent(peer.name, "not ready")
	message.setSenderColor(Color(1.0, 0.0, 0.0))
	message.name = str(id)
	$PlayerList/VBoxContainer.add_child(message)

#Remove player from player list
func removeUserFromList(id):
	var node = get_node("PlayerList/VBoxContainer/" + str(id))
	if is_instance_valid(node):
		node.queue_free()

#Add message to chat
func addMessage(sender, text, senderColor = Color(1.0, 1.0, 0.0)):
	var message = messageScene.instance()
	message.setContent(sender, text)
	message.setSenderColor(senderColor)
	$ChatWindow/VBoxContainer.add_child(message)
	
#Receive message from someone
remotesync func receiveMessage(message: String):
	var id = get_tree().get_rpc_sender_id()
	if not Network.peers.has(id):
		return
	var peer = Network.peers[id]
	addMessage(peer.name, message)

#Receive system message (usually from server)
remotesync func systemMessage(message: String):
	addMessage("[SYSTEM]", message, Color(1.0, 0.0, 1.0))

#Close the lobby (doesn't clean up network stuff)
func quitLobby():
	queue_free()
	Network.disconnectNetwork()
	Global.showMainMenu()

#Local user sent a message
func _messageEntered(text):
	$MessageEdit.clear()
	if text == "":
		return
		
	if text == "/help":
		var helpString = "Commands:\n/help -- show this message\n/start or /startgame -- start game if host\n/disconnect or /quit -- leave lobby\n/ready -- mark self as ready\n/unready or /notready -- mark self as not ready\n/host -- show who is host"
		systemMessage(helpString)
		return
	if text in ["/start", "/startgame"]:
		if is_network_master():
			Network.rpc("startGame")	
		else:
			systemMessage("Error: Only the host can start the game")
		return
	if text in ["/disconnect", "/quit"]:
		quitLobby()
	if text == "/ready":
		rpc("setReady")
		if not is_network_master():
			setReady()
		return
	if text in ["/unready", "/notready"]:
		rpc("setNotReady")
		if not is_network_master():
			setNotReady()
		return
	if text == "/host":
		systemMessage("Host is \"" + str(Network.peers[1].name) + "\"")
		return

	rpc("receiveMessage", text)
	if not is_network_master():
		receiveMessage(text)

func _exitingTree():
	print("Lobby exiting tree")

