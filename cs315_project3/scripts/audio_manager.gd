extends Node

var audio_players: Array[AudioStreamPlayer] = []
var max_players: int = 10

var coin_sound = preload("res://coin.wav")
var game_play_sound = preload("res://Gameplay Song.wav")
var jump_sound = preload("res://jump.wav")
var power_up_sound = preload("res://power_up.wav")
var tap_sound = preload("res://tap.wav")
var explosion_sound = preload("res://explosion.wav")
var cockadoodledoo_sound = preload("res://rooster-call-cock-a-doodle-doo-46096.mp3")

func go_to_sleep_or_plant_crop(): #
	AudioManager.play_sound(tap_sound)
	
func interact():#
	AudioManager.play_sound(coin_sound)

func water_or_harvest():#
	AudioManager.play_sound(jump_sound)

func ocd_event():
	AudioManager.play_sound(explosion_sound)
	
func ocd_success():
	AudioManager.play_sound(power_up_sound)

func new_day():
	AudioManager.play_sound(cockadoodledoo_sound)

func _ready():
	# Pre-create audio players
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		player.finished.connect(_on_player_finished.bind(player))
		audio_players.append(player)

# THIS IS THE MAIN FUNCTION - plays any sound you give it
func play_sound(sound: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0):
	for player in audio_players:
		if not player.playing:
			player.stream = sound
			player.volume_db = volume_db
			player.pitch_scale = pitch_scale
			player.play()
			return player
	
	# All players busy
	print("Warning: All audio players busy!")
	audio_players[0].stream = sound
	audio_players[0].play()
	return audio_players[0]

func _on_player_finished(_player: AudioStreamPlayer):
	pass
