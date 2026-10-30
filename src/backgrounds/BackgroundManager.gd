extends Control

# -----------------------------------------------------------------------------
# OVERVIEW
# -----------------------------------------------------------------------------

# There are a few goals for the background manager:
#
# 1. It should be able to display a gallery of images pulled from /backgrounds/
# 2. It should manage a second window that can display in fullscreen
# 3. When double pressing a gallery image, it should update the second window
# 4. It should be able to handle sub-folders, like the audio manager

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

const BACKGROUND_PATH: String = "backgrounds"
const IMAGE_EXTENSIONS: PackedStringArray = ["png", "jpg", "jpeg"]

# Note: For now, the thumbnail size uses the ratio of my TV (3840x2160) to
# roughly show what it'll look like on the display window.
const THUMBNAIL_SIZE: Vector2i = Vector2i(192, 108)

# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------

@export var tree: Tree
@export var gallery: ItemList

@export var display_window: Window
@export var display_image: TextureRect

@export var show_window_button: Button
@export var fullscreen_button: Button

var _gallery_path: String = ""

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

func _ready() -> void:
	var path: String = MediaHelpers.get_library_path(BACKGROUND_PATH)
	var error: Error = MediaHelpers.add_items_to_tree(tree, path, IMAGE_EXTENSIONS)

	if error != OK:
		return

	_show_gallery(tree.get_root())


func _show_gallery(folder: TreeItem) -> void:
	var path: String = folder.get_meta(&"path")
	if path == _gallery_path:
		return

	_gallery_path = path
	gallery.clear()

	for item: TreeItem in folder.get_children():
		if item.get_meta(&"is_directory", false):
			continue

		var image_path: String = item.get_meta(&"path")

		var thumbnail: Texture2D = _create_thumbnail(image_path)
		if thumbnail == null:
			continue

		var index: int = gallery.add_item(item.get_text(0), thumbnail)
		gallery.set_item_metadata(index, image_path)


func _create_thumbnail(path: String) -> Texture2D:
	var image: Image = Image.load_from_file(path)
	if image == null || image.is_empty():
		push_error("Cannot load image: %s" % path)
		return null

	var image_size: Vector2 = image.get_size()
	var image_scale: float = minf(1.0, minf(THUMBNAIL_SIZE.x / image_size.x, THUMBNAIL_SIZE.y / image_size.y))
	image.resize(maxi(1, roundi(image_size.x * image_scale)), maxi(1, roundi(image_size.y * image_scale)), Image.INTERPOLATE_LANCZOS)

	return ImageTexture.create_from_image(image)


func _display_background(path: String) -> void:
	var image: Image = Image.load_from_file(path)
	if image == null || image.is_empty():
		push_error("Cannot display image: %s" % path)
		return

	display_image.texture = ImageTexture.create_from_image(image)
	display_window.title = "GM Tools - %s" % path.get_file()


func _on_tree_item_selected() -> void:
	var item: TreeItem = tree.get_selected()
	var directory: bool = item.get_meta(&"is_directory", false)
	_show_gallery(item if directory else item.get_parent())


func _on_tree_item_activated() -> void:
	var item: TreeItem = tree.get_selected()
	if !item.get_meta(&"is_directory", false):
		_display_background(item.get_meta(&"path"))


func _on_gallery_item_activated(index: int) -> void:
	_display_background(gallery.get_item_metadata(index))


func _on_show_window_toggled(show_window: bool) -> void:
	display_window.visible = show_window
	show_window_button.text = "Hide Display Window" if show_window else "Show Display Window"


func _on_fullscreen_toggled(fullscreen: bool) -> void:
	if fullscreen:
		show_window_button.button_pressed = true
	display_window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	fullscreen_button.text = "Set Background Image Windowed" if fullscreen else "Set Background Image Fullscreen"


func _on_display_close_requested() -> void:
	show_window_button.button_pressed = false
