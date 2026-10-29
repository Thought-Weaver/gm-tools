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

const BACKGROUND_PATH: String = "/backgrounds"
