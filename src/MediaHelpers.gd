class_name MediaHelpers extends RefCounted

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

static func get_library_path(folder: String) -> String:
	var base_path: String = OS.get_executable_path().get_base_dir()
	return base_path.path_join(folder)


static func add_items_to_tree(tree: Tree, path: String, extensions: PackedStringArray) -> Error:
	tree.clear()
	
	if !DirAccess.dir_exists_absolute(path):
		var error: Error = DirAccess.make_dir_recursive_absolute(path)
		if error != OK:
			push_error("Cannot create media folder '%s': %s" % [path, error_string(error)])
			return error

	var root: TreeItem = _create_item(tree, null, path, true)
	return _create_items_for_folder(tree, root, path, extensions)


static func _create_items_for_folder(tree: Tree, parent: TreeItem, path: String, extensions: PackedStringArray) -> Error:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		var error: Error = DirAccess.get_open_error()
		push_error("Cannot read media folder '%s': %s" % [path, error_string(error)])
		return error

	var folders: PackedStringArray = dir.get_directories()	
	for folder_name: String in folders:
		# Do not follow directory links, which can lead back to a parent.
		if dir.is_link(folder_name):
			continue
		
		var folder_path: String = path.path_join(folder_name)
		var folder: TreeItem = _create_item(tree, parent, folder_path, true)
		var error: Error = _create_items_for_folder(tree, folder, folder_path, extensions)
		
		if error != OK:
			return error
		
		if folder.get_child_count() == 0:
			folder.free()

	var files: PackedStringArray = dir.get_files()
	
	for file_name: String in files:
		if file_name.get_extension().to_lower() in extensions:
			_create_item(tree, parent, path.path_join(file_name), false)
	
	return OK


static func _create_item(tree: Tree, parent: TreeItem, path: String, directory: bool) -> TreeItem:
	var item: TreeItem = tree.create_item(parent)
	item.set_text(0, path.get_file())
	item.set_meta(&"path", path)
	item.set_meta(&"is_directory", directory)
	return item
