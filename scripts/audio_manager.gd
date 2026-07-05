extends Node

const POOL_SIZE := 8

const SFX := {
	"attack": preload("res://assets/audio/sfx_attack.wav"),
	"hit": preload("res://assets/audio/sfx_hit.wav"),
	"enemy_death": preload("res://assets/audio/sfx_enemy_death.wav"),
	"pickup": preload("res://assets/audio/sfx_pickup.wav"),
	"level_up": preload("res://assets/audio/sfx_level_up.wav"),
	"player_death": preload("res://assets/audio/sfx_player_death.wav"),
	"victory": preload("res://assets/audio/sfx_victory.wav"),
	"ui_click": preload("res://assets/audio/sfx_ui_click.wav"),
	"gate": preload("res://assets/audio/sfx_gate.wav"),
}

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)


func play(sfx_name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = SFX.get(sfx_name)
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# every player is busy: steal the next one in round-robin order
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.play()
