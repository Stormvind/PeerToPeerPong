extends Node

var peer_address : String;
var input_delay : int;
var network_port : int = 31415;
var server : UDPServer;
var connection : PacketPeerUDP;
var is_host : bool;
var game_over_text : String;
