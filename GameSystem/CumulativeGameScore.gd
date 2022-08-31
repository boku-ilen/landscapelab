extends GameScore
class_name CumulativeGameScore


# Override to do `value += sum` rather than `value = sum`
# FIXME: Code duplication could be lessened by moving that line to a separate function and overriding that
func recalculate_score():
	var sum = 0.0
	
	for contributor in contributors:
		sum += contributor.get_value()
	
	if value != sum:
		value += sum
		emit_signal("value_changed", value)
	
		if value >= target:
			emit_signal("target_reached")
