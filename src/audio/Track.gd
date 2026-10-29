class_name Track
extends Container

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var loop: bool = false

# TODO: Add quick volume options (25%, 50%, 75%, 100%)

func _process(_delta: float):
	if audio_player.stream != null:
		var time_remaining_label: Label = $MarginContainer/HBoxContainer/TimeRemainingLabel
		var time_remaining_str: String = format_seconds_to_str(round(audio_player.get_playback_position()))
		var total_time_str: String = format_seconds_to_str(round(audio_player.stream.get_length()))

		time_remaining_label.text = "%s/%s" % [time_remaining_str, total_time_str]


func format_seconds_to_str(seconds: int):
	var minutes = floor(seconds / 60)
	var final_seconds = (seconds - (minutes * 60))

	var minutes_str = str(minutes)
	var seconds_str = str(final_seconds)

	if minutes < 10:
		minutes_str = "0%s" % minutes_str
	if seconds < 10:
		seconds_str = "0%s" % seconds_str
	
	return "%s:%s" % [minutes_str, seconds_str]


class AudioStreamFactory:
	static func get_stream(filename: String) -> AudioStream:
		var file_parts = filename.split(".")
		var file_extension = file_parts[len(file_parts) - 1]
    	
		match file_extension:
			"mp3":
				return AudioStreamMP3.new()
			"wav":
				return AudioStreamWAV.new()
			_:
				return AudioStream.new()


func load_sound(path: String):
	var track_name: String = path.split("/")[-1].split(".")[0]
	$MarginContainer/HBoxContainer/TrackNameLabel.text = track_name

	var file = FileAccess.open(path, FileAccess.READ)

	if file == null:
		pass

	var buffer = file.get_buffer(file.get_length())
	var stream = AudioStreamFactory.get_stream(path)
	stream.data = buffer

	audio_player.stream = stream
	audio_player.play()


func _on_loop_button_toggled(toggled_on: bool):
	loop = toggled_on


func _on_audio_stream_player_finished():
	if loop:
		audio_player.play()
	else:
		queue_free()


func _on_fade_out_button_pressed():
	var tween: Tween = create_tween()
	# Hard-coded to 2 seconds of fade out, but might make it more intelligent
	# or allow customization.
	tween.tween_property(audio_player, "volume_db", -55, 2)
	tween.tween_callback(queue_free)


func _on_quarter_volume_button_pressed():
	var tween: Tween = create_tween()
	tween.tween_property(audio_player, "volume_db", -12, 1)


func _on_half_volume_button_pressed():
	var tween: Tween = create_tween()
	tween.tween_property(audio_player, "volume_db", -6, 1)
