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

#Called by a peer sending their peer information to us. Responds with our own data
#Called by self
remotesync func addPeer(name: String, ready: bool):
	var id = get_tree().get_rpc_sender_id()
	print("Adding peer [" + str(id) + "] " + name)
	if not peers.has(id):
		peers[id] = {"id": id, "name": name, "ready": ready}
		if id != networkID:
			rpc_id(id, "addPeer", peers[networkID].name, peers[networkID].ready)
	if is_instance_valid(lobbyInstance):
		lobbyInstance.peerConnected(id)
	
#Remove a peer's data when they disconnect
func removePeer(id):
	print("Removing peer" + str(id))
	if peers.has(id):
		var peer = peers[id]
		if is_instance_valid(lobbyInstance):
			lobbyInstance.peerDisconnected(id)
		removePlayerFromGame(id)
		peers.erase(id)

func removePlayerFromGame(id):
	if is_instance_valid(gameInstance):
		var playerNode = gameInstance.get_node("Players/" + str(id))
		if is_instance_valid(playerNode):
			playerNode.queue_free()

#Peer connected
func _player_connected(id):
	print("Player connected " + str(id))
	var selfPeer = peers[Network.networkID]
	rpc_id(id, "addPeer", selfPeer.name, selfPeer.ready)

#Peer disconnected
func _player_disconnected(id):
	print("Player disconnected " + str(id))
	removePeer(id)
	
#Connected to server
func _connected_ok():
	print("Connected to server")
	var selfPeer = peers[Network.networkID]
	rpc("addPeer", selfPeer.name, selfPeer.ready)
	lobbyInstance.visible = true
	Global.hideMainMenu()

#Disconnected by server
func _server_disconnected():
	print("Disconnected by server")
	stopGame()
	if is_instance_valid(lobbyInstance):
		lobbyInstance.quitLobby()
	Global.showMainMenu()
	Global.showDialogMessage("Disconnected by server.", "Network")

#Failed to connect to server
func _connected_fail():
	print("Failed to connect to server")
	if is_instance_valid(lobbyInstance):
		lobbyInstance.quitLobby()

#Start hosting a server
func createServer(port: int):
	disconnectNetwork()
	peers = {}
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(port))
	get_tree().network_peer = peer
	networkID = peer.get_unique_id()
	peers[networkID] = {"name": Global.settings.playerName, "ready": false}
	print("Created server. I am ID " + str(networkID))

#Try to join a server
func createClient(ip: String, port: int):
	disconnectNetwork()
	peers = {}
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, port)
	get_tree().network_peer = peer
	networkID = peer.get_unique_id()
	peers[networkID] = {"name": Global.settings.playerName, "ready": false}
	print("Created client. I am ID " + str(networkID))
	
#Close connections and reset variables
func disconnectNetwork():
	print("Closing network connection")
	var peer = get_tree().network_peer
	if is_instance_valid(peer):
		print("Closed network connection")
		peer.close_connection()
		peer = null
	peers = {}
	networkID = 0
	

#Start a new lobby as the server
func hostLobby(port: int):
	print("Hosting lobby")
	if is_instance_valid(lobbyInstance):
		lobbyInstance.quitLobby()
		lobbyInstance = null
	lobbyInstance = lobbyScene.instance()
	get_node("/root/Game").add_child(lobbyInstance)
	lobbyInstance.systemMessage("Type /help for a list of commands")
	
	createServer(port)
	lobbyInstance.updateLayout()
	var selfPeer = peers[Network.networkID]
	rpc("addPeer", selfPeer.name, selfPeer.ready)
	Global.hideMainMenu()

#Join lobby as client
func joinLobby(ip: String, port:int):
	print("Joining lobby")
	if is_instance_valid(lobbyInstance):
		lobbyInstance.quitLobby()
		lobbyInstance = null
	
	lobbyInstance = lobbyScene.instance()
	lobbyInstance.visible = false
	get_node("/root/Game").add_child(lobbyInstance)
	lobbyInstance.systemMessage("Type /help for a list of commands")

	createClient(ip, port)
	lobbyInstance.updateLayout()

#Leave the lobby if it exists
func leaveLobby():
	if is_instance_valid(lobbyInstance):
		lobbyInstance.quitLobby()
		
#Start a game with the current peers
remotesync func startGame():
	if is_instance_valid(gameInstance):
		stopGame()
	lobbyInstance.visible = false
	
	#Make level
	var levelScene = preload("res://Maps/TempleMap.tscn")
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
		
	Global.captureMouse()

#End the current game
remotesync func stopGame():
	if is_instance_valid(gameInstance):
		gameInstance.queue_free()
		gameInstance = null
		Global.releaseMouse()

