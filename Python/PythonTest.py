from godot import exposed, export
from godot import *

from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
import matplotlib.pyplot

import numpy as np


@exposed
class PythonTest(Node):

	# member variables here, example:
	a = export(int)
	b = export(str, default='foo')
	
	def numpy_array_to_image(self, array):
		image = Image()
		
		width = array.shape[0]
		height = array.shape[1]
		
		image.create(height, width, False, Image.FORMAT_RGB8)
		
		image.lock()
		
		print("set pixel start")
		for x in range(width):
			for y in range(height):
				val = array[x][y]
				image.set_pixel(y, x, Color(val[0], val[1], val[2]))
		
		print("set pixel end")
		
		image.unlock()
		
		return image

	def _ready(self):
		fig = Figure(dpi=200)
		canvas = FigureCanvas(fig)
		
		plot = fig.add_subplot(111)
 
		# draw a cardinal sine plot
		x = np.arange(0, 100, 0.1)
		y = np.sin(x)
		plot.plot(x, y, color='red')

		canvas.draw()       # draw the canvas, cache the renderer

		image_from_plot = np.frombuffer(canvas.tostring_rgb(), dtype=np.uint8)
		image_from_plot = image_from_plot.reshape(canvas.get_width_height()[::-1] + (3,))
		
		image = self.numpy_array_to_image(image_from_plot)
		
		image_texture = ImageTexture()
		image_texture.create_from_image(image)
		
		self.get_node("TextureRect").texture = image_texture

