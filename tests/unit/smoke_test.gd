extends GdUnitTestSuite


func test_project_resolution() -> void:
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	assert_int(width).is_equal(1280)
	assert_int(height).is_equal(720)
