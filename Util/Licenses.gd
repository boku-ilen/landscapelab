extends Node


class License:
	var name
	var acronym
	var author
	var additional_info
	
	func _init(initial_name, initial_acronym, initial_author, initial_additional_info):
		self.name = initial_name
		self.acronym = initial_acronym
		self.author = initial_author
		self.additional_info = initial_additional_info
	
	func _to_string():
		return "%s: %s - %s" % ([name, acronym, author])


signal license_added(license)
signal license_removed(name)

var licenses := {}


func _ready():
	# FIXME: read from a csv?
	add_license(
		"Deep Star Maps 2020",
		"Public Domain",
		"Gaia DR2",
		"NASA/Goddard Space Flight Center Scientific Visualization Studio." +
		"Gaia DR2: ESA/Gaia/DPAC. Constellation figures based checked those developed" +
		"for the IAU by Alan MacRobert of Sky and Telescope magazine (Roger Sinnott and Rick Fienberg)."
	)


func add_license(
		license_name: String,
		acronym: String,
		author := "",
		additional_info := ""
	):
	var new_license = License.new(license_name, acronym, author, additional_info)
	licenses[license_name] = License.new(license_name, acronym, author, additional_info)
	emit_signal("license_added", new_license)


func remove_license(license_name: String):
	licenses.erase(license_name)
	emit_signal("license_removed", license_name)
