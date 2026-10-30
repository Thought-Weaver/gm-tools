extends Control

# -----------------------------------------------------------------------------
# OVERVIEW
# -----------------------------------------------------------------------------

# There are a few goals for the audio manager:
#
# 1. It should be able to play music and multiple sound effects concurrently
# 2. I should be able to configure audio adjustment before and while playing
# 3. It should let me fade in/out the sound
# 4. It should indicate the time remaining
# 5. It should have options to loop and pause/start a playing sound
# 6. Choosing audio to play should use an /audio/ folder where the app is

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

const AUDIO_PATH: String = "audio"
const AUDIO_EXTENSIONS: PackedStringArray = ["mp3", "wav", "ogg"]

# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------

@export var tree: Tree
@export var track_container: VBoxContainer

@export var default_volume: SpinBox
@export var default_loop: CheckButton
@export var default_fade_in: SpinBox
@export var default_fade_out: SpinBox

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

func _ready() -> void:
	MediaHelpers.add_items_to_tree(tree, MediaHelpers.get_library_path(AUDIO_PATH), AUDIO_EXTENSIONS)


func _on_tree_item_activated() -> void:
	var item: TreeItem = tree.get_selected()
	if item == null || item.get_meta(&"is_directory", false):
		return
	
	var track: Track = preload("res://src/audio/Track.tscn").instantiate()
	track_container.add_child(track)

	var sound_file_path: String = item.get_meta(&"path")
	var error: Error = track.load_sound(sound_file_path, default_volume.value / 100.0, default_loop.button_pressed, default_fade_in.value, default_fade_out.value)

	if error != OK:
		track.queue_free()
