extends GridContainer

onready var amount = get_node("Details/AmountHBox/AmountText")
onready var value = get_node("Details/ValueHBox/ValueText")
onready var of = get_node("Details/ValueHBox/Of")


func _ready():
	amount.set_text(tr("AMOUNT"))
	value.set_text(tr("ENERGYPRODUCTION"))
	of.set_text(tr("OF"))
