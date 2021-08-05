from godot import exposed, export
from godot import *

import matplotlib.pyplot as pyplot


@exposed
class PythonTest(Node):

	# member variables here, example:
	a = export(int)
	b = export(str, default='foo')

	def _ready(self):
		pyplot.plot([1, 2, 3, 4, 5, 6],[4, 5, 1, 3, 6, 7])
		pyplot.title('Test Chart')
		pyplot.show()
