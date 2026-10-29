extends MarginContainer

@onready var tree: Tree = %Tree
@onready var track_container: VBoxContainer = %TrackContainer

func _ready():
	var base_path: String = OS.get_executable_path().get_base_dir()
	var root: TreeItem = tree.create_item()

	construct_tree(base_path, root)


func construct_tree(path: String, root: TreeItem):
	var dir: DirAccess = DirAccess.open(path)

	if dir:
		dir.list_dir_begin()
		
		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				var folder = tree.create_item(root)
				folder.set_text(0, file_name)

				construct_tree(dir.get_current_dir().path_join(file_name), folder)
			else:
				if file_name.get_extension().to_lower() in ["mp3", "wav"]:
					var sound_file = tree.create_item(root)
					sound_file.set_text(0, file_name)
					# Store the full path to load the sound when the item is double clicked
					sound_file.set_metadata(0, dir.get_current_dir().path_join(file_name))
			
			file_name = dir.get_next()
		
		if root.get_child_count() == 0:
			# If there aren't any sounds in a folder, ignore it.
			root.free()
	else:
		print("An error occurred when trying to access %s." % path)


func _on_tree_item_activated():
	var item: TreeItem = %Tree.get_selected()
	var sound_path = item.get_metadata(0)
	if type_string(typeof(sound_path)) == "String":
		var track: Track = preload("res://src/audio/Track.tscn").instantiate()
		%TrackContainer.add_child(track)
		track.load_sound(sound_path)
