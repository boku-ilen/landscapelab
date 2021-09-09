extends Object
class_name Python

#
# General utility functions for Python via PythonScript, written in Godot to
# guarantee that they're accessible.
#


static func is_available():
	# TODO: More sophisticated check (maybe try running a script)
	return Directory.new().dir_exists("res://addons/pythonscript")
