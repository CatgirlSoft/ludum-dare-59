class_name MusicManager_class
extends Node

## Manages background music playback with smooth fade transitions.
##
## This singleton (autoload) handles playing music tracks with fade-in and fade-out effects.
## It ensures seamless transitions between tracks and prevents restarting if the same track is already playing.

# Signal
signal music_start(music: MusicTrack)

# Manager setting
const _MUSIC_BUS: String = "Music" 
const _MUSIC_AUDIO_PLAYER_COUNT: int = 2

# Music Parameter
var _is_looping: bool = false
var _fade_time_second: float = 0.0
var _is_shuffling: bool = false
var _is_playlist: bool = false

# AudioPlayer reference
var _current_music_player: int = 0
var _music_players : Array[AudioStreamPlayer] = []

var _current_music: MusicTrack
var _current_playlist: MusicPlaylist
var _playlist_unplayed: Array[MusicTrack] = []

@onready var timer: Timer = $Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	timer.timeout.connect(_play_song)
	music_start.connect(_music_finished_timer)
	
	_create_audio_players()


## Play the given song while stoping any currently playing track.
## If [code]fade_time[/code] is different from [code]0.0[/code] the music will be faded in and out.  
## looping will make the song restart when it end.
## The track will continues playing if it is already active.  
func play_music(music: MusicTrack, is_looping: bool = true, fade_time: float = 1.5) -> void:
	_current_music = music
	_current_playlist = null
	_playlist_unplayed = []
	
	_is_playlist = false
	_is_looping = is_looping
	_fade_time_second = fade_time
	
	_switch_player()


## Play the given playlist while stoping any currently playing track.
## If fade_time is different from [code]0.0[/code] the musics will be faded in and out.  
## Looping will make the playlist restart when all music in it have been played.
## Shuffling will mix the order of the music in the playlist.
## (If the track is also looping a music can't be replayed until every other track in the playlist as been played)
## The playlist will continues playing if it is already active.  
func play_playlist(playlist: MusicPlaylist, is_looping: bool = true, is_shuffling: bool = false, fade_time: float = 1.5) -> void:
	_is_playlist = true
	_is_looping = is_looping
	_is_shuffling = is_shuffling
	_fade_time_second = fade_time
	
	if _current_playlist != playlist:
		_current_playlist = playlist
		_playlist_unplayed = playlist.tracks
		_play_song()


## Pause the music playing, and fade it out if fade_time is superior to [code]0.0[/code] .
func pause(fade_time: float = 0.0) -> void:
	var tween = create_tween()
	tween.tween_property(_music_players[_current_music_player], "volume_db", -40, fade_time)
	await tween.finished
	_music_players[_current_music_player].stream_paused = true


## Resume the music previously playing, and fade it in if fade_time is superior to [code]0.0[/code] .
func resume(fade_time: float = 0.0) -> void:
	_music_players[_current_music_player].stream_paused = false
	var tween = create_tween()
	tween.tween_property(_music_players[_current_music_player], "volume_db", 0, fade_time)
	await tween.finished


## Stop the music playing, and fade it out if fade_time is superior to [code]0.0[/code] .
func stop(fade_time: float = 0.0) -> void:
	var tween = create_tween()
	tween.tween_property(_music_players[_current_music_player], "volume_db", -40, fade_time)
	await tween.finished
	_music_players[_current_music_player].stop()
	for player in _music_players:
		player.stream = null


func _play_song() -> void:
	if _is_playlist:
		# Looping
		if _playlist_unplayed.size() == 0:
			if _is_looping:
				_playlist_unplayed = _current_playlist.tracks
			else:
				var old_music_player: AudioStreamPlayer = _music_players[_current_music_player]
				_fade_out_and_stop(old_music_player)
				return
		
		# Pick a song
		if _is_shuffling:
			_current_music = _playlist_unplayed.pop_at(randi_range(0,_playlist_unplayed.size() - 1))
		else:
			_current_music = _playlist_unplayed.pop_front()
		
		# Play the song
		_switch_player()
	else:
		if not _is_looping:
			stop(_fade_time_second)

# Creates AudioStreamPlayers, adds them to the scene tree, and stores them.
func _create_audio_players() -> void:
	for count in range(_MUSIC_AUDIO_PLAYER_COUNT):
		var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(audio_player)
		_music_players.append(audio_player)
		
		audio_player.name = "audio_player_1"
		audio_player.finished.connect(_play_song)
		audio_player.bus = _MUSIC_BUS
		audio_player.volume_db = -40


# Starts playing the given AudioStreamPlayer and fades it in.
func _start_and_fade_in(audio_player: AudioStreamPlayer) -> void:
	audio_player.play()
	
	var tween = create_tween()
	tween.tween_property( audio_player, "volume_db", 0, _fade_time_second).set_trans(Tween.TRANS_CUBIC)


# Fades out the given AudioStreamPlayer and stops it.
func _fade_out_and_stop(audio_player: AudioStreamPlayer) -> void:
	var tween = create_tween()
	tween.tween_property( audio_player, "volume_db", -40, _fade_time_second).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	audio_player.stop()


func _switch_player() -> void:
	if _current_music.track == _music_players[_current_music_player].stream:
		return
		
	music_start.emit(_current_music)
	
	var old_music_player: AudioStreamPlayer = _music_players[_current_music_player]
	_fade_out_and_stop(old_music_player)
	
	_current_music_player = wrap(_current_music_player + 1, 0, _MUSIC_AUDIO_PLAYER_COUNT)
	var new_music_player: AudioStreamPlayer = _music_players[_current_music_player]
	new_music_player.stream = _current_music.track
	_start_and_fade_in( new_music_player)


func _music_finished_timer(music: MusicTrack) -> void:
	timer.start(music.track.get_length() - _fade_time_second - 0.01)
