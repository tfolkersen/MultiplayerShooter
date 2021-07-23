extends Node

var lobbyInstance = null
var gameInstance = null

var networkID = 0
var peers = {}

remotesync func addPeer(name):
	var id = get_tree().get_rpc_sender_id()
	print("Adding peer [" + str(id) + "]" + name)
	if peers.has(id):
		return
	peers[id] = {"id": id, "name": name}
	if id != networkID:
		rpc_id(id, "addPeer", Global.playerName)
	lobbyInstance.addUserToList(name, id)
	if lobbyInstance.is_network_master():
		lobbyInstance.rpc("systemMessage", name + " has joined")

func removePeer(id):
	print("Removing peer" + str(id))
	if peers.has(id):
		var peer = peers[id]
		if is_instance_valid(lobbyInstance):
			lobbyInstance.systemMessage(peer.name + " has left")
			lobbyInstance.removeUserFromList(id)
			
		if is_instance_valid(gameInstance):
			var playerNode = gameInstance.get_node("players/" + str(id))
			playerNode.queue_free()

func _ready():
	print("Network ready")
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.
	print("Player connected " + str(id))
	rpc_id(id, "addPeer", Global.playerName)

func _player_disconnected(id):
	print("Player disconnected " + str(id))
	removePeer(id)
	
func _connected_ok():
	print("Connected to server")
	rpc("addPeer", Global.playerName)
	lobbyInstance.visible = true
	Global.closeMainMenu()

func _server_disconnected():
	print("Disconnected by server")
	if is_instance_valid(lobbyInstance):
		stopGame()
		lobbyInstance.quitLobby()
		lobbyInstance = null
	Network.disconnectNetwork()

func _connected_fail():
	print("Failed to connect to server")
	pass # Could not even connect to server; abort.

func createServer(port):
	peers = {}
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(port))
	get_tree().network_peer = peer
	networkID = peer.get_unique_id()

	print("Created server. I am ID " + str(networkID))
	
func createClient(ip, port):
	peers = {}
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, int(port))
	get_tree().network_peer = peer
	networkID = peer.get_unique_id()
	print("Created client. I am ID " + str(networkID))
	
func disconnectNetwork():
	var peer = get_tree().network_peer
	if is_instance_valid(peer):
		peer.close_connection()
		peer = null
		networkID = 0
		print("Closed network connection")
		peers = {}

func hostLobby(port):
	print("Hosting lobby")
	if is_instance_valid(lobbyInstance):
		lobbyInstance.quitLobby()
		lobbyInstance = null
	var lobbyScene = preload("res://Lobby.tscn")
	lobbyInstance = lobbyScene.instance()
	get_node("/root/Game").add_child(lobbyInstance)
	
	createServer(port)
	rpc("addPeer", Global.playerName)
	
	Global.closeMainMenu()

var playerScene = preload("res://Player.tscn")

remotesync func startGame():
	if is_instance_valid(gameInstance):
		stopGame()
		
	#Make level
	lobbyInstance.visible = false
	var levelScene = preload("res://TestMap.tscn")
	gameInstance = levelScene.instance()
	gameInstance.name = "Level"
	get_node("/root/Game").add_child(gameInstance)
	
	#Make players
	var players = Node.new()
	players.set_name("players")
	gameInstance.add_child(players)
	
	for id in peers:
		var player = playerScene.instance()
		print("Making player with ID " + str(id))
		player.set_name(str(id))
		player.set_network_master(id)
		players.add_child(player)
		#gameInstance.add_child(player)
		
	Global.captureMouse()

remotesync func stopGame():
	if is_instance_valid(gameInstance):
		gameInstance.queue_free()
		gameInstance = null
		Global.releaseMouse()

func joinLobby(ip, port):
	print("Joining lobby")
	if is_instance_valid(lobbyInstance):
		lobbyInstance.quitLobby()
		lobbyInstance = null
	
	var lobbyScene = preload("res://Lobby.tscn")
	lobbyInstance = lobbyScene.instance()
	lobbyInstance.visible = false
	get_node("/root/Game").add_child(lobbyInstance)
	
	#Global.closeMainMenu()
	
	createClient(ip, port)
	#addPeer(Global.playerName)
