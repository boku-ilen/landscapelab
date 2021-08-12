from godot import exposed, export
from godot import *
import os
import sys

from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
import matplotlib.pyplot

import numpy as np


@exposed
class PythonTest(Node):
	def numpy_array_to_image(self, array):
		image = Image()
		
		width = array.shape[0]
		height = array.shape[1]
		
		pool_array = PoolByteArray(array.flatten())
		image.create_from_data(height, width, False, Image.FORMAT_RGB8, pool_array)
		
		return image

	def _ready(self):
		fig = Figure(dpi=200)
		canvas = FigureCanvas(fig)
		
		plot = fig.add_subplot(111)
 
		# draw a cardinal sine plot
		x = np.arange(0, 100, 0.1)
		y = np.sin(x)
		plot.plot(x, y, color='red')

		canvas.draw()

		image_from_plot = np.frombuffer(canvas.tostring_rgb(), dtype=np.uint8)
		image_from_plot = image_from_plot.reshape(canvas.get_width_height()[::-1] + (3,))
		
		image = self.numpy_array_to_image(image_from_plot)
		
		image_texture = ImageTexture()
		image_texture.create_from_image(image)
		
		self.get_node("TextureRect").texture = image_texture
