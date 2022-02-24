extends Object
class_name CSVReader

#
# Utility object for reading from CSV files. Each line is parsed into a dictionary with the headers
# (the first CSV row) as the keys.
# 
# Assumptions about the CSV file:
# - The headers are in the first row
# - These headers apply to every row
# - Each row has the same length
#


var lines = []

const LOG_MODULE := "CSVREADER"


func read_csv(csv_path: String) -> void:
	var csv_file = File.new()
	csv_file.open(csv_path, File.READ)
	
	if not csv_file.is_open():
		logger.error("CSV file does not exist, expected it at %s"
				 % [csv_path], LOG_MODULE)
		return
	
	var headings = csv_file.get_csv_line()
	
	while not csv_file.eof_reached():
		var csv = csv_file.get_csv_line()
		
		if csv.size() < headings.size():
			logger.warning("Unexpected CSV line (size does not match headings): %s"
					% [csv], LOG_MODULE)
			continue
		
		# Read all lines into a dictionary mapping heading names to values
		var current_line = {}
		var i = 0
		for heading in headings:
			current_line[heading] = csv[i]
			
			i += 1
		
		# Add that dictionary to the list of lines
		lines.append(current_line)


func get_lines():
	return lines
