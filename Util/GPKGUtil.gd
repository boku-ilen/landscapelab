extends Object
class_name GPKGUtil


#
# Static utility functions for gpkg handling
#


static func load_entire_table(db, table_name: String):
	# Duplication is necessary (SQLite plugin otherwise overwrites with the next query
	var table = db.select_rows(table_name, "", ["*"]).duplicate()
	
	# Log the table
	logger.info("Loaded table \"%s\"\n" % [table_name])
	logger.info(table)
	
	return table
