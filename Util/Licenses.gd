extends Node


class License:
	var name
	var acronym
	var author
	var additional_info
	
	func _init(name, acronym, author, additional_info):
		self.name = name
		self.acronym = acronym
		self.author = author
		self.additional_info = additional_info
	
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
		"Gaia DR2: ESA/Gaia/DPAC. Constellation figures based on those developed" +
		"for the IAU by Alan MacRobert of Sky and Telescope magazine (Roger Sinnott and Rick Fienberg)."
	)


func add_license(
		name: String,
		acronym: String,
		author := "",
		additional_info := ""
	):
	var new_license = License.new(name, acronym, author, additional_info)
	licenses[name] = License.new(name, acronym, author, additional_info)
	emit_signal("license_added", new_license)


func remove_license(name: String):
	licenses.erase(name)
	emit_signal("license_removed", name)
