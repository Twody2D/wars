extends Node
## Sound (SPEC 12): SFX from a fixed pool of players (nothing is created in
## battle), one looping music track. Mute is the Master bus — see
## Platform.update_mute(). Sounds: CC0 packs via tools/import_sounds.py
## (docs/AUDIO_CREDITS.md).

## Several files = variants, one is picked at random each time.
const SFX: Dictionary[StringName, Array] = {
	&"hit": [
		preload("res://audio/sfx/hit_1.ogg"),
		preload("res://audio/sfx/hit_2.ogg"),
		preload("res://audio/sfx/hit_3.ogg"),
		preload("res://audio/sfx/hit_4.ogg"),
		preload("res://audio/sfx/hit_5.ogg"),
	],
	&"shoot": [
		preload("res://audio/sfx/shoot_1.ogg"),
		preload("res://audio/sfx/shoot_2.ogg"),
		preload("res://audio/sfx/shoot_3.ogg"),
	],
	&"explosion": [preload("res://audio/sfx/explosion.ogg")],
	&"death": [
		preload("res://audio/sfx/death_1.ogg"),
		preload("res://audio/sfx/death_2.ogg"),
		preload("res://audio/sfx/death_3.ogg"),
		preload("res://audio/sfx/death_4.ogg"),
		preload("res://audio/sfx/death_5.ogg"),
	],
	&"spawn": [preload("res://audio/sfx/spawn_1.ogg"), preload("res://audio/sfx/spawn_2.ogg")],
	&"coin": [preload("res://audio/sfx/coin_1.ogg"), preload("res://audio/sfx/coin_2.ogg")],
	&"ore": [
		preload("res://audio/sfx/ore_1.ogg"),
		preload("res://audio/sfx/ore_2.ogg"),
		preload("res://audio/sfx/ore_3.ogg"),
	],
	&"meteor": [preload("res://audio/sfx/meteor.ogg")],
	&"win": [preload("res://audio/sfx/win.ogg")],
	&"lose": [preload("res://audio/sfx/lose.ogg")],
	&"click": [preload("res://audio/sfx/click.ogg")],
	&"wave": [preload("res://audio/sfx/wave.ogg")],
	&"base_hit": [
		preload("res://audio/sfx/base_hit_1.ogg"),
		preload("res://audio/sfx/base_hit_2.ogg"),
		preload("res://audio/sfx/base_hit_3.ogg"),
	],
}
const MUSIC: Dictionary[StringName, AudioStream] = {
	&"menu": preload("res://audio/music/menu.ogg"),
	&"battle": preload("res://audio/music/battle.ogg"),
}
## Simultaneous SFX; the oldest one is cut when all are busy.
const POOL_SIZE := 12
## The same SFX again within this time is skipped (a crowd hitting at once).
const REPEAT_GAP_SEC := 0.06
## Random pitch spread so repeated hits don't sound identical.
const PITCH_JITTER := 0.08

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last_played: Dictionary[StringName, int] = {}
var _music: AudioStreamPlayer
var _music_id: StringName = &""


func _ready() -> void:
	# UI clicks and music keep working on the pause screen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.finished.connect(_music.play)
	add_child(_music)
	get_tree().node_added.connect(_on_node_added)


func play_sfx(id: StringName, jitter: bool = true) -> void:
	var variants: Array = SFX.get(id, [])
	if variants.is_empty():
		push_warning("Audio: unknown sfx %s" % id)
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_played.get(id, -100000) < int(REPEAT_GAP_SEC * 1000.0):
		return
	_last_played[id] = now
	var p: AudioStreamPlayer = _free_player()
	p.stream = variants.pick_random()
	p.pitch_scale = 1.0 + (randf_range(-PITCH_JITTER, PITCH_JITTER) if jitter else 0.0)
	p.play()


func play_music(id: StringName) -> void:
	if id == _music_id and _music.playing:
		return
	var stream: AudioStream = MUSIC.get(id)
	if stream == null:
		push_warning("Audio: unknown music %s" % id)
		return
	_music_id = id
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music_id = &""
	_music.stop()


## Every button in the game clicks (one place instead of each scene).
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var button: BaseButton = node
		if not button.pressed.is_connected(_on_button_pressed):
			button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	play_sfx(&"click", false)


func _free_player() -> AudioStreamPlayer:
	for i: int in POOL_SIZE:
		var p: AudioStreamPlayer = _players[(_next + i) % POOL_SIZE]
		if not p.playing:
			_next = (_next + i + 1) % POOL_SIZE
			return p
	var oldest: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % POOL_SIZE
	return oldest
