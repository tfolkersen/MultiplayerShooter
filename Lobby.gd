extends Control

var messageScene = preload("res://LobbyMessage.tscn")

onready var xd = randi()

remotesync func setReady():
	var id = get_tree().get_rpc_sender_id()
	var node = get_node("PlayerList/VBoxContainer/" + str(id))
	node.setText("ready")
	node.setSenderColor(Color(0.0, 1.0, 0.0))
	
remotesync func setNotReady():
	var id = get_tree().get_rpc_sender_id()
	var node = get_node("PlayerList/VBoxContainer/" + str(id))
	node.setText("not ready")
	node.setSenderColor(Color(1.0, 0.0, 0.0))

func addUserToList(name, id):
	var message = messageScene.instance()
	message.setContent(name, "not ready")
	message.setSenderColor(Color(1.0, 0.0, 0.0))
	message.name = str(id)
	$PlayerList/VBoxContainer.add_child(message)

func removeUserFromList(id):
	var node = get_node("PlayerList/VBoxContainer/" + str(id))
	if node:
		node.queue_free()

func testChat():
	var users = ["memer", "xxQuickscopes420xx", "asdasdasdasd"]
	var words = ["nice", "meme", "haha", "xd"]
	
	randomize()
	for i in range(50):
		var u = users[randi() % len(users)]
		var m = ""
		for w in range(randi() % 10 + 1):
			m += words[randi() % len(words)] + " "
		
		addMessage(u, m)

func testUserList():
	var users = ["memer", "xxQuickscopes420xx", "asdasdasdasd"]
	var words = ["nice", "meme", "haha", "xd"]
	
	randomize()
	for i in range(10):
		var u = users[randi() % len(users)]
		addUserToList(u, i)

func _ready():
	print("Joined tree")
	#testChat()
	#testUserList()
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

func addMessage(sender, text, senderColor = Color(1.0, 1.0, 0.0)):
	var message = messageScene.instance()
	message.setContent(sender, text)
	message.setSenderColor(senderColor)
	$ChatWindow/VBoxContainer.add_child(message)
	
remotesync func receiveMessage(message):
	var id = get_tree().get_rpc_sender_id()
	if not Network.peers.has(id):
		return
	var peer = Network.peers[id]
	addMessage(peer.name, message)
	
remotesync func systemMessage(message):
	addMessage("[SYSTEM]", message, Color(0.5, 0.0, 1.0))

func quitLobby():
	Network.disconnectNetwork()
	queue_free()
	Global.showMainMenu()

func _messageEntered(text):
	$MessageEdit.clear()
	if text == "":
		return
	if text in ["/disconnect", "/quit"]:
		quitLobby()
		return
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

	rpc("receiveMessage", text)
	if not is_network_master():
		receiveMessage(text)

func _process(delta):
	pass

func _exitingTree():
	print("Lobby exiting tree")
