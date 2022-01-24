"""
		Network singleton

	Handles client/server setup and connecting/disconnecting
"""

extends Node

const lobbyScene = preload("res://Scenes/Lobby.tscn")
const playerScene = preload("res://Scenes/Player.tscn")

var lobbyInstance = null
var gameInstance = null

var networkID = 0 #My network ID
var peers = {} #Data for connected peers


func _ready():
	print("Network entered tree")
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func setInitialSelfData(networkPeer):
	networkID = networkPeer.get_unique_id()
	peers = {}
	var selfPeer = {"id": networkID, "name": Global.settings.playerName, "ready": false}
	peers[networkID] = selfPeer

#Called by a peer sending their peer information to us. Responds with our own data
#Called by self
remotesync func addPeer(name: String, ready: bool):
	var id = get_tree().get_rpc_sender_id()
	print("Adding peer [" + str(id) + "] " + name)
	if not peers.has(id):
		peers[id] = {"id": id, "name": name, "ready": ready}
		if id != networkID:
			var selfPeer = peers[networkID]
			rpc_id(id, "addPeer", selfPeer.name, selfPeer.ready)
	if is_instance_valid(lobbyInstance):
			lobbyInstance.onPeerConnect(peers[id])
		
	
#Remove a peer's data when they disconnect
func removePeer(id):
	print("Removing peer" + str(id))
	if peers.has(id):
		if is_instance_valid(lobbyInstance):
			lobbyInstance.onPeerDisconnect(peers[id])
		removePlayerFromGame(id)
		peers.erase(id)

remotesync func receiveMessage(content: String):
	var id = get_tree().get_rpc_sender_id()
	if id in peers:
		var peer = peers[id]
		Menus.addChatMessage(peer.name, content)

remotesync func receiveSystemMessage(content: String):
	Menus.addSystemMessage(content)

func removePlayerFromGame(id):
	if is_instance_valid(gameInstance):
		var playerNode = gameInstance.get_node("Players/" + str(id))
		if is_instance_valid(playerNode):
			playerNode.delete()

#Peer connected
func _player_connected(id):
	print("Player connected " + str(id))
	var selfPeer = peers[networkID]
	rpc_id(id, "addPeer", selfPeer.name, selfPeer.ready)

#Peer disconnected
func _player_disconnected(id):
	print("Player disconnected " + str(id))
	removePeer(id)
	
#Connected to server
func _connected_ok():
	print("Connected to server")
	var selfPeer = peers[networkID]
	rpc("addPeer", selfPeer.name, selfPeer.ready) #maybe not needed (TODO)
	showLobby()

#Disconnected by server
func _server_disconnected():
	print("Disconnected by server")
	quitLobby()
	Menus.showDialogMessage("Disconnected by server.", "Network")

#Failed to connect to server
func _connected_fail():
	print("Failed to connect to server")
	quitLobby()
	Menus.showDialogMessage("Failed to connect to server.", "Network")

#Start hosting a server
func createServer(port: int):
	disconnectNetwork()
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(port))
	setInitialSelfData(peer)
	get_tree().network_peer = peer
	print("Created server. I am ID " + str(networkID))

#Try to join a server
func createClient(ip: String, port: int):
	disconnectNetwork()
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, port)
	setInitialSelfData(peer)
	get_tree().network_peer = peer
	print("Created client. I am ID " + str(networkID))
	
#Close connections and reset variables
func disconnectNetwork():
	print("Closing network connection")
	var peer = get_tree().network_peer
	if is_instance_valid(peer):
		print("Closed network connection")
		peer.close_connection()
	peers = {}
	networkID = 0
	
#Start a new lobby as the server
func hostLobby(port: int):
	print("Hosting lobby")
	quitLobby()
	Menus.clearChat()
	Menus.chatModeLobby()
	
	lobbyInstance = lobbyScene.instance()
	get_node("/root/Game").add_child(lobbyInstance)

	Menus.showChat()
	Menus.addSystemMessage("Type /help for a list of commands")
	
	createServer(port)
	showLobby()
	
	#Probably not needed
	var selfPeer = peers[networkID]
	rpc("addPeer", selfPeer.name, selfPeer.ready)

#Join lobby as client
func joinLobby(ip: String, port: int):
	print("Joining lobby")
	quitLobby()
	Menus.clearChat()
	Menus.chatModeLobby()
	
	Menus.addSystemMessage("Type /help for a list of commands")
	
	lobbyInstance = lobbyScene.instance()
	get_node("/root/Game").add_child(lobbyInstance)
	hideLobby()
	
	createClient(ip, port)

func quitLobby():
	stopGame()
	if is_instance_valid(lobbyInstance):
		lobbyInstance.requestClose()

#Start a game with the current peers
remotesync func startGame():
	Menus.chatModeNormal()
	Menus.deactivateChat()
	
	stopGame()
	hideLobby()
	
	#Make level
	var levelScene = preload("res://Maps/Temple/TempleMap.tscn")
	gameInstance = levelScene.instance()
	gameInstance.name = "Level"
	get_node("/root/Game").add_child(gameInstance)
	
	#Make players
	var players = Node.new()
	players.set_name("Players")
	gameInstance.add_child(players)
	
	for id in peers:
		var player = playerScene.instance()
		print("Making player with ID " + str(id))
		player.global_transform.origin = Vector3(0, 2, 0) + Vector3(0, 3.5 * ((id - 1) % 2), 0)
		player.set_name(str(id))
		player.set_network_master(id)
		players.add_child(player)
		
	Menus.showChat()
	Global.captureMouse()
	Global.allowControl = true
	Menus.releaseMenuFocus()
	

#End the current game
remotesync func stopGame():
	if is_instance_valid(gameInstance):
		gameInstance.queue_free()
		gameInstance = null
		Global.releaseMouse()

func showLobby():
	if is_instance_valid(lobbyInstance):
		Menus.hideMainMenu()
		Menus.chatModeLobby()
		Menus.showChat()
		Menus.activateChat()
		lobbyInstance.show()
		
func hideLobby():
	if is_instance_valid(lobbyInstance):
		Menus.hideChat()
		lobbyInstance.hide()
