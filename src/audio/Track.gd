class_name Track extends Container

# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------

@export var audio_player: AudioStreamPlayer
@export var time_remaining_label: Label
@export var track_name_label: Label

@export var volume_slider: HSlider
@export var pause_button: Button
@export var loop_button: CheckButton
@export var fade_duration: SpinBox

var _volume_tween: Tween
var _fading_out: bool = false

# -----------------------------------------------------------------------------
# PLAYBACK
# -----------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if audio_player.stream == null:
		return

	var length: float = audio_player.stream.get_length()
	var remaining: int = ceil(max(0.0, length - audio_player.get_playback_position()))
	time_remaining_label.text = "-%s / %s" % [_format_seconds_to_str(remaining), _format_seconds_to_str(ceil(length))]


func load_sound(path: String, initial_volume: float = 1.0, loop: bool = false, fade_in_seconds: float = 0.0, fade_out_seconds: float = 2.0) -> Error:
	var error: Error = _load_audio_stream(path)
	if error != OK:
		return error

	track_name_label.text = path.get_file().get_basename()
	track_name_label.tooltip_text = path

	volume_slider.set_value_no_signal(clampf(initial_volume, 0.0, 1.0) * 100.0)
	loop_button.set_pressed_no_signal(loop)
	fade_duration.value = maxf(0.0, fade_out_seconds)

	_change_volume(0.0)
	audio_player.play()
	_change_volume(volume_slider.ratio, fade_in_seconds)

	return OK


func _change_volume(volume: float, duration: float = 0.0) -> void:
	if _volume_tween != null:
		_volume_tween.kill()
		_volume_tween = null

	if duration <= 0.0:
		audio_player.volume_linear = volume
	else:
		_volume_tween = create_tween()
		_volume_tween.tween_property(audio_player, "volume_linear", volume, duration)


func _format_seconds_to_str(seconds: int) -> String:
	seconds = maxi(0, seconds)
	return "%02d:%02d" % [floori(seconds / 60.0), seconds % 60]


func _load_audio_stream(path: String) -> Error:
	var stream: AudioStream
	match path.get_extension().to_lower():
		"mp3":
			stream = AudioStreamMP3.load_from_file(path)
		"wav":
			stream = AudioStreamWAV.load_from_file(path)
		"ogg":
			stream = AudioStreamOggVorbis.load_from_file(path)
		_:
			push_error("Unsupported audio format: %s" % path)
			return ERR_FILE_UNRECOGNIZED

	if stream == null || stream.get_length() <= 0.0:
		push_error("Cannot decode audio file: %s" % path)
		return ERR_FILE_CORRUPT

	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamMP3:
		stream.loop = false
	elif stream is AudioStreamOggVorbis:
		stream.loop = false

	audio_player.stream = stream
	return OK


func _on_audio_stream_player_finished() -> void:
	if loop_button.button_pressed && !_fading_out:
		audio_player.play()
	else:
		queue_free()


func _on_pause_button_toggled(paused: bool) -> void:
	audio_player.stream_paused = paused
	pause_button.text = "Resume" if paused else "Pause"


func _on_volume_slider_value_changed(value: float) -> void:
	if !_fading_out:
		_change_volume(value / 100.0, 0.15)


func _on_volume_preset_pressed(volume: float) -> void:
	if !_fading_out:
		volume_slider.value = volume


func _on_fade_in_button_pressed() -> void:
	if _fading_out:
		return

	pause_button.button_pressed = false
	_change_volume(0.0)
	_change_volume(volume_slider.ratio, fade_duration.value)


func _on_fade_out_button_pressed() -> void:
	if _fading_out:
		return

	if audio_player.stream_paused || fade_duration.value <= 0.0:
		_on_stop_button_pressed()
		return

	_fading_out = true
	pause_button.disabled = true
	loop_button.disabled = true
	volume_slider.editable = false

	_change_volume(0.0, fade_duration.value)

	_volume_tween.tween_callback(_on_stop_button_pressed)


func _on_stop_button_pressed() -> void:
	audio_player.stop()
	queue_free()
