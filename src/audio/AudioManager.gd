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

const AUDIO_PATH: String = "/audio"

# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------

@export var tree: Tree
@export var track_container: VBoxContainer

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

func _ready():
    var base_path: String = OS.get_executable_path().get_base_dir()
    var root: TreeItem = tree.create_item()

    iterate_files_and_update_tree(base_path + AUDIO_PATH, root)


func iterate_files_and_update_tree(path: String, root: TreeItem):
    var dir: DirAccess = DirAccess.open(path)

    if dir != null:
        dir.list_dir_begin()
        var file_name: String = dir.get_next()

        while file_name != "":
            if dir.current_is_dir():
                var folder = tree.create_item(root)
                folder.set_text(0, file_name)

                iterate_files_and_update_tree(dir.get_current_dir().path_join(file_name), folder)
            else:
                if file_name.get_extension().to_lower() in ["mp3", "wav"]:
                    var sound_file = tree.create_item(root)
                    sound_file.set_text(0, file_name)
                    # Store the full path to load the sound when the item is double clicked
                    sound_file.set_metadata(0, dir.get_current_dir().path_join(file_name))
            
            file_name = dir.get_next()

        dir.list_dir_end()
    else:
        print("An error occurred when trying to access %s." % path)

    if root.get_child_count() == 0:
        # If there aren't any sounds in a folder, ignore it.
        root.free()


func _on_tree_item_activated():
    var item: TreeItem = tree.get_selected()
    var sound_path = item.get_metadata(0)

    if type_string(typeof(sound_path)) == "String":
        var track: Track = preload("res://src/audio/Track.tscn").instantiate()
        track_container.add_child(track)
        track.load_sound(sound_path)
